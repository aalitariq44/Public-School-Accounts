import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    // Load Amiri-Bold.ttf font for Arabic support
    final fontData = await rootBundle.load('fonts/Amiri-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('الملخص المالي',
                  style: pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold),
                  textDirection: pw.TextDirection.rtl),
              pw.SizedBox(height: 10),
              _buildSummaryTable(ttf),
              pw.SizedBox(height: 20),
              pw.Text('تفاصيل المدارس',
                  style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
                  textDirection: pw.TextDirection.rtl),
              pw.SizedBox(height: 10),
              _buildSchoolsTable(ttf),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  pw.Widget _buildSummaryTable(pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('مجموع الأقساط الكلي (المطلوب)',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('المجموع الكلي الواصل',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('مجموع الطلاب الكلي',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('الواردات الخارجية',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
        ]),
        pw.TableRow(children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('${_formatNumber(grandTotalInstallments)} د.ع',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('${_formatNumber(grandTotalPaid)} د.ع',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('$totalStudents',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('${_formatNumber(externalTotal)} د.ع',
                style: pw.TextStyle(font: ttf),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl),
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
          pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: pw.Text('المدرسة',
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl)),
          pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: pw.Text('عدد الطلاب',
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl)),
          pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: pw.Text('مجموع الأقساط المطلوب',
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl)),
          pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: pw.Text('الأقساط الواصلة',
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl)),
          pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: pw.Text('الرسوم الإضافية الواصلة',
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl)),
          pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: pw.Text('المجموع الواصل للمدرسة',
                  style: pw.TextStyle(font: ttf),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl)),
        ]),
        ...schools.map((school) {
          int schoolId = school['id'];
          int studentCount = schoolStudentCounts[schoolId] ?? 0;
          double paidInstallmentTotal = paidInstallmentTotals[schoolId] ?? 0;
          double totalInstallment = totalInstallmentAmounts[schoolId] ?? 0;
          double feesTotal = feesTotals[schoolId] ?? 0;
          double schoolTotalPaid = paidInstallmentTotal + feesTotal;
          return pw.TableRow(children: [
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${school['name']}',
                    style: pw.TextStyle(font: ttf),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('$studentCount',
                    style: pw.TextStyle(font: ttf),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${_formatNumber(totalInstallment)} د.ع',
                    style: pw.TextStyle(font: ttf),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${_formatNumber(paidInstallmentTotal)} د.ع',
                    style: pw.TextStyle(font: ttf),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${_formatNumber(feesTotal)} د.ع',
                    style: pw.TextStyle(font: ttf),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl)),
            pw.Padding(
                padding: pw.EdgeInsets.all(4),
                child: pw.Text('${_formatNumber(schoolTotalPaid)} د.ع',
                    style: pw.TextStyle(font: ttf),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl)),
          ]);
        }).toList(),
      ],
    );
  }
}
