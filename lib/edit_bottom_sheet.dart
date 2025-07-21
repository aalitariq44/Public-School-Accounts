import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/data.dart';

class EditBottomSheet extends StatefulWidget {
  final Map<String, dynamic> student;
  final SqlDb sqlDb;
  final Function readData;
  final int school;
  final String schoolName;

  const EditBottomSheet({
    Key? key,
    required this.student,
    required this.sqlDb,
    required this.readData,
    required this.school,
    required this.schoolName,
  }) : super(key: key);

  @override
  _EditBottomSheetState createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<EditBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController totalController;
  late TextEditingController phoneController;
  DateTime? dateCommencement;
  String? level;
  String? stage;
  String? stream;
  String? section;
  bool dateCommencementError = false;

  final List<String> levels = ['ابتدائي', 'متوسط', 'إعدادي'];
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
    nameController = TextEditingController(text: widget.student['name']);
    totalController = TextEditingController(
        text: widget.student['totalInstallment'].toString());
    phoneController =
        TextEditingController(text: widget.student['phoneNumber']);
    level = widget.student['level'];
    stage = widget.student['stage'];
    stream = widget.student['stream'];
    section = widget.student['section'];
    dateCommencement = DateTime.tryParse(widget.student['dateCommencement']);
  }

  @override
  void dispose() {
    nameController.dispose();
    totalController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<bool> _showPasswordDialog(BuildContext context) async {
    String enteredPassword = '';
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('أدخل كلمة المرور'),
          content: TextField(
            autofocus: true,
            obscureText: true,
            onChanged: (value) {
              enteredPassword = value;
            },
            decoration: InputDecoration(hintText: "كلمة المرور"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('تأكيد'),
              onPressed: () {
                Navigator.of(context).pop(enteredPassword == '0000');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text("تعديل معلومات الطالب",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'الاسم الرباعي'),
              validator: (value) =>
                  value!.isEmpty ? 'يرجى إدخال الاسم الرباعي' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: stage,
              decoration: InputDecoration(labelText: 'الصف'),
              items: stages[level]
                  ?.map((stage) =>
                      DropdownMenuItem(value: stage, child: Text(stage)))
                  .toList(),
              onChanged: (value) => setState(() => stage = value),
              validator: (value) => value == null ? 'يرجى اختيار الصف' : null,
            ),
            SizedBox(height: 16),
            if (level == 'إعدادي')
              DropdownButtonFormField<String>(
                value: stream,
                decoration: InputDecoration(labelText: 'العلمي - الأدبي'),
                items: ['العلمي', 'الأدبي']
                    .map((stream) =>
                        DropdownMenuItem(value: stream, child: Text(stream)))
                    .toList(),
                onChanged: (value) => setState(() => stream = value),
                validator: (value) => (level == 'إعدادي' && value == null)
                    ? 'يرجى اختيار الاختصاص'
                    : null,
              ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: section,
              decoration: InputDecoration(labelText: 'الشعبة'),
              items: sections
                  .map((section) =>
                      DropdownMenuItem(value: section, child: Text(section)))
                  .toList(),
              onChanged: (value) => setState(() => section = value),
              validator: (value) => value == null ? 'يرجى اختيار الشعبة' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: totalController,
              decoration: InputDecoration(labelText: 'القسط الكلي'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value!.isEmpty ? 'يرجى إدخال القسط الكلي' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: dateCommencement ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) setState(() => dateCommencement = picked);
              },
              child: Text(dateCommencement == null
                  ? 'اختر تاريخ المباشرة'
                  : DateFormat('yyyy-MM-dd').format(dateCommencement!)),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    dateCommencement != null) {
                  bool requirePassword = nameController.text != widget.student['name'] ||
                      totalController.text != widget.student['totalInstallment'].toString();

                  bool canProceed = true;
                  if (requirePassword) {
                    canProceed = await _showPasswordDialog(context);
                  }

                  if (canProceed) {
                    String dateCommencementStr =
                        DateFormat('yyyy-MM-dd').format(dateCommencement!);
                    int response = await widget.sqlDb.updateData(
                        "UPDATE students SET name = '${nameController.text}', stage = '$stage', totalInstallment = ${totalController.text}, level = '$level', stream = '$stream', section = '$section', dateCommencement = '$dateCommencementStr', phoneNumber = '${phoneController.text}' WHERE id = ${widget.student['id']}");
                    if (response > 0) {
                      await widget.sqlDb.updateData(
                          "UPDATE installments SET nameStudent = '${nameController.text}' WHERE IDStudent = ${widget.student['id']}");
                      widget.readData();
                      Navigator.pop(context);
                    }
                  } else if (requirePassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('كلمة المرور غير صحيحة')),
                    );
                  }
                } else {
                  setState(() => dateCommencementError = dateCommencement == null);
                }
              },
              child: Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}