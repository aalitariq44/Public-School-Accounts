import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/academicYear.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintMultipleAdditionalFees extends StatefulWidget {
  final String name;
  final String stage;
  final String level;
  final String stream;
  final String section;
  final String schoolName;
  final String address;
  final String phone;
  final List<Map<String, dynamic>> fees;

  PrintMultipleAdditionalFees({
    required this.name,
    required this.stage,
    required this.level,
    required this.stream,
    required this.section,
    required this.fees,
    required this.schoolName,
    required this.address,
    required this.phone,
  });

  @override
  _PrintMultipleAdditionalFeesState createState() => _PrintMultipleAdditionalFeesState();
}

class _PrintMultipleAdditionalFeesState extends State<PrintMultipleAdditionalFees> {
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
        accountManagers.add('إضافة اسم محاسب');
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
    _loadAccountManagers();
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
          SizedBox(width: 20),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generateMultipleFeesPdf(format),
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        previewPageMargin: EdgeInsets.all(10),
        maxPageWidth: 800 * 1,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
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

  Future<Uint8List> _generateMultipleFeesPdf(PdfPageFormat format) async {
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
              _buildReceipt(ttf, logoImage, newtechImage),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 10),
              _buildReceipt(ttf, logoImage, newtechImage),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReceipt(
      pw.Font ttf, ByteData logoImage, ByteData newtechImage) {
    return pw.Container(
      width: 800,
      color: PdfColor.fromHex('#FFEBEE'),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 2),
        ),
        child: pw.Column(
          children: [
            _buildHeader(ttf, logoImage),
            _buildStudentInfo(ttf),
            _buildFeesTable(ttf),
            _buildTotal(ttf),
            _buildFooter(ttf, newtechImage),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildHeader(pw.Font ttf, ByteData logoImage) {
    return pw.Container(
      width: double.infinity,
      height: 90,
      margin: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
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
          pw.Image(pw.MemoryImage(logoImage.buffer.asUint8List()), width: 70),
          pw.Padding(
            padding: pw.EdgeInsets.only(right: 10),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(widget.schoolName,
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
    );
  }

  pw.Widget _buildStudentInfo(pw.Font ttf) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(10.0),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildPdfInfoRow(
                          " الصف: ",
                          " ${widget.stage} ${widget.stream == "null" ? '' : widget.stream}  ${widget.section}",
                          ttf,
                          14),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildPdfInfoRow(
                          " اسم الطالب: ", " ${widget.name}", ttf, 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(
      String label, String value, pw.Font ttf, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 40,
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
                style: pw.TextStyle(font: ttf, fontSize: fontSize),
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
                    fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFeesTable(pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        ...widget.fees
            .map((fee) => pw.TableRow(
                  children: [
                    _buildTableCell(
                        '${fee['paymentDate']}  ${fee['notes']}', ttf),
                    _buildTableCell('${_formatAmount(fee['amount'])} د.ع', ttf),
                    _buildTableCell(fee['feeType'].toString(), ttf),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font ttf, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: ttf,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildTotal(pw.Font ttf) {
    double total =
        widget.fees.fold(0, (sum, fee) => sum + _parseAmount(fee['amount']));
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      padding: pw.EdgeInsets.all(10),
      child: pw.Text(
        'المجموع: ${_formatAmount(total)} د.ع',
        style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildFooter(pw.Font ttf, ByteData newtechImage) {
    return pw.Container(
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
                      widget.address,
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
                            bottom: pw.BorderSide(color: PdfColors.black)),
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
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount is int) {
      return NumberFormat("#,##0").format(amount);
    } else if (amount is double) {
      // Remove trailing zeros and decimal point if not needed
      return NumberFormat("#,##0.##").format(amount);
    } else {
      return amount.toString();
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount is int) {
      return amount.toDouble();
    } else if (amount is double) {
      return amount;
    } else if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}
