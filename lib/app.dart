import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maryams_school_fees/add_student.dart';
import 'package:maryams_school_fees/additionalf_ees_page.dart';
import 'package:maryams_school_fees/all_installments.dart';
import 'package:maryams_school_fees/customize/display.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/schools.dart';
import 'package:maryams_school_fees/student_list.dart';

class App extends StatefulWidget {
  final int school;
  final String schoolName;

  const App({super.key, required this.school, required this.schoolName});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  SqlDb sqlDb = SqlDb();
  bool isLoading = true;
  final searchController = TextEditingController();

  List students = [];
  List filteredStudents = [];
  late Timer _timer;
  String lastSearchQuery = '';

  Future readData() async {
    List<Map> response = await sqlDb
        .readData("SELECT * FROM students WHERE school = ${widget.school}");
    students.clear(); // Clear the list before adding new data
    students.addAll(response);

    // Apply the last search query if exists
    if (lastSearchQuery.isNotEmpty) {
      filterStudents(lastSearchQuery);
    } else {
      filteredStudents = students;
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    readData();
    searchController.addListener(() {
      lastSearchQuery = searchController.text;
      filterStudents(lastSearchQuery);
      setState(() {}); // إضافة هذا السطر لتحديث واجهة المستخدم
    });

    // Set up a timer to call readData every 4 seconds
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      readData();
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    searchController.dispose();
    super.dispose();
  }

  void filterStudents(String query) {
    List results = [];
    if (query.isEmpty) {
      results = students;
    } else {
      results = students
          .where((student) => student['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredStudents = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SchoolsPage()),
                );
              },
              icon: Row(
                children: [
                  Text('المدارس'),
                  SizedBox(width: 4),
                  Icon(Icons.home),
                ],
              ),
            ),
            SizedBox(width: 10),
            Text(widget.schoolName),
            SizedBox(width: 20),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'بحث',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            filterStudents('');
                          },
                        )
                      : null,
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AllInstallments(
                            school: widget.school,
                          )),
                );
              },
              icon: Row(
                children: [
                  Text('الاقساط'),
                  SizedBox(width: 4),
                  Icon(Icons.money),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AdditionalFeesPage(
                            school: widget.school,
                          )),
                );
              },
              icon: Row(
                children: [
                  Text('الرسوم الاضافية'),
                  SizedBox(width: 4),
                  Icon(Icons.details),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentListPage(
                            school: widget.school,
                          )),
                );
              },
              icon: Row(
                children: [
                  Text('الطباعة'),
                  SizedBox(width: 4),
                  Icon(Icons.print),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  StudentList(
                    students: filteredStudents,
                    sqlDb: sqlDb,
                    readData: readData,
                    school: widget.school,
                    schoolName: widget.schoolName,
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return AddStudent(
                sqlDb: sqlDb,
                readData: readData,
                school: widget.school,
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
