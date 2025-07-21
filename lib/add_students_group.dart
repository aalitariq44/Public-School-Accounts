import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/data.dart';

class AddStudentsGroup extends StatefulWidget {
  final SqlDb sqlDb;
  final Function readData;
  final int school;

  const AddStudentsGroup({
    Key? key,
    required this.sqlDb,
    required this.readData,
    required this.school,
  }) : super(key: key);

  @override
  _AddStudentsGroupState createState() => _AddStudentsGroupState();
}

class _AddStudentsGroupState extends State<AddStudentsGroup> {
  final _formKey = GlobalKey<FormState>();
  final List<StudentField> studentFields = [];
  List<String> levels = [];
  List<String> schoolTypes = [];
  final List<String> sections = ['أ', 'ب', 'ج', 'د'];
  final Map<String, List<String>> stages = {
    'ابتدائي': [
      'الأول الإبتدائي',
      'الثاني الإبتدائي',
      'الثالث الإبتدائي',
      'الرابع الإبتدائي',
      'الخامس الإبتدائي',
      'السادس الإبتدائي'
    ],
    'متوسط': ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'],
    'إعدادي': [
      'الرابع',
      'الخامس',
      'السادس',
    ],
  };

  void _getSchoolTypes() async {
    var result = await widget.sqlDb.readData(
        "SELECT schoolTypes FROM schools WHERE id = ${widget.school}");
    if (result.isNotEmpty && mounted) {
      setState(() {
        schoolTypes = result[0]['schoolTypes'].split(',');
        levels = schoolTypes;
        if (levels.isNotEmpty && studentFields.isEmpty) {
          _addStudentField();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getSchoolTypes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (studentFields.isNotEmpty) {
        FocusScope.of(context).requestFocus(studentFields.first.nameFocusNode);
      }
    });
  }

  void _addStudentField() {
    setState(() {
      if (studentFields.isEmpty) {
        if (levels.isNotEmpty) {
          studentFields.add(StudentField(
            nameController: TextEditingController(),
            totalController: TextEditingController(),
            phoneNumberController: TextEditingController(),
            nameFocusNode: FocusNode(),
            level: levels.first,
            stage: stages[levels.first]!.first,
            section: 'أ',
            dateCommencement: DateTime.now(),
          ));
        }
      } else {
        var lastStudentField = studentFields.last;
        studentFields.add(StudentField(
          nameController: TextEditingController(),
          totalController: TextEditingController(
              text: lastStudentField.totalController.text),
          phoneNumberController: TextEditingController(),
          nameFocusNode: FocusNode(),
          level: lastStudentField.level,
          stage: lastStudentField.stage,
          section: lastStudentField.section,
          dateCommencement: lastStudentField.dateCommencement,
          stream: lastStudentField.stream,
        ));
      }

      // تركيز الانتباه على حقل الاسم الرباعي للصف الجديد
      WidgetsBinding.instance.addPostFrameCallback((_) {
        studentFields.last.nameFocusNode.requestFocus();
      });
    });
  }

  void _removeStudentField(int index) {
    setState(() {
      studentFields.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إضافة مجموعة طلاب"),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text("اضافة معلومات الطلاب"),
                SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: studentFields.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: StudentFormField(
                            studentField: studentFields[index],
                            levels: levels,
                            stages: stages,
                            sections: sections,
                            onRemove: () => _removeStudentField(index),
                            onUpdate: () {
                              setState(() {});
                            },
                          ),
                        ),
                        Divider(
                          color: Colors.white,
                          thickness: 2,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 10),
                IconButton(
                  icon: Icon(Icons.add_circle),
                  onPressed: _addStudentField,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Check trial version limit
                      int currentCount = await widget.sqlDb.getStudentCount();
                      int newStudentsCount = studentFields.length;

                      if (currentCount + newStudentsCount > 25) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('نسخة تجريبية'),
                            content: Text(
                                'لا يمكن إضافة ${newStudentsCount} طلاب جدد لأنه سيتجاوز حد النسخة التجريبية (25 طلاب). '
                                'للحصول على النسخة الكاملة، يرجى الاتصال على الرقم 07710995922 أو التواصل عبر واتساب.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('حسناً'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      for (var studentField in studentFields) {
                        String dateCommencementStr = DateFormat('yyyy-MM-dd')
                            .format(studentField.dateCommencement!);
                        int response = await widget.sqlDb.insertData(
                          "INSERT INTO 'students' ('name', 'stage', 'dateCommencement', 'totalInstallment', 'level', 'stream', 'section', 'phoneNumber', 'school') VALUES ('${studentField.nameController.text}', '${studentField.stage}', '$dateCommencementStr', ${studentField.totalController.text}, '${studentField.level}', '${studentField.stream}', '${studentField.section}', '${studentField.phoneNumberController.text}' , '${widget.school}')",
                        );
                        print('Response: $response');
                      }
                      widget
                          .readData(); // تحديث البيانات بعد إدخال الطلاب الجدد
                      Navigator.pop(context);
                    }
                  },
                  child: Text("إضافة المجموعة"),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var field in studentFields) {
      field.nameFocusNode.dispose();
    }
    super.dispose();
  }
}

class StudentField {
  final TextEditingController nameController;
  final TextEditingController totalController;
  final TextEditingController phoneNumberController;
  final FocusNode nameFocusNode;

  DateTime? dateCommencement;
  String level;
  String stage;
  String? stream;
  String section;

  StudentField({
    required this.nameController,
    required this.totalController,
    required this.phoneNumberController,
    required this.nameFocusNode,
    required this.level,
    required this.stage,
    this.stream,
    required this.section,
    this.dateCommencement,
  });
}

class StudentFormField extends StatelessWidget {
  final StudentField studentField;
  final List<String> levels;
  final Map<String, List<String>> stages;
  final List<String> sections;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const StudentFormField({
    Key? key,
    required this.studentField,
    required this.levels,
    required this.stages,
    required this.sections,
    required this.onRemove,
    required this.onUpdate,
  }) : super(key: key);

  void _setTotalInstallment() async {
    var sqlDb = SqlDb(); // إنشاء نسخة جديدة من SqlDb
    var result = await sqlDb.readData(
        "SELECT fee FROM class_fees WHERE className = '${studentField.stage}'");

    if (result.isNotEmpty) {
      studentField.totalController.text = result[0]['fee'].toString();
      onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: studentField.nameController,
                focusNode: studentField.nameFocusNode,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: 'الاسم الرباعي',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم الرباعي';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: studentField.level,
                hint: Text('المرحلة'),
                onChanged: (newValue) {
                  studentField.level = newValue!;
                  studentField.stage = stages[studentField.level]!.first;
                  studentField.stream = null;
                  _setTotalInstallment();
                  onUpdate();
                },
                items: levels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? 'يرجى اختيار المرحلة' : null,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: studentField.stage,
                hint: Text('الصف'),
                onChanged: (newValue) {
                  studentField.stage = newValue!;
                  _setTotalInstallment();
                  onUpdate();
                },
                items: stages[studentField.level]!.map((stage) {
                  return DropdownMenuItem<String>(
                    value: stage,
                    child: Text(stage),
                  );
                }).toList(),
                validator: (value) => value == null ? 'يرجى اختيار الصف' : null,
              ),
            ),
            SizedBox(width: 10),
            if (studentField.level == 'إعدادي')
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: studentField.stream,
                  hint: Text('العلمي - الأدبي'),
                  onChanged: (newValue) {
                    studentField.stream = newValue!;
                    onUpdate();
                  },
                  items: ['العلمي', 'الأدبي'].map((stream) {
                    return DropdownMenuItem<String>(
                      value: stream,
                      child: Text(stream),
                    );
                  }).toList(),
                  validator: (value) =>
                      (studentField.level == 'إعدادي' && value == null)
                          ? 'يرجى اختيار الاختصاص'
                          : null,
                ),
              ),
            if (studentField.level == 'إعدادي') SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: studentField.section,
                hint: Text('الشعبة'),
                onChanged: (newValue) {
                  studentField.section = newValue!;
                  onUpdate();
                },
                items: sections.map((section) {
                  return DropdownMenuItem<String>(
                    value: section,
                    child: Text(section),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? 'يرجى اختيار الشعبة' : null,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: studentField.totalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'القسط الكلي',
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: studentField.phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'رقم الهاتف (اختياري)',
                ),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: studentField.dateCommencement ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  studentField.dateCommencement = pickedDate;
                  onUpdate();
                }
              },
              child: Text(studentField.dateCommencement == null
                  ? 'اختر تاريخ'
                  : DateFormat('yyyy-MM-dd')
                      .format(studentField.dateCommencement!)),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.remove_circle),
              onPressed: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}
