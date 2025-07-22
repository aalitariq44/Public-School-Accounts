import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:maryams_school_fees/academicYear.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintPage extends StatefulWidget {
  const PrintPage(
      {Key? key,
      required this.name,
      required this.id,
      required this.amount,
      required this.date,
      required this.satge,
      required this.totalPaid,
      required this.totalInstallment,
      required this.remainingInstallment,
      required this.invoice,
      required this.stage,
      required this.level,
      required this.stream,
      required this.section,
      required this.dateCommencement,
      required this.schoolId,
      required this.schoolName,
      required this.addres,
      required this.phone})
      : super(key: key);

  final String name;
  final int id;
  final String amount;
  final String date;
  final String satge;
  final String totalPaid;
  final int totalInstallment;
  final String remainingInstallment;
  final String invoice;
  final String stage;
  final String level;
  final String stream;
  final String section;
  final String dateCommencement;
  final dynamic schoolId;
  final dynamic schoolName;
  final dynamic addres;
  final dynamic phone;

  @override
  _PrintPageState createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  late String stream;
  String academicYear = AppSettings().academicYear;
  String selectedAccountManager = '';
  List<String> accountManagers = [];

  // جلب المحاسبين من قاعدة البيانات
  Future<void> _loadAccountManagers() async {
    try {
      final SqlDb sqlDb = SqlDb();
      List<Map> result = await sqlDb.readData("SELECT name FROM accountants");
      setState(() {
        accountManagers = result.map<String>((e) => e['name'].toString()).toList();
        // إضافة خيار إضافة محاسب
        accountManagers.add('إضافة اسم محاسب');
        // تعيين الافتراضي
        if (accountManagers.isNotEmpty) {
          selectedAccountManager = accountManagers.first;
        } else {
          selectedAccountManager = '';
        }
      });
    } catch (e) {
      setState(() {
        accountManagers = ['محاسب', 'إضافة اسم محاسب'];
        selectedAccountManager = 'محاسب';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    stream = (widget.stream == "null") ? "" : widget.stream;
    _loadAccountManagers();
  }

  void _showAddAccountManagerDialog() {
    String newManager = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('إضافة اسم محاسب جديد'),
          content: TextField(
            onChanged: (value) {
              newManager = value;
            },
            decoration: InputDecoration(hintText: "أدخل اسم المحاسب الجديد"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('إضافة'),
              onPressed: () async {
                if (newManager.isNotEmpty) {
                  final SqlDb sqlDb = SqlDb();
                  await sqlDb.insertData("INSERT INTO accountants (name) VALUES ('$newManager')");
                  await _loadAccountManagers();
                  setState(() {
                    selectedAccountManager = newManager;
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("معاينة الطباعة"),
        actions: [
          DropdownButton<String>(
            value: selectedAccountManager.isNotEmpty ? selectedAccountManager : null,
            icon: Icon(Icons.arrow_drop_down),
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Colors.white),
            underline: Container(
              height: 2,
              color: Colors.white,
            ),
            onChanged: (String? newValue) {
              if (newValue == 'إضافة اسم محاسب') {
                _showAddAccountManagerDialog();
              } else if (newValue != null) {
                setState(() {
                  selectedAccountManager = newValue;
                });
              }
            },
            items: accountManagers.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(width: 20), // لإضافة بعض المساحة على اليمين
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        maxPageWidth: 800 * 1,
        allowSharing: true,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final amiriBold = await rootBundle.load("fonts/Amiri-Bold.ttf");
    final ttf = pw.Font.ttf(amiriBold);

    final logoImage = await rootBundle.load('images/logo.png');
    final newtechImage = await rootBundle.load('images/newtech.png');

    final pageFormat = PdfPageFormat.a4.copyWith(
      marginLeft: 8 * PdfPageFormat.mm,
      marginTop: 4 * PdfPageFormat.mm,
      marginRight: 8 * PdfPageFormat.mm,
      marginBottom: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              _buildPdfReceipt(logoImage, newtechImage, ttf),
              pw.SizedBox(height: 10),
              _buildPdfReceipt(logoImage, newtechImage, ttf),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfReceipt(
      ByteData logoImage, ByteData newtechImage, pw.Font ttf) {
    String schoolNameToShow = (widget.schoolName != null && widget.schoolName.toString().isNotEmpty)
        ? widget.schoolName.toString()
        : 'اسم المدرسة';
    return pw.Container(
      width: 800,
      height: 400,
      color: PdfColor.fromInt(0xFFE6F3FF),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            height: 90,
            margin: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: 10),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text("وصل",
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                          textDirection: pw.TextDirection.rtl),
                      pw.Text("تسديد الإجور الدراسية",
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                          textDirection: pw.TextDirection.rtl),
                      pw.Text(academicYear,
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                          textDirection: pw.TextDirection.rtl),
                    ],
                  ),
                ),
                pw.Image(pw.MemoryImage(logoImage.buffer.asUint8List()),
                    width: 70),
                pw.Padding(
                  padding: pw.EdgeInsets.only(right: 10),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(schoolNameToShow,
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold),
                          textDirection: pw.TextDirection.rtl),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Information Section
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            margin: pw.EdgeInsets.symmetric(horizontal: 10),
            padding: pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _buildPdfInfoRow(
                              " الصف: ", " ${widget.satge} ${stream}", ttf, 14),
                          _buildPdfInfoRow(
                              " الشعبة: ", " ${widget.section}", ttf, 14),
                          _buildPdfInfoRow(" مجموع التسديد:",
                              " ${widget.totalPaid} ", ttf, 14),
                          _buildPdfInfoRow(" القسط الكلي: ",
                              " ${widget.totalInstallment} ", ttf, 14),
                          _buildPdfInfoRow(" المتبقي: ",
                              " ${widget.remainingInstallment} ", ttf, 14),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _buildPdfInfoRow(
                              " اسم الطالب: ", " ${widget.name}", ttf, 14),
                          _buildPdfInfoRow(
                              " رقم الوصل: ", "${widget.invoice}", ttf, 14),
                          _buildPdfInfoRow(
                              " مبلغ التسديد: ", " ${widget.amount} ", ttf, 14),
                          _buildPdfInfoRow(
                              " تاريخ التسديد: ", " ${widget.date}", ttf, 14),
                          _buildPdfInfoRow(
                              " المرحلة: ", " ${widget.level}", ttf, 14),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Footer
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.only(top: 0, right: 34, left: 34),
            child: pw.Column(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              "مدير الحسابات",
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              selectedAccountManager,
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text("  "),
                      ],
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            widget.addres,
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            "للإستفسار ${widget.phone} ",
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom:
                                      pw.BorderSide(color: PdfColors.black)),
                            ),
                            child: pw.Text(
                              "يرجى الاحتفاظ بالوصل لإبرازه عند الحاجة",
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(pw.MemoryImage(newtechImage.buffer.asUint8List()),
                        width: 120),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "برمجة شركة الحلول التقنية الجديدة 07710995922     تليكرام tech_solu@ ",
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            "تطوير كافة تطبيقات الأندرويد والايفون وسطح المكتب ومواقع الويب وإدارة قواعد البيانات",
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(
      String label, String value, pw.Font ttf, double fontSize) {
    final isRemaining = label.trim() == "المتبقي:";
    final color = isRemaining ? PdfColors.black : PdfColors.black;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 30,
            child: pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
                color: PdfColors.white,
              ),
              child: pw.Text(
                value,
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style:
                    pw.TextStyle(font: ttf, fontSize: fontSize, color: color),
              ),
            ),
          ),
          pw.SizedBox(width: 2),
          pw.Expanded(
            flex: 16,
            child: pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
                color: PdfColors.white,
              ),
              child: pw.Text(
                label,
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    font: ttf,
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
