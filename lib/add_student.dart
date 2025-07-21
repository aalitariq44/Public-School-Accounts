import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/add_students_group.dart';
import 'package:maryams_school_fees/data.dart';

class AddStudent extends StatefulWidget {
  final SqlDb sqlDb;
  final Function readData;
  final int school;

  const AddStudent({
    Key? key,
    required this.sqlDb,
    required this.readData,
    required this.school,
  }) : super(key: key);

  @override
  _AddStudentState createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final totalController = TextEditingController();
  final phoneController = TextEditingController();
  final nameFocusNode = FocusNode();
  DateTime? dateCommencement = DateTime.now();
  String? level;
  String? stage;
  String? stream;
  String? section = 'أ';
  bool dateCommencementError = false;
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
  @override
  void initState() {
    super.initState();
    _getSchoolTypes();
    nameFocusNode.requestFocus();
  }

  void _getSchoolTypes() async {
    var result = await widget.sqlDb.readData(
        "SELECT schoolTypes FROM schools WHERE id = ${widget.school}");
    if (result.isNotEmpty && mounted) {
      setState(() {
        schoolTypes = result[0]['schoolTypes'].split(',');
        levels = schoolTypes;
        if (levels.isNotEmpty) {
          level = levels.first;
          if (stages.containsKey(level)) {
            stage = stages[level]!.first;
            _setTotalInstallment();
          }
        }
      });
    }
  }

  void _updateStage() {
    if (level != null && stages.containsKey(level)) {
      setState(() {
        stage = stages[level]?.first;
        if (stage != null) {
          _setTotalInstallment();
        }
      });
    }
  }

  void _setTotalInstallment() async {
    if (stage == null) return;
    var result = await widget.sqlDb.readData(
      "SELECT fee FROM class_fees WHERE className = '$stage'"
    );
    if (result.isNotEmpty && mounted) {
      setState(() {
        totalController.text = result[0]['fee'].toString();
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check trial version limit
      int studentCount = await widget.sqlDb.getStudentCount();
      if (studentCount >= 25) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('نسخة تجريبية'),
            content: Text(
                'لقد وصلت إلى الحد الأقصى لعدد الطلاب (25) في النسخة التجريبية. للحصول على النسخة الكاملة، يرجى الاتصال على الرقم 07710995922 أو التواصل عبر واتساب.'),
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

      if (dateCommencement != null && level != null && stage != null) {
        String dateCommencementStr =
            DateFormat('yyyy-MM-dd').format(dateCommencement!);
        int response = await widget.sqlDb.insertData(
          "INSERT INTO 'students' ('name', 'stage', 'dateCommencement', 'totalInstallment', 'level', 'stream', 'section', 'phoneNumber', 'school') VALUES ('${nameController.text}', '$stage', '$dateCommencementStr', ${totalController.text}, '$level', '$stream', '$section', '${phoneController.text}', '${widget.school}')",
        );
        if (response > 0) {
          widget.readData();
        }
        print('Response: $response');

        Navigator.pop(context);
        nameController.clear();
        totalController.clear();
        phoneController.clear();
        setState(() {
          dateCommencement = DateTime.now();
          if (levels.isNotEmpty) {
            level = levels.first;
            stage = stages[level]?.first;
            _setTotalInstallment();
          }
          stream = null;
          section = 'أ';
          dateCommencementError = false;
        });
      } else {
        setState(() {
          dateCommencementError = true;
        });
      }
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      _submitForm();
    }
  }

  Widget _buildStageDropdown() {
    if (level == null || !stages.containsKey(level)) {
      return SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      value: stage,
      hint: Text('الصف'),
      onChanged: (newValue) {
        setState(() {
          stage = newValue;
          _setTotalInstallment();
        });
      },
      items: stages[level]!.map((stageValue) {
        return DropdownMenuItem<String>(
          value: stageValue,
          child: Text(stageValue),
        );
      }).toList(),
      validator: (value) => value == null ? 'يرجى اختيار الصف' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Form(
            key: _formKey,
            child: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text("اضافة معلومات الطالب"),
                  SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
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
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: level,
                    hint: Text('المرحلة'),
                    onChanged: (newValue) {
                      setState(() {
                        level = newValue;
                        _updateStage();
                        stream = null;
                        _setTotalInstallment();
                      });
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
                  SizedBox(height: 10),
                  _buildStageDropdown(),
                  SizedBox(height: 10),
                  if (level == 'إعدادي')
                    DropdownButtonFormField<String>(
                      value: stream,
                      hint: Text('العلمي - الأدبي'),
                      onChanged: (newValue) {
                        setState(() {
                          stream = newValue;
                        });
                      },
                      items: ['العلمي', 'الأدبي'].map((stream) {
                        return DropdownMenuItem<String>(
                          value: stream,
                          child: Text(stream),
                        );
                      }).toList(),
                      validator: (value) => (level == 'إعدادي' && value == null)
                          ? 'يرجى اختيار الاختصاص'
                          : null,
                    ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: section,
                    hint: Text('الشعبة'),
                    onChanged: (newValue) {
                      setState(() {
                        section = newValue;
                      });
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
                  SizedBox(height: 10),
                  TextFormField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'القسط الكلي',
                    ),
                  ),
                  SizedBox(height: 14),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'رقم الهاتف (اختياري)',
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(height: 14),
                  Text("تاريخ المباشرة"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: dateCommencement ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dateCommencement = pickedDate;
                          dateCommencementError = false;
                        });
                      }
                    },
                    child: Text(dateCommencement == null
                        ? 'اختر تاريخ'
                        : DateFormat('yyyy-MM-dd').format(dateCommencement!)),
                  ),
                  if (dateCommencementError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'يرجى اختيار تاريخ المباشرة',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 20),
                  IconButton(
                    onPressed: _submitForm,
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "اضافة",
                          style: TextStyle(fontSize: 20),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddStudentsGroup(
                                  sqlDb: widget.sqlDb,
                                  readData: widget.readData,
                                  school: widget.school,
                                ),
                              ),
                            );
                          },
                          child: Text("إضافة مجموعة"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
