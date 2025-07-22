import 'package:flutter/material.dart';
import 'package:maryams_school_fees/data.dart';

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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المجموع الكلي الواصل:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${grandTotalPaid.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSummaryCard(
                    'مجموع الأقساط الكلي (المطلوب)',
                    '${grandTotalInstallments.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
                    Colors.orange,
                  ),
                  SizedBox(height: 16),
                  _buildSummaryCard(
                    'مجموع الطلاب الكلي',
                    totalStudents.toString(),
                    Colors.purple,
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الواردات الخارجية:',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        Text(
                          '${externalTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  ...schools.map((school) {
                    int schoolId = school['id'];
                    int studentCount = schoolStudentCounts[schoolId] ?? 0;
                    double paidInstallmentTotal = paidInstallmentTotals[schoolId] ?? 0;
                    double totalInstallment = totalInstallmentAmounts[schoolId] ?? 0;
                    double feesTotal = feesTotals[schoolId] ?? 0;
                    double schoolTotalPaid = paidInstallmentTotal + feesTotal;

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                school['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                '${schoolTotalPaid.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow('عدد الطلاب:', studentCount.toDouble()),
                          _buildDetailRow('مجموع الأقساط المطلوب:', totalInstallment),
                          _buildDetailRow('الأقساط الواصلة:', paidInstallmentTotal),
                          _buildDetailRow('الرسوم الإضافية الواصلة:', feesTotal),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} د.ع',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
