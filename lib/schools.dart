import 'dart:io';

import 'package:flutter/material.dart';
import 'package:maryams_school_fees/app.dart';
import 'package:maryams_school_fees/backup_page.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/external_income_page.dart';
import 'package:maryams_school_fees/settings.dart';
import 'package:file_picker/file_picker.dart';

class SchoolsPage extends StatefulWidget {
  @override
  _SchoolsPageState createState() => _SchoolsPageState();
}

class _SchoolsPageState extends State<SchoolsPage> {
  SqlDb sqlDb = SqlDb();
  List<Map> schools = [];
  bool isLoading = true;
  Map<int, int> schoolStudentCounts = {};
  int totalStudents = 0;
  String academicYear = '';
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<String> selectedTypes = [];
  String? selectedLogoPath;

  @override
  void initState() {
    super.initState();
    getSchools();
    getStudentCounts();
    getAcademicYear();
  }

  void getSchools() async {
    List<Map> response = await sqlDb.readData("SELECT * FROM schools");
    setState(() {
      schools = response;
      isLoading = false;
    });
  }

  Future<void> getStudentCounts() async {
    List<Map> counts = await sqlDb.readData(
        "SELECT CAST(school AS INTEGER) as school, COUNT(*) as count FROM students GROUP BY school");

    setState(() {
      totalStudents = 0;
      for (var count in counts) {
        if (count['school'] != null) {
          int schoolId = int.parse(count['school'].toString());
          int studentCount = count['count'];
          schoolStudentCounts[schoolId] = studentCount;
          totalStudents += studentCount;
        }
      }
    });
  }

  Future<void> getAcademicYear() async {
    List<Map> response = await sqlDb
        .readData("SELECT value FROM appSettings WHERE key = 'academicYear'");
    if (response.isNotEmpty) {
      setState(() {
        academicYear = response[0]['value'];
      });
    }
  }

  Future<void> _showFinancialSummary() async {
    List<Map> installments = await sqlDb.readData(
        "SELECT i.amount, i.IDStudent, CAST(s.school AS INTEGER) as school FROM installments i INNER JOIN students s ON i.IDStudent = s.id");
    List<Map> additionalFees = await sqlDb.readData(
        "SELECT af.amount, af.studentId, CAST(s.school AS INTEGER) as school FROM additionalFees af INNER JOIN students s ON af.studentId = s.id WHERE af.isPaid = 1");
    List<Map> externalIncome =
        await sqlDb.readData("SELECT amount FROM external_income");

    Map<int, double> installmentTotals = {};
    Map<int, double> feesTotals = {};

    for (var installment in installments) {
      int schoolId = installment['school'] ?? 0;
      double amount = (installment['amount'] ?? 0).toDouble();
      installmentTotals[schoolId] = (installmentTotals[schoolId] ?? 0) + amount;
    }

    for (var fee in additionalFees) {
      int schoolId = fee['school'] ?? 0;
      double amount = (fee['amount'] ?? 0).toDouble();
      feesTotals[schoolId] = (feesTotals[schoolId] ?? 0) + amount;
    }

    double externalTotal = 0;
    for (var income in externalIncome) {
      externalTotal += (income['amount'] ?? 0).toDouble();
    }

    double grandTotal = externalTotal;
    installmentTotals.values.forEach((total) => grandTotal += total);
    feesTotals.values.forEach((total) => grandTotal += total);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          'المجموع الكلي:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${grandTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
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
                    double installmentTotal = installmentTotals[schoolId] ?? 0;
                    double feesTotal = feesTotals[schoolId] ?? 0;
                    double schoolTotal = installmentTotal + feesTotal;

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
                                '${schoolTotal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow('الأقساط:', installmentTotal),
                          _buildDetailRow('الرسوم الإضافية:', feesTotal),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      selectedLogoPath = result.files.single.path;
    }
  }

  Future<void> _addNewSchool() async {
    selectedTypes = [];
    selectedLogoPath = null;
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إضافة مدرسة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _pickLogo();
                    setDialogState(() {});
                  },
                  icon: Icon(Icons.image),
                  label: Text('اختيار شعار المدرسة'),
                ),
                if (selectedLogoPath != null && selectedLogoPath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(
                      File(selectedLogoPath!),
                      height: 50, // تغيير من 100 إلى 50
                      width: 50, // تغيير من 100 إلى 50
                      fit: BoxFit.cover,
                    ),
                  ),
                TextField(
                  controller: _nameArController,
                  decoration: InputDecoration(
                    hintText: "اسم المدرسة بالعربي",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _nameEnController,
                  decoration: InputDecoration(
                    hintText: "School Name in English",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: "عنوان المدرسة",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: "رقم الهاتف",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text("نوع المدرسة:"),
                CheckboxListTile(
                  title: Text("ابتدائية"),
                  value: selectedTypes.contains("ابتدائي"),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value!) {
                        selectedTypes.add("ابتدائي");
                      } else {
                        selectedTypes.remove("ابتدائي");
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text("متوسطة"),
                  value: selectedTypes.contains("متوسط"),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value!) {
                        selectedTypes.add("متوسط");
                      } else {
                        selectedTypes.remove("متوسط");
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text("اعدادية"),
                  value: selectedTypes.contains("إعدادي"),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value!) {
                        selectedTypes.add("إعدادي");
                      } else {
                        selectedTypes.remove("إعدادي");
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearControllers();
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameArController.text.isNotEmpty && selectedTypes.isNotEmpty) {
                  String types = selectedTypes.join(',');
                  await sqlDb.insertData('''
                    INSERT INTO schools (name, nameEn, schoolTypes, address, phone, logoPath) 
                    VALUES (
                      '${_nameArController.text}',
                      '${_nameEnController.text}',
                      '$types',
                      '${_addressController.text}',
                      '${_phoneController.text}',
                      '${selectedLogoPath ?? ''}'
                    )
                  ''');
                  _clearControllers();
                  Navigator.pop(context);
                  getSchools();
                }
              },
              child: Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSchool(Map school) async {
    _nameArController.text = school['name'] ?? '';
    _nameEnController.text = school['nameEn'] ?? '';
    _addressController.text = school['address'] ?? '';
    _phoneController.text = school['phone'] ?? '';
    selectedLogoPath = school['logoPath'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('تعديل المدرسة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _pickLogo();
                    setDialogState(() {});
                  },
                  icon: Icon(Icons.image),
                  label: Text('اختيار شعار المدرسة'),
                ),
                if (selectedLogoPath != null && selectedLogoPath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(
                      File(selectedLogoPath!),
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                TextField(
                  controller: _nameArController,
                  decoration: InputDecoration(
                    hintText: "اسم المدرسة بالعربي",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _nameEnController,
                  decoration: InputDecoration(
                    hintText: "School Name in English",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: "عنوان المدرسة",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: "رقم الهاتف",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearControllers();
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameArController.text.isNotEmpty) {
                  await sqlDb.updateData('''
                    UPDATE schools 
                    SET name = '${_nameArController.text}',
                        nameEn = '${_nameEnController.text}',
                        address = '${_addressController.text}',
                        phone = '${_phoneController.text}',
                        logoPath = '${selectedLogoPath ?? ''}'
                    WHERE id = ${school['id']}
                  ''');
                  _clearControllers();
                  Navigator.pop(context);
                  getSchools();
                }
              },
              child: Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSchool(int schoolId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحذير!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'سيتم حذف المدرسة وجميع الطلاب والأقساط المتعلقة بها. هذا الإجراء لا يمكن التراجع عنه.'),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: "أدخل كلمة المرور",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (_passwordController.text == '0000') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('كلمة المرور غير صحيحة')),
                );
              }
              _passwordController.clear();
            },
            child: Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete related records first
        await sqlDb.deleteData(
            "DELETE FROM installments WHERE IDStudent IN (SELECT id FROM students WHERE school = $schoolId)");
        await sqlDb.deleteData(
            "DELETE FROM additionalFees WHERE studentId IN (SELECT id FROM students WHERE school = $schoolId)");
        await sqlDb.deleteData("DELETE FROM students WHERE school = $schoolId");
        await sqlDb.deleteData("DELETE FROM schools WHERE id = $schoolId");

        setState(() {
          getSchools();
          getStudentCounts();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف المدرسة')),
        );
      }
    }
  }

  void _clearControllers() {
    _nameArController.clear();
    _nameEnController.clear();
    _addressController.clear();
    _phoneController.clear();
    selectedTypes.clear();
    selectedLogoPath = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('المدارس', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'مجموع الطلاب: $totalStudents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'العام الدراسي: $academicYear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            icon: Row(
              children: [
                Text('الاعدادات'),
                SizedBox(width: 4),
                Icon(Icons.settings, color: Colors.black),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BackupPage(),
                ),
              );
            },
            icon: Row(
              children: [
                Text('النسخ الاحتياطي'),
                SizedBox(width: 4),
                Icon(Icons.backup, color: Colors.black),
              ],
            ),
          ),
          IconButton(
            onPressed: _showFinancialSummary,
            icon: Row(
              children: [
                Text('ملخص مالي'),
                SizedBox(width: 4),
                Icon(Icons.assessment, color: Colors.black),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExternalIncomePage(),
                ),
              );
            },
            icon: Row(
              children: [
                Text('الواردات الخارجية'),
                SizedBox(width: 4),
                Icon(Icons.monetization_on, color: Colors.black),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('تنبيه'),
                    content: Text('هذه الميزة غير متاحة في النسخة التجريبية'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('حسناً'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Row(
              children: [
                Text('كتابة قبول '),
                SizedBox(width: 4),
                Icon(Icons.app_registration, color: Colors.black),
              ],
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : schools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد مدارس',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يمكنك إضافة مدرسة جديدة بالضغط على زر الإضافة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: schools.length,
                    itemBuilder: (context, index) {
                      int schoolId = schools[index]['id'] ?? 0;
                      int studentCount = schoolStudentCounts[schoolId] ?? 0;
                      String name = schools[index]['name'] ?? '';
                      String nameEn = schools[index]['nameEn'] ?? '';
                      String schoolTypes = schools[index]['schoolTypes'] ?? '';
                      String phone = schools[index]['phone'] ?? '';

                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => App(
                                  school: schoolId,
                                  schoolName: name,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4), // تغيير من 12 إلى 6
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue[100],
                                  ),
                                  child: ClipOval(
                                    child: schools[index]['logoPath'] != null && schools[index]['logoPath'].isNotEmpty
                                        ? Image.file(
                                            File(schools[index]['logoPath']),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'images/logo.png',
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'images/logo.png',
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (nameEn.isNotEmpty)
                                        Text(
                                          nameEn,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      SizedBox(height: 4),
                                      Text(
                                        schoolTypes.replaceAll(',', ' - '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      if (phone.isNotEmpty)
                                        Text(
                                          'هاتف: $phone',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'عدد الطلاب: $studentCount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'رقم المدرسة: $schoolId',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Icon(Icons.edit, color: Colors.black),
                                        title: Text('تعديل'),
                                      ),
                                      onTap: () {
                                        Future.delayed(
                                          Duration(seconds: 0),
                                          () => _editSchool(schools[index]),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Icon(Icons.delete,
                                            color: Colors.black),
                                        title: Text('حذف',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                      onTap: () {
                                        Future.delayed(
                                          Duration(seconds: 0),
                                          () => _deleteSchool(
                                              schools[index]['id']),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSchool,
        child: Icon(Icons.add, color: Colors.black),
        tooltip: 'إضافة مدرسة جديدة',
      ),
    );
  }
}
