import 'package:flutter/material.dart';

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';

class FinancialSummaryPrintPage extends StatelessWidget {
  final List<Map> schools;
  final Map<int, int> schoolStudentCounts;
  final Map<int, double> paidInstallmentTotals;
  final Map<int, double> totalInstallmentAmounts;
  final Map<int, double> feesTotals;
  final double externalTotal;
  final double grandTotalPaid;
  final double grandTotalInstallments;
  final int totalStudents;

  const FinancialSummaryPrintPage({
    Key? key,
    required this.schools,
    required this.schoolStudentCounts,
    required this.paidInstallmentTotals,
    required this.totalInstallmentAmounts,
    required this.feesTotals,
    required this.externalTotal,
    required this.grandTotalPaid,
    required this.grandTotalInstallments,
    required this.totalStudents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('طباعة الملخص المالي')),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final amiriBold = await rootBundle.load("fonts/Amiri-Bold.ttf");
    final ttf = pw.Font.ttf(amiriBold);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('الملخص المالي', style: pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildSummaryTable(ttf),
              pw.SizedBox(height: 20),
              pw.Text('تفاصيل المدارس', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildSchoolsTable(ttf),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildSummaryTable(pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('مجموع الأقساط الكلي (المطلوب)', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('المجموع الكلي الواصل', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('مجموع الطلاب الكلي', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('الواردات الخارجية', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
        ]),
        pw.TableRow(children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('${grandTotalInstallments.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('${grandTotalPaid.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('$totalStudents', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('${externalTotal.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl),
          ),
        ]),
      ],
    );
  }

  pw.Widget _buildSchoolsTable(pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(children: [
          pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('المدرسة', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
          pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('عدد الطلاب', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
          pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('مجموع الأقساط المطلوب', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
          pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('الأقساط الواصلة', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
          pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('الرسوم الإضافية الواصلة', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
          pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('المجموع الواصل للمدرسة', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
        ]),
        ...schools.map((school) {
          int schoolId = school['id'];
          int studentCount = schoolStudentCounts[schoolId] ?? 0;
          double paidInstallmentTotal = paidInstallmentTotals[schoolId] ?? 0;
          double totalInstallment = totalInstallmentAmounts[schoolId] ?? 0;
          double feesTotal = feesTotals[schoolId] ?? 0;
          double schoolTotalPaid = paidInstallmentTotal + feesTotal;
          return pw.TableRow(children: [
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${school['name']}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('$studentCount', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${totalInstallment.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${paidInstallmentTotal.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${feesTotal.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('${schoolTotalPaid.toStringAsFixed(2)} د.ع', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf), textDirection: pw.TextDirection.rtl)),
          ]);
        }).toList(),
      ],
    );
  }
}
