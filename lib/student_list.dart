import 'package:flutter/material.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/delete_student.dart';
import 'package:maryams_school_fees/edit_bottom_sheet.dart';
import 'package:maryams_school_fees/one_student.dart';

class StudentList extends StatefulWidget {
  final List students;
  final SqlDb sqlDb;
  final Function readData;
  final int school;
  final String schoolName;

  const StudentList({
    Key? key,
    required this.students,
    required this.sqlDb,
    required this.readData,
    required this.school,
    required this.schoolName,
  }) : super(key: key);

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  String? stageFilter;
  String? streamFilter;
  String? sectionFilter;
  final List<String> orderedStages = [
    'الأول الإبتدائي',
    'الثاني الإبتدائي',
    'الثالث الإبتدائي',
    'الرابع الإبتدائي',
    'الخامس الإبتدائي',
    'السادس الإبتدائي',
    'الأول المتوسط',
    'الثاني المتوسط',
    'الثالث المتوسط',
    'الرابع',
    'الخامس',
    'السادس',
  ];
  void readData() {
    widget.readData().then((newData) {
      setState(() {
        // تحديث حالة الويدجت بعد إعادة تحميل البيانات
      });
    });
  }

  int getArabicCharValue(String char) {
    const arabicAlphabet = 'أبتثجحخدذرزسشصضطظعغفقكلمنهوي';
    return arabicAlphabet.indexOf(char.toLowerCase());
  }

  Future<void> updatePhoneNumber(int studentId, String newPhoneNumber) async {
    await widget.sqlDb.updateData('''
    UPDATE students
    SET phoneNumber = '$newPhoneNumber'
    WHERE id = $studentId
  ''');
    readData();
  }

  void _showEditPhoneNumberDialog(
      BuildContext context, int studentId, String? currentPhoneNumber) {
    String newPhoneNumber = currentPhoneNumber ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل رقم الهاتف'),
          content: TextField(
            decoration: InputDecoration(hintText: "أدخل رقم الهاتف الجديد"),
            onChanged: (value) {
              newPhoneNumber = value;
            },
            controller: TextEditingController(text: currentPhoneNumber),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('حفظ'),
              onPressed: () {
                updatePhoneNumber(studentId, newPhoneNumber);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditBottomSheet(
      BuildContext context, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EditBottomSheet(
          student: student,
          sqlDb: widget.sqlDb,
          readData: readData,
          school: widget.school,
          schoolName: widget.schoolName,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List filteredStudents = widget.students.where((student) {
      bool matchesStage =
          (stageFilter == null || student['stage'] == stageFilter);
      bool matchesStream =
          (streamFilter == null || student['stream'] == streamFilter);
      bool matchesSection =
          (sectionFilter == null || student['section'] == sectionFilter);

      return matchesStage && matchesStream && matchesSection;
    }).toList();

    filteredStudents.sort((a, b) {
      String nameA = a['name'].toString().trim();
      String nameB = b['name'].toString().trim();

      int minLength = nameA.length < nameB.length ? nameA.length : nameB.length;

      for (int i = 0; i < minLength; i++) {
        int valueA = getArabicCharValue(nameA[i]);
        int valueB = getArabicCharValue(nameB[i]);

        if (valueA != valueB) {
          return valueA - valueB;
        }
      }

      return nameA.length - nameB.length;
    });

    // Get unique stages that actually have students
    Set<String> stages =
        widget.students.map((s) => s['stage'] as String).toSet();

    // Get streams only for the selected stage and non-null values
    Set<String> streams = Set<String>();
    if (stageFilter != null) {
      streams = widget.students
          .where((s) =>
              s['stage'] == stageFilter &&
              s['stream'] != null &&
              s['stream'] != "null")
          .map((s) => s['stream'] as String)
          .toSet();
    }

    // Get sections for the selected stage
    Set<String> sections = Set<String>();
    if (stageFilter != null) {
      sections = widget.students
          .where((s) => s['stage'] == stageFilter)
          .map((s) => s['section'] as String)
          .toSet();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    FilterChip(
                      label: const Text('عرض الكل'),
                      selected: stageFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          stageFilter = null;
                          streamFilter = null;
                          sectionFilter = null;
                        });
                      },
                    ),
                    ...orderedStages
                        .where((stage) => stages.contains(stage))
                        .map((stage) => FilterChip(
                              label: Text(stage),
                              selected: stageFilter == stage,
                              onSelected: (selected) {
                                setState(() {
                                  stageFilter = selected ? stage : null;
                                  streamFilter = null;
                                  sectionFilter = null;
                                });
                              },
                            )),
                  ],
                ),
                if (stageFilter != null && streams.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: streams.map((stream) {
                        return FilterChip(
                          label: Text(stream),
                          selected: streamFilter == stream,
                          onSelected: (selected) {
                            setState(() {
                              streamFilter = selected ? stream : null;
                              sectionFilter = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                if (stageFilter != null && sections.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: sections.map((section) {
                        return FilterChip(
                          label: Text('شعبة $section'),
                          selected: sectionFilter == section,
                          onSelected: (selected) {
                            setState(() {
                              sectionFilter = selected ? section : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          ListView.builder(
            itemCount: filteredStudents.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, i) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OneStudent(
                        id: filteredStudents[i]['id'],
                      ),
                    ),
                  );
                },
                child: Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.blue,
                          radius: 14,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 300,
                              child: Text(
                                '${filteredStudents[i]['name']}',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                            ),
                            Text(
                              '${(filteredStudents[i]['notes']?.isEmpty == true || filteredStudents[i]['notes'] == null ? '' : (filteredStudents[i]['notes']!.length > 37 ? filteredStudents[i]['notes']!.substring(0, 37) + ' . . .' : filteredStudents[i]['notes']))}',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (context) {
                                return DeleteStudentDialog(
                                  studentId: filteredStudents[i]['id'],
                                  sqlDb: widget.sqlDb,
                                  readData: readData,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete),
                        ),
                        IconButton(
                          onPressed: () {
                            _showEditBottomSheet(context, filteredStudents[i]);
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          width: 320,
                          child: Text(
                            filteredStudents[i]['stream'] == null ||
                                    filteredStudents[i]['stream'] == "null"
                                ? 'الصف :  ${filteredStudents[i]['stage']} -${filteredStudents[i]['section']}- '
                                : 'الصف :  ${filteredStudents[i]['stage']} ${filteredStudents[i]['stream']}  -${filteredStudents[i]['section']}-         ',
                          ),
                        ),
                        Text(
                            'القسط الكلي: ${filteredStudents[i]['totalInstallment']}'),
                        SizedBox(
                          width: 80,
                        ),
                        Text(
                          'رقم الهاتف: ${filteredStudents[i]['phoneNumber']?.isEmpty == true || filteredStudents[i]['phoneNumber'] == null ? 'لا يوجد' : filteredStudents[i]['phoneNumber']}',
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, size: 16),
                          onPressed: () {
                            _showEditPhoneNumberDialog(
                                context,
                                filteredStudents[i]['id'],
                                filteredStudents[i]['phoneNumber']);
                          },
                        ),
                        const Spacer(),
                        Text(
                            'تاريخ المباشرة: ${filteredStudents[i]['dateCommencement']}'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            height: 80,
          )
        ],
      ),
    );
  }
}
