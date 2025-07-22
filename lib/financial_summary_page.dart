import 'package:flutter/material.dart';
import 'package:maryams_school_fees/data.dart';
import 'printe/financial_summary_print_page.dart';

class FinancialSummaryPage extends StatefulWidget {
  @override
  _FinancialSummaryPageState createState() => _FinancialSummaryPageState();
}

class _FinancialSummaryPageState extends State<FinancialSummaryPage> {
  SqlDb sqlDb = SqlDb();
  bool isLoading = true;
  List<Map> schools = [];
  Map<int, int> schoolStudentCounts = {};
  int totalStudents = 0;
  Map<int, double> paidInstallmentTotals = {};
  Map<int, double> totalInstallmentAmounts = {};
  Map<int, double> feesTotals = {};
  double externalTotal = 0;
  double grandTotalPaid = 0;
  double grandTotalInstallments = 0;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    List<Map> schoolsResponse = await sqlDb.readData("SELECT * FROM schools");
    
    List<Map> studentCounts = await sqlDb.readData(
        "SELECT CAST(school AS INTEGER) as school, COUNT(*) as count FROM students GROUP BY school");
    
    List<Map> paidInstallments = await sqlDb.readData(
        "SELECT i.amount, CAST(s.school AS INTEGER) as school FROM installments i INNER JOIN students s ON i.IDStudent = s.id");
    
    List<Map> allInstallments = await sqlDb.readData(
        "SELECT s.totalInstallment, CAST(s.school AS INTEGER) as school FROM students s");

    List<Map> additionalFees = await sqlDb.readData(
        "SELECT af.amount, CAST(s.school AS INTEGER) as school FROM additionalFees af INNER JOIN students s ON af.studentId = s.id WHERE af.isPaid = 1");
    
    List<Map> externalIncome =
        await sqlDb.readData("SELECT amount FROM external_income");

    Map<int, int> tempSchoolStudentCounts = {};
    int tempTotalStudents = 0;
    for (var count in studentCounts) {
      if (count['school'] != null) {
        int schoolId = int.parse(count['school'].toString());
        int studentCount = count['count'];
        tempSchoolStudentCounts[schoolId] = studentCount;
        tempTotalStudents += studentCount;
      }
    }

    Map<int, double> tempPaidInstallmentTotals = {};
    for (var installment in paidInstallments) {
      int schoolId = installment['school'] ?? 0;
      double amount = (installment['amount'] ?? 0).toDouble();
      tempPaidInstallmentTotals[schoolId] = (tempPaidInstallmentTotals[schoolId] ?? 0) + amount;
    }

    Map<int, double> tempTotalInstallmentAmounts = {};
    for (var student in allInstallments) {
      int schoolId = student['school'] ?? 0;
      double amount = (student['totalInstallment'] ?? 0).toDouble();
      tempTotalInstallmentAmounts[schoolId] = (tempTotalInstallmentAmounts[schoolId] ?? 0) + amount;
    }

    Map<int, double> tempFeesTotals = {};
    for (var fee in additionalFees) {
      int schoolId = fee['school'] ?? 0;
      double amount = (fee['amount'] ?? 0).toDouble();
      tempFeesTotals[schoolId] = (tempFeesTotals[schoolId] ?? 0) + amount;
    }

    double tempExternalTotal = 0;
    for (var income in externalIncome) {
      tempExternalTotal += (income['amount'] ?? 0).toDouble();
    }

    double tempGrandTotalPaid = tempExternalTotal;
    tempPaidInstallmentTotals.values.forEach((total) => tempGrandTotalPaid += total);
    tempFeesTotals.values.forEach((total) => tempGrandTotalPaid += total);

    double tempGrandTotalInstallments = 0;
    tempTotalInstallmentAmounts.values.forEach((total) => tempGrandTotalInstallments += total);

    setState(() {
      schools = schoolsResponse;
      schoolStudentCounts = tempSchoolStudentCounts;
      totalStudents = tempTotalStudents;
      paidInstallmentTotals = tempPaidInstallmentTotals;
      totalInstallmentAmounts = tempTotalInstallmentAmounts;
      feesTotals = tempFeesTotals;
      externalTotal = tempExternalTotal;
      grandTotalPaid = tempGrandTotalPaid;
      grandTotalInstallments = tempGrandTotalInstallments;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الملخص المالي'),
        backgroundColor: Colors.blue,
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(Icons.print),
              tooltip: 'طباعة الملخص المالي',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        // ignore: prefer_const_constructors
                        FinancialSummaryPrintPage(
                      schools: schools,
                      schoolStudentCounts: schoolStudentCounts,
                      paidInstallmentTotals: paidInstallmentTotals,
                      totalInstallmentAmounts: totalInstallmentAmounts,
                      feesTotals: feesTotals,
                      externalTotal: externalTotal,
                      grandTotalPaid: grandTotalPaid,
                      grandTotalInstallments: grandTotalInstallments,
                      totalStudents: totalStudents,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryGrid(),
                  SizedBox(height: 20),
                  Text(
                    'تفاصيل المدارس',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildSchoolsDataTable(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          'مجموع الأقساط الكلي (المطلوب)',
          '${grandTotalInstallments.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
          Colors.orange,
        ),
        _buildSummaryCard(
          'المجموع الكلي الواصل',
          '${grandTotalPaid.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
          Colors.blue,
        ),
        _buildSummaryCard(
          'مجموع الطلاب الكلي',
          totalStudents.toString(),
          Colors.purple,
        ),
        _buildSummaryCard(
          'الواردات الخارجية',
          '${externalTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolsDataTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: DataTable(
        columns: [
          DataColumn(label: Text('المدرسة', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('عدد الطلاب', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('مجموع الأقساط المطلوب', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الأقساط الواصلة', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الرسوم الإضافية الواصلة', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('المجموع الواصل للمدرسة', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: schools.map((school) {
          int schoolId = school['id'];
          int studentCount = schoolStudentCounts[schoolId] ?? 0;
          double paidInstallmentTotal = paidInstallmentTotals[schoolId] ?? 0;
          double totalInstallment = totalInstallmentAmounts[schoolId] ?? 0;
          double feesTotal = feesTotals[schoolId] ?? 0;
          double schoolTotalPaid = paidInstallmentTotal + feesTotal;

          return DataRow(
            cells: [
              DataCell(Text(school['name'])),
              DataCell(Text(studentCount.toString())),
              DataCell(Text('${totalInstallment.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع')),
              DataCell(Text('${paidInstallmentTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع')),
              DataCell(Text('${feesTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع')),
              DataCell(Text('${schoolTotalPaid.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
