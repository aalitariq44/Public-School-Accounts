import 'package:flutter/material.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/main.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SqlDb sqlDb = SqlDb();
  final TextEditingController _academicYearController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _accountantNameController =
      TextEditingController();
  List<Map> accountants = [];

  String? _currentAcademicYear;
  String? _storedPassword;

  // Update these variables
  List<bool> _isExpanded = [false, false, false]; // Update to add new panel
  List<Map> classFees = [];
  Map<int, TextEditingController> _feeControllers = {};
  Map<int, int> _originalFees = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAccountants();
    _loadClassFees();
  }

  Future<void> _loadSettings() async {
    List<Map> academicYearResult = await sqlDb
        .readData("SELECT value FROM appSettings WHERE key = 'academicYear'");
    List<Map> passwordResult = await sqlDb
        .readData("SELECT value FROM appSettings WHERE key = 'appPassword'");

    setState(() {
      _currentAcademicYear = academicYearResult.isNotEmpty
          ? academicYearResult.first['value']
          : '';
      _storedPassword =
          passwordResult.isNotEmpty ? passwordResult.first['value'] : '';
      _academicYearController.text = _currentAcademicYear ?? '';
    });
  }

  Future<void> _loadAccountants() async {
    List<Map> result = await sqlDb.readData("SELECT * FROM accountants");
    setState(() {
      accountants = result;
    });
  }

  Future<void> _loadClassFees() async {
    List<Map> result = await sqlDb
        .readData("SELECT * FROM class_fees ORDER BY id");
    setState(() {
      classFees = result;
      // Store original values and create controllers
      for (var fee in result) {
        _feeControllers[fee['id']] = TextEditingController(text: fee['fee'].toString());
        _originalFees[fee['id']] = fee['fee'];
      }
    });
  }

  Future<void> _updateDarkMode(bool value) async {
    await sqlDb.updateData(
        "UPDATE appSettings SET value = '${value.toString()}' WHERE key = 'darkMode'");
    setState(() {});
    Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
  }

  Future<void> _updatePassword() async {
    if (_oldPasswordController.text == _storedPassword) {
      if (_newPasswordController.text.isNotEmpty) {
        await sqlDb.updateData(
            "UPDATE appSettings SET value = '${_newPasswordController.text}' WHERE key = 'appPassword'");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _loadSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الرجاء إدخال كلمة المرور الجديدة')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('كلمة المرور القديمة غير صحيحة')),
      );
    }
  }


  Future<void> _addAccountant() async {
    if (_accountantNameController.text.isNotEmpty) {
      await sqlDb.insertData(
          "INSERT INTO accountants (name) VALUES ('${_accountantNameController.text}')");
      _accountantNameController.clear();
      await _loadAccountants();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة المحاسب بنجاح')),
      );
    }
  }

  Future<void> _deleteAccountant(int id) async {
    await sqlDb.deleteData("DELETE FROM accountants WHERE id = $id");
    await _loadAccountants();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف المحاسب بنجاح')),
    );
  }

  Future<void> _updateClassFee(int id, String newFee) async {
    if (newFee.isNotEmpty) {
      await sqlDb.updateData(
          "UPDATE class_fees SET fee = ${int.parse(newFee)} WHERE id = $id");
      await _loadClassFees();
    }
  }

  Future<void> _saveAllClassFees() async {
    try {
      for (var fee in classFees) {
        int id = fee['id'];
        String newValue = _feeControllers[id]?.text ?? '';
        if (newValue.isNotEmpty && int.parse(newValue) != _originalFees[id]) {
          await sqlDb.updateData(
              "UPDATE class_fees SET fee = ${int.parse(newValue)} WHERE id = $id");
        }
      }
      await _loadClassFees(); // Reload to update original values
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ جميع التغييرات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ التغييرات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Column(
                children: [
                  Text(
                    'العام الدراسي الحالي: ${_currentAcademicYear ?? "غير محدد"}',
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            SizedBox(height: 10),
            ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _isExpanded[index] = !_isExpanded[index];
                });
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text('تغيير كلمة المرور'),
                    );
                  },
                  body: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _oldPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور القديمة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور الجديدة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _updatePassword,
                          child: Text('تغيير كلمة المرور'),
                        ),
                      ],
                    ),
                  ),
                  isExpanded: _isExpanded[0],
                ),
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text('إدارة المحاسبين'),
                    );
                  },
                  body: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _accountantNameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم المحاسب',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _addAccountant,
                              child: Text('إضافة'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ...accountants
                            .map((accountant) => Card(
                                  child: ListTile(
                                    title: Text(accountant['name']),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () =>
                                          _deleteAccountant(accountant['id']),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                  isExpanded: _isExpanded[1],
                ),
                ExpansionPanel(
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text('مبلغ الأقساط لكل صف'),
                    );
                  },
                  body: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ...classFees.map((fee) {
                          return Card(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(fee['className']),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _feeControllers[fee['id']],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'المبلغ',
                                        suffixText: 'دينار',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveAllClassFees,
                          child: Text('حفظ جميع التغييرات'),
                        ),
                      ],
                    ),
                  ),
                  isExpanded: _isExpanded[2],
                ),
              ],
            ),
            SizedBox(height: 20),
            Card(
              child: ListTile(
                title: Text('الوضع الداكن'),
                trailing: Switch(
                  value: themeNotifier.isDarkMode,
                  onChanged: _updateDarkMode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
