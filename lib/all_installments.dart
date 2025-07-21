import 'package:flutter/material.dart';
import 'package:maryams_school_fees/data.dart';

class AllInstallments extends StatefulWidget {
  final int school;

  const AllInstallments({super.key, required this.school});

  @override
  State<AllInstallments> createState() => _AllInstallmentsState();
}

class _AllInstallmentsState extends State<AllInstallments> {
  SqlDb sqlDb = SqlDb();
  bool isLoading = true;
  List<Map<String, Object?>> installments = [];
  List<Map<String, Object?>> filteredInstallments = [];
  int totalAmount = 0;
  TextEditingController searchController = TextEditingController();

  void filterInstallments(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredInstallments = installments;
      } else {
        filteredInstallments = installments.where((installment) {
          final name = installment['name'].toString().toLowerCase();
          final id = installment['id'].toString();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || id.contains(searchLower);
        }).toList();
      }
    });
  }

  Future readData() async {
    List<Map> response = await sqlDb.readData('''
      SELECT installments.*, students.name, students.school, students.stage, students.stream, students.section
      FROM installments 
      INNER JOIN students ON installments.IDStudent = students.id
      WHERE students.school = ${widget.school}
      ''');
    setState(() {
      installments = response.cast<Map<String, Object?>>();
      filteredInstallments = installments;
      totalAmount = installments.fold(0,
          (sum, item) => sum + (int.tryParse(item['amount'].toString()) ?? 0));
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    readData();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.white);
    final headerTextStyle = textStyle.copyWith(
      color: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "جميع الاقساط",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'البحث باسم الطالب او رقم القسط',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                controller: searchController,
                style: TextStyle(color: Colors.white),
                onChanged: filterInstallments,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "المجموع الكلي: $totalAmount الف دينار عراقي",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          SizedBox(
            width: 20,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (filteredInstallments.isEmpty)
              Center(child: Text("لا توجد نتائج للبحث"))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filteredInstallments.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    var installment = filteredInstallments[index];
                    return Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 25, 2, 79),
                      ),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  margin: EdgeInsets.only(left: 10),
                                  decoration:
                                      BoxDecoration(color: Colors.amber),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                Text(
                                  "اسم الطالب: ",
                                  style: textStyle,
                                ),
                                Text(
                                  "${installment['name']}",
                                  style: textStyle,
                                ),
                                Spacer(),
                                Text(
                                  "رقم المدرسة: ${installment['school']}",
                                  style: textStyle,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "الصف: ${installment['stage']}",
                                  style: textStyle,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "${installment['stream'] == "null" ? '' : installment['stream']}",
                                  style: textStyle,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "الشعبة: ${installment['section'] ?? 'غير محدد'}",
                                  style: textStyle,
                                ),
                                Spacer(),
                                Text(
                                  "رقم القسط: ${installment['id']}",
                                  style: textStyle,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "مبلغ القسط: ",
                                  style: textStyle,
                                ),
                                Text(
                                  "${installment['amount']}",
                                  style: textStyle,
                                ),
                                Text(
                                  "  الف دينار عراقي   ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Spacer(),
                                Text(
                                  "${installment['date']}",
                                  style: headerTextStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
