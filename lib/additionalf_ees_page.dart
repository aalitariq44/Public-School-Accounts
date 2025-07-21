import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdditionalFeesPage extends StatefulWidget {
  final int school;

  const AdditionalFeesPage({super.key, required this.school});

  @override
  _AdditionalFeesPageState createState() => _AdditionalFeesPageState();
}

class _AdditionalFeesPageState extends State<AdditionalFeesPage> {
  SqlDb sqlDb = SqlDb();
  List<Map> additionalFees = [];
  String currentFilter = 'الكل';
  String currentPaymentFilter = 'الكل';
  double totalAmount = 0;
  bool showOnlyWithNotes = false;

  @override
  void initState() {
    super.initState();
    getAdditionalFees();
  }

  void getAdditionalFees({String? feeType, String? paymentStatus}) async {
    String query = '''
    SELECT additionalFees.*, 
           students.name as studentName, 
           students.stage, 
           students.level, 
           students.stream, 
           students.section, 
           students.school
    FROM additionalFees
    INNER JOIN students ON additionalFees.studentId = students.id
    WHERE students.school = ${widget.school}
  ''';

    if (feeType != null && feeType != 'الكل') {
      query += " AND additionalFees.feeType = '$feeType'";
    }

    if (paymentStatus != null && paymentStatus != 'الكل') {
      query +=
          " AND additionalFees.isPaid = ${paymentStatus == 'مدفوع' ? 1 : 0}";
    }

    if (showOnlyWithNotes) {
      query +=
          " AND additionalFees.notes IS NOT NULL AND additionalFees.notes != '' AND additionalFees.notes != 'null'";
    }

    print("SQL Query: $query"); // للتحقق من الاستعلام

    List<Map> response = await sqlDb.readData(query);

    print("Response: ${response.length}"); // للتحقق من عدد النتائج
    if (response.isNotEmpty) {
      print("First result: ${response.first}"); // للتحقق من أول نتيجة
    }

    double sum = 0;
    for (var fee in response) {
      if (fee['isPaid'] == 1) {
        sum += fee['amount'];
      }
    }
    setState(() {
      additionalFees = response;
      totalAmount = sum;
    });
  }

  Widget _buildNotesFilterButton(String label, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: showOnlyWithNotes ? Colors.blue : Colors.grey[300],
        foregroundColor: showOnlyWithNotes ? Colors.white : Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          showOnlyWithNotes = !showOnlyWithNotes;
        });
        getAdditionalFees(
          feeType: currentFilter == 'الكل' ? null : currentFilter,
          paymentStatus:
              currentPaymentFilter == 'الكل' ? null : currentPaymentFilter,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الرسوم الإضافية'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: previewAndPrintPdf,
          ),
          Text(
            'المجموع: ${totalAmount.round()} د.ع',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(width: 20)
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('الكل', Icons.list),
                      SizedBox(width: 8),
                      _buildFilterButton('تسجيل', Icons.app_registration),
                      SizedBox(width: 8),
                      _buildFilterButton('كتب', Icons.book),
                      SizedBox(width: 8),
                      _buildFilterButton('زي مدرسي', Icons.checkroom),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPaymentFilterButton('الكل', Icons.all_inclusive),
                      SizedBox(width: 8),
                      _buildPaymentFilterButton('مدفوع', Icons.check_circle),
                      SizedBox(width: 8),
                      _buildPaymentFilterButton('غير مدفوع', Icons.cancel),
                      SizedBox(width: 8),
                      _buildNotesFilterButton('مع ملاحظات', Icons.note),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: additionalFees.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      additionalFees[index]['studentName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${additionalFees[index]['stage']} ${additionalFees[index]['stream'] == 'null' ? '' : 'لا يوجد'} - ${additionalFees[index]['section']}   رقم المدرسة: ${additionalFees[index]['school']}'),
                        Row(
                          children: [
                            Text(
                                'نوع الرسوم: ${additionalFees[index]['feeType']}'),
                            SizedBox(
                              width: 40,
                            ),
                            Text(
                              '${additionalFees[index]['notes']}',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: additionalFees[index]['isPaid'] == 1
                        ? Text(
                            '${additionalFees[index]['amount'].round()} د.ع',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          )
                        : Text(
                            'غير مدفوع',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            currentFilter == label ? Colors.blue : Colors.grey[300],
        foregroundColor: currentFilter == label ? Colors.white : Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          currentFilter = label;
        });
        getAdditionalFees(
          feeType: label == 'الكل' ? null : label,
          paymentStatus:
              currentPaymentFilter == 'الكل' ? null : currentPaymentFilter,
        );
      },
    );
  }

  Widget _buildPaymentFilterButton(String label, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            currentPaymentFilter == label ? Colors.blue : Colors.grey[300],
        foregroundColor:
            currentPaymentFilter == label ? Colors.white : Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          currentPaymentFilter = label;
          showOnlyWithNotes = false; // Reset the notes filter
        });
        getAdditionalFees(
          feeType: currentFilter == 'الكل' ? null : currentFilter,
          paymentStatus: label == 'الكل' ? null : label,
        );
      },
    );
  }

  Future<Uint8List> generatePdf() async {
    final fontData = await rootBundle.load("fonts/Amiri-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);

    double fontSize = 10;

    final pdf = pw.Document();
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('images/logo.png')).buffer.asUint8List(),
    );

    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );

    Map<String, List<Map>> feesByType = {};
    for (var fee in additionalFees) {
      String feeType = fee['feeType'];
      if (!feesByType.containsKey(feeType)) {
        feesByType[feeType] = [];
      }
      feesByType[feeType]!.add(fee);
    }

    feesByType.forEach((feeType, fees) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginBottom: 50,
          ),
          margin: pw.EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 50),
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
                          'قائمة الرسوم الإضافية - $feeType',
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
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1.5),
                    2: pw.FlexColumnWidth(1.5),
                    3: pw.FlexColumnWidth(2),
                    4: pw.FlexColumnWidth(3),
                    5: pw.FixedColumnWidth(30),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Text('الملاحظات', style: headerStyle),
                        pw.Text('الحالة', style: headerStyle),
                        pw.Text('المبلغ', style: headerStyle),
                        pw.Text('الصف', style: headerStyle),
                        pw.Text('اسم الطالب', style: headerStyle),
                        pw.Text('ت', style: headerStyle),
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
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(3),
                  5: pw.FixedColumnWidth(30),
                },
                children: fees.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  Map fee = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(fee['notes'] ?? '',
                            style: pw.TextStyle(font: ttf, fontSize: fontSize)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                            fee['isPaid'] == 1 ? 'مدفوع' : 'غير مدفوع',
                            style: pw.TextStyle(font: ttf, fontSize: fontSize)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text('${fee['amount'].round()}',
                            style: pw.TextStyle(font: ttf, fontSize: fontSize),
                            textAlign: pw.TextAlign.left),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                            '${fee['stage']} ${fee['stream'] != 'null' ? fee['stream'] : ''} - ${fee['section']}',
                            style: pw.TextStyle(font: ttf, fontSize: fontSize)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(fee['studentName'],
                            style: pw.TextStyle(font: ttf, fontSize: fontSize)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text('$index',
                            style: pw.TextStyle(font: ttf, fontSize: fontSize),
                            textAlign: pw.TextAlign.center),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'المجموع: ${fees.fold(0.0, (sum, fee) => sum + (fee['isPaid'] == 1 ? fee['amount'] : 0)).round()} د.ع',
                style: pw.TextStyle(
                    font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ];
          },
        ),
      );
    });

    return pdf.save();
  }

  void previewAndPrintPdf() async {
    final pdfContent = await generatePdf();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('معاينة الطباعة'),
            actions: [
              IconButton(
                icon: Icon(Icons.print),
                onPressed: () async {
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdfContent,
                  );
                },
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => pdfContent,
          ),
        ),
      ),
    );
  }
}
