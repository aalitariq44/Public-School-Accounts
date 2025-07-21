import 'package:flutter/material.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/schools.dart';

class PasswordScreen extends StatefulWidget {
  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final SqlDb sqlDb = SqlDb();
  String? _storedPassword;
  bool _isSettingNewPassword = false;

  @override
  void initState() {
    super.initState();
    _loadPassword();
    // تركيز تلقائي على حقل كلمة المرور
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPassword() async {
    if (!mounted) return;
    List<Map> result = await sqlDb
        .readData("SELECT value FROM appSettings WHERE key = 'appPassword'");
    if (!mounted) return;
    if (result.isNotEmpty) {
      setState(() {
        _storedPassword = result.first['value'];
      });
    } else {
      setState(() {
        _isSettingNewPassword = true;
      });
    }
  }

  Future<void> _setPassword(String password) async {
    await sqlDb.insertData(
        "INSERT OR REPLACE INTO appSettings (key, value) VALUES ('appPassword', '$password')");
    if (!mounted) return; 
    setState(() {
      _storedPassword = password;
      _isSettingNewPassword = false;
    });
  }

  void _verifyPassword() {
    if (_passwordController.text == _storedPassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SchoolsPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('كلمة المرور غير صحيحة')),
      );
    }
  }

  void _handleSubmit() {
    if (_isSettingNewPassword) {
      if (_passwordController.text.isNotEmpty) {
        _setPassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء كلمة المرور بنجاح')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SchoolsPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الرجاء إدخال كلمة مرور')),
        );
      }
    } else {
      _verifyPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isSettingNewPassword ? 'إنشاء كلمة مرور' : 'إدخال كلمة المرور'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isSettingNewPassword
                    ? 'أدخل كلمة مرور جديدة'
                    : 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: Text(_isSettingNewPassword ? 'إنشاء' : 'دخول'),
            ),
          ],
        ),
      ),
    );
  }
}
