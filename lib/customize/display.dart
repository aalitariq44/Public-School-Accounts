import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/one_student.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentListPage extends StatefulWidget {
  final int school;

  const StudentListPage({super.key, required this.school});

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  late int schoolId;

  SqlDb sqlDb = SqlDb();
  List<Map> allStudents = [];
  List<Map> displayedStudents = [];
  TextEditingController searchController = TextEditingController();
  String currentFilter = 'all'; // 'all', 'paid', 'unpaid'
  String levelFilter = 'all';
  String? stageFilter;
  String? sectionFilter;
  String? streamFilter;
  final _studentsStreamController = StreamController<List<Map>>.broadcast();
  bool _isActive = true;

  final Map<String, List<String>> stages = {
    'ابتدائي': [
      'الأول الإبتدائي',
      'الثاني الإبتدائي',
      'الثالث الإبتدائي',
      'الرابع الإبتدائي',
      'الخامس الإبتدائي',
      'السادس الإبتدائي'
    ],
    'متوسط': ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'],
    'إعدادي': ['الرابع', 'الخامس', 'السادس'],
  };

  List<String> streams = ['العلمي', 'الأدبي'];
  @override
  void initState() {
    super.initState();
    schoolId = widget.school;
    _isActive = true;
    loadStudentsWithPayments();
  }

  @override
  void dispose() {
    _isActive = false;
    _studentsStreamController.close();
    super.dispose();
  }

  int getArabicCharValue(String char) {
    const arabicAlphabet = 'أإآاءؤبتثجحخدذرزسشصضطظعغفقكلمنهوي';
    return arabicAlphabet.indexOf(char.toLowerCase());
  }

  int compareArabicStrings(String a, String b) {
    int minLength = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLength; i++) {
      int valueA = getArabicCharValue(a[i]);
      int valueB = getArabicCharValue(b[i]);
      if (valueA != valueB) {
        return valueA - valueB;
      }
    }
    return a.length - b.length;
  }

  Stream<List<Map>> get studentsStream => _studentsStreamController.stream;

  void loadStudentsWithPayments() async {
    while (_isActive) {
      List<Map> response = await sqlDb.readData('''
    SELECT 
      s.*, 
      COALESCE(SUM(i.amount), 0) as total_paid,
      (SELECT GROUP_CONCAT(feeType)
       FROM additionalFees
       WHERE studentId = s.id AND isPaid = 0) as unpaid_fees
    FROM 
      students s
    LEFT JOIN 
      installments i ON s.id = i.IDStudent
    WHERE 
      s.school = ${widget.school}
    GROUP BY 
      s.id
  ''');

      if (_isActive) {
        List<Map> sortedResponse = List<Map>.from(response);
        sortedResponse
            .sort((a, b) => compareArabicStrings(a['name'], b['name']));
        _studentsStreamController.add(sortedResponse);
      }

      await Future.delayed(Duration(seconds: 5));
    }
  }

  void applyFilter() {
    displayedStudents = allStudents.where((student) {
      bool matchesPaymentFilter = true;
      switch (currentFilter) {
        case 'paid':
          matchesPaymentFilter = (student['totalInstallment'] ?? 0) -
                  (student['total_paid'] ?? 0) <=
              0;
          break;
        case 'unpaid':
          matchesPaymentFilter = (student['totalInstallment'] ?? 0) -
                  (student['total_paid'] ?? 0) >
              0;
          break;
      }

      bool matchesLevel =
          (levelFilter == 'all' || student['level'] == levelFilter);
      bool matchesStage =
          (stageFilter == null || student['stage'] == stageFilter);
      bool matchesSection =
          (sectionFilter == null || student['section'] == sectionFilter);
      bool matchesStream =
          (streamFilter == null || student['stream'] == streamFilter);

      return matchesPaymentFilter &&
          matchesLevel &&
          matchesStage &&
          matchesSection &&
          matchesStream;
    }).toList();
  }

  void filterStudents(String query) {
    setState(() {
      updateDisplayedStudents();
    });
  }

  Future<void> generatePdf() async {
    final fontData = await rootBundle.load("fonts/Amiri-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);

    bool showNotes = true; // متغير للتحكم في إظهار الملاحظات
    bool showBasicsOnly = false; // متغير جديد للتحكم في إظهار الأساسيات فقط
    double fontSize = 10; // حجم الخط الافتراضي

    Future<Uint8List> generatePdfContent() async {
      final pdf = pw.Document();
      final logoImage = pw.MemoryImage(
        (await rootBundle.load('images/logo.png')).buffer.asUint8List(),
      );

      // تعريف نمط العنوان
      final headerStyle = pw.TextStyle(
        font: ttf,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      );

      // تجميع الطلاب حسب الصف
      Map<String, List<Map>> studentsByClass = {};
      for (var student in displayedStudents) {
        String className =
            '${student['stage']} ${student['stream'] != 'null' ? student['stream'] + ' - ' : ''}${student['section']}';
        if (!studentsByClass.containsKey(className)) {
          studentsByClass[className] = [];
        }
        studentsByClass[className]!.add(student);
      }

      // إنشاء صفحات لكل صف
      studentsByClass.forEach((className, students) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.copyWith(
              marginBottom: 50,
            ),
            margin:
                pw.EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 50),
            textDirection: pw.TextDirection.rtl,
            theme: pw.ThemeData.withFont(
              base: ttf,
            ),
            header: (pw.Context context) {
              return pw.Column(
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    margin: pw.EdgeInsets.only(bottom: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'قائمة طلاب $className',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Center(
                            child: pw.Image(logoImage, width: 30, height: 30),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'صفحة ${context.pageNumber} من ${context.pagesCount}',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: showBasicsOnly
                        ? {
                            0: pw.FlexColumnWidth(3), // الملاحظات
                            1: pw.FlexColumnWidth(3.5), // الاسم
                            2: pw.FixedColumnWidth(30), // ت (التسلسل)
                          }
                        : (showNotes
                            ? {
                                0: pw.FlexColumnWidth(3), // الملاحظات
                                1: pw.FlexColumnWidth(
                                    2.3), // الرسوم غير المدفوعة
                                2: pw.FlexColumnWidth(1.5), // المتبقي
                                3: pw.FlexColumnWidth(1.5), // المدفوع
                                4: pw.FlexColumnWidth(1.7), // القسط الكلي
                                5: pw.FlexColumnWidth(3.5), // الاسم
                                6: pw.FixedColumnWidth(30), // ت (التسلسل)
                              }
                            : {
                                0: pw.FlexColumnWidth(
                                    2.5), // الرسوم غير المدفوعة
                                1: pw.FixedColumnWidth(70), // المتبقي
                                2: pw.FixedColumnWidth(70), // المدفوع
                                3: pw.FixedColumnWidth(70), // القسط الكلي
                                4: pw.FlexColumnWidth(4), // الاسم
                                5: pw.FixedColumnWidth(30), // ت (التسلسل)
                              }),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          if (showBasicsOnly) ...[
                            pw.Text('الملاحظات', style: headerStyle),
                            pw.Text('الاسم', style: headerStyle),
                            pw.Text('ت', style: headerStyle),
                          ] else if (showNotes) ...[
                            pw.Text('الملاحظات', style: headerStyle),
                            pw.Text('الرسوم غير المدفوعة', style: headerStyle),
                            pw.Text('المتبقي', style: headerStyle),
                            pw.Text('المدفوع', style: headerStyle),
                            pw.Text('القسط الكلي', style: headerStyle),
                            pw.Text('الاسم', style: headerStyle),
                            pw.Text('ت', style: headerStyle),
                          ] else ...[
                            pw.Text('الرسوم غير المدفوعة', style: headerStyle),
                            pw.Text('المتبقي', style: headerStyle),
                            pw.Text('المدفوع', style: headerStyle),
                            pw.Text('القسط الكلي', style: headerStyle),
                            pw.Text('الاسم', style: headerStyle),
                            pw.Text('ت', style: headerStyle),
                          ]
                        ]
                            .map((header) => pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(5),
                                  child: header,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              );
            },
            build: (pw.Context context) {
              return [
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: showBasicsOnly
                      ? {
                          0: pw.FlexColumnWidth(3), // الملاحظات
                          1: pw.FlexColumnWidth(3.5), // الاسم
                          2: pw.FixedColumnWidth(30), // ت (التسلسل)
                        }
                      : (showNotes
                          ? {
                              0: pw.FlexColumnWidth(3), // الملاحظات
                              1: pw.FlexColumnWidth(2.3), // الرسوم غير المدفوعة
                              2: pw.FlexColumnWidth(1.5), // المتبقي
                              3: pw.FlexColumnWidth(1.5), // المدفوع
                              4: pw.FlexColumnWidth(1.7), // القسط الكلي
                              5: pw.FlexColumnWidth(3.5), // الاسم
                              6: pw.FixedColumnWidth(30), // ت (التسلسل)
                            }
                          : {
                              0: pw.FlexColumnWidth(2.5), // الرسوم غير المدفوعة
                              1: pw.FixedColumnWidth(70), // المتبقي
                              2: pw.FixedColumnWidth(70), // المدفوع
                              3: pw.FixedColumnWidth(70), // القسط الكلي
                              4: pw.FlexColumnWidth(4), // الاسم
                              5: pw.FixedColumnWidth(30), // ت (التسلسل)
                            }),
                  children: students.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    Map student = entry.value;
                    int totalInstallment = student['totalInstallment'] ?? 0;
                    int totalPaid = student['total_paid'] ?? 0;
                    int remaining = totalInstallment - totalPaid;
                    String unpaidFees = student['unpaid_fees'] ?? '';
                    List<String> feeTypes =
                        unpaidFees.isNotEmpty ? unpaidFees.split(',') : [];
                    String formattedFees =
                        feeTypes.isEmpty ? ' ' : feeTypes.join(', ');

                    if (showBasicsOnly) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (student['phoneNumber'] != null &&
                                    student['phoneNumber'].isNotEmpty)
                                  pw.Text('${student['phoneNumber']}',
                                      style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: fontSize,
                                          fontWeight: pw.FontWeight.bold)),
                                pw.Text(student['notes'] ?? '',
                                    style: pw.TextStyle(
                                        font: ttf, fontSize: fontSize)),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text(student['name'],
                                style: pw.TextStyle(
                                    font: ttf, fontSize: fontSize)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text('$index',
                                style:
                                    pw.TextStyle(font: ttf, fontSize: fontSize),
                                textAlign: pw.TextAlign.center),
                          ),
                        ],
                      );
                    } else {
                      return pw.TableRow(
                        children: [
                          if (showNotes)
                            pw.Padding(
                              padding: pw.EdgeInsets.all(2),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  if (student['phoneNumber'] != null &&
                                      student['phoneNumber'].isNotEmpty)
                                    pw.Text('${student['phoneNumber']}',
                                        style: pw.TextStyle(
                                            font: ttf,
                                            fontSize: fontSize,
                                            fontWeight: pw.FontWeight.bold)),
                                  pw.Text(student['notes'] ?? '',
                                      style: pw.TextStyle(
                                          font: ttf, fontSize: fontSize)),
                                ],
                              ),
                            ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text(formattedFees,
                                style: pw.TextStyle(
                                    font: ttf, fontSize: fontSize)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text('$remaining',
                                style:
                                    pw.TextStyle(font: ttf, fontSize: fontSize),
                                textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text('$totalPaid',
                                style:
                                    pw.TextStyle(font: ttf, fontSize: fontSize),
                                textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text('$totalInstallment',
                                style:
                                    pw.TextStyle(font: ttf, fontSize: fontSize),
                                textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text(student['name'],
                                style: pw.TextStyle(
                                    font: ttf, fontSize: fontSize)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(2),
                            child: pw.Text('$index',
                                style:
                                    pw.TextStyle(font: ttf, fontSize: fontSize),
                                textAlign: pw.TextAlign.center),
                          ),
                        ],
                      );
                    }
                  }).toList(),
                ),
              ];
            },
          ),
        );
      });

      return pdf.save();
    }

    // عرض معاينة PDF مع أزرار إضافية
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: PdfPreview(
                    build: (format) => generatePdfContent(),
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    initialPageFormat: PdfPageFormat.a4,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pdfData = await generatePdfContent();
                            await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) => pdfData,
                            );
                          },
                          child: Text('طباعة'),
                        ),
                        Row(
                          children: [
                            Text('إظهار الملاحظات'),
                            Switch(
                              value: showNotes,
                              onChanged: (value) {
                                setState(() {
                                  showNotes = value;
                                  if (value) showBasicsOnly = false;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text('إظهار الأساسيات فقط'),
                            Switch(
                              value: showBasicsOnly,
                              onChanged: (value) {
                                setState(() {
                                  showBasicsOnly = value;
                                  if (value) showNotes = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('حجم الخط: '),
                        DropdownButton<double>(
                          value: fontSize,
                          items: [8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0]
                              .map((double value) {
                            return DropdownMenuItem<double>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              fontSize = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void updateDisplayedStudents() {
    displayedStudents = List<Map>.from(allStudents).where((student) {
      bool matchesSearch = student['name']
          .toLowerCase()
          .contains(searchController.text.toLowerCase());
      bool matchesPaymentFilter = true;
      switch (currentFilter) {
        case 'paid':
          matchesPaymentFilter = (student['totalInstallment'] ?? 0) -
                  (student['total_paid'] ?? 0) <=
              0;
          break;
        case 'unpaid':
          matchesPaymentFilter = (student['totalInstallment'] ?? 0) -
                  (student['total_paid'] ?? 0) >
              0;
          break;
      }

      bool matchesLevel =
          (levelFilter == 'all' || student['level'] == levelFilter);
      bool matchesStage =
          (stageFilter == null || student['stage'] == stageFilter);
      bool matchesSection =
          (sectionFilter == null || student['section'] == sectionFilter);
      bool matchesStream =
          (streamFilter == null || student['stream'] == streamFilter);

      return matchesSearch &&
          matchesPaymentFilter &&
          matchesLevel &&
          matchesStage &&
          matchesSection &&
          matchesStream;
    }).toList();

    // ترتيب القائمة حسب الحروف العربية
    displayedStudents
        .sort((a, b) => compareArabicStrings(a['name'], b['name']));
  }

  String truncateWithEllipsis(String text, int maxLength) {
    return (text.length <= maxLength)
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('قائمة الطلاب'),
          actions: [
            IconButton(
              icon: Icon(Icons.print),
              onPressed: generatePdf,
              tooltip: 'تحويل إلى PDF وطباعة',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'بحث عن طالب',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: filterStudents,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        label: Text('الكل'),
                        selected: currentFilter == 'all',
                        onSelected: (selected) {
                          setState(() {
                            currentFilter = 'all';
                            applyFilter();
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        label: Text('أكملوا الأقساط'),
                        selected: currentFilter == 'paid',
                        onSelected: (selected) {
                          setState(() {
                            currentFilter = 'paid';
                            applyFilter();
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        label: Text('متبقي عليهم أقساط'),
                        selected: currentFilter == 'unpaid',
                        onSelected: (selected) {
                          setState(() {
                            currentFilter = 'unpaid';
                            applyFilter();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                        label: Text('الكل'),
                        selected: levelFilter == 'all',
                        onSelected: (selected) {
                          setState(() {
                            levelFilter = 'all';
                            stageFilter = null;
                            streamFilter = null;
                            sectionFilter = null;
                            applyFilter();
                          });
                        },
                      ),
                    ),
                    ...stages.keys.map((level) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FilterChip(
                            label: Text(level),
                            selected: levelFilter == level,
                            onSelected: (selected) {
                              setState(() {
                                levelFilter = level;
                                stageFilter = null;
                                streamFilter = null;
                                sectionFilter = null;
                                applyFilter();
                              });
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),
            if (levelFilter != 'all')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stages[levelFilter]!
                        .map((stage) => Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilterChip(
                                label: Text(stage),
                                selected: stageFilter == stage,
                                onSelected: (selected) {
                                  setState(() {
                                    stageFilter = selected ? stage : null;
                                    streamFilter = null;
                                    sectionFilter = null;
                                    applyFilter();
                                  });
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            if (levelFilter == 'إعدادي' && stageFilter != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: FilterChip(
                          label: Text('الكل'),
                          selected: streamFilter == null,
                          onSelected: (selected) {
                            setState(() {
                              streamFilter = null;
                              sectionFilter = null;
                              applyFilter();
                            });
                          },
                        ),
                      ),
                      ...streams.map((stream) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: FilterChip(
                              label: Text(stream),
                              selected: streamFilter == stream,
                              onSelected: (selected) {
                                setState(() {
                                  streamFilter = selected ? stream : null;
                                  sectionFilter = null;
                                  applyFilter();
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            if (stageFilter != null &&
                (levelFilter != 'إعدادي' || streamFilter != null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['أ', 'ب', 'ج', 'د']
                        .map((section) => Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilterChip(
                                label: Text('شعبة $section'),
                                selected: sectionFilter == section,
                                onSelected: (selected) {
                                  setState(() {
                                    sectionFilter = selected ? section : null;
                                    applyFilter();
                                  });
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<List<Map>>(
                stream: studentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    allStudents = List<Map>.from(snapshot.data!);
                    updateDisplayedStudents();
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: null,
                      ),
                      itemCount: displayedStudents.length,
                      itemBuilder: (context, index) {
                        Map student = displayedStudents[index];
                        int totalInstallment = student['totalInstallment'] ?? 0;
                        int totalPaid = student['total_paid'] ?? 0;
                        int remaining = totalInstallment - totalPaid;
                        bool isPaidFully = remaining <= 0;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OneStudent(
                                    id: student['id'],
                                    name: student['name'],
                                    stage: student['stage'],
                                    totalInstallment:
                                        student['totalInstallment'],
                                    level: student['level'],
                                    stream: student['stream'],
                                    section: student['section'],
                                    dateCommencement:
                                        student['dateCommencement'],
                                    phoneNumber:
                                        student['phoneNumber'] ?? 'لايوجد',
                                    schoolId: student['school'],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.amber,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          student['name'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isPaidFully)
                                        Icon(Icons.check_circle,
                                            color: Colors.green, size: 18),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'الصف: ${student['stage']} ${student['stream'] != 'null' ? student['stream'] + ' - ' : ''}${student['section']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                      student['phoneNumber']?.isNotEmpty == true
                                          ? 'رقم الهاتف: ${student['phoneNumber']}'
                                          : 'رقم الهاتف: لا يوجد',
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 16)),
                                  Text(
                                    student['notes']?.isNotEmpty == true
                                        ? '${truncateWithEllipsis(student['notes'], 25)}'
                                        : '',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Spacer(),
                                  Text('القسط الكلي: $totalInstallment د.ع',
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 16)),
                                  Text('المدفوع: $totalPaid د.ع',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 16)),
                                  Text('المتبقي: $remaining د.ع',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      padding: EdgeInsets.all(10),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
