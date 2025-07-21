import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'data.dart';

class BackupPage extends StatefulWidget {
  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String databasePath = '.dart_tool\\sqflite_common_ffi\\databases';
  String? backupPath;
  final SqlDb sqlDb = SqlDb();

  @override
  void initState() {
    super.initState();
    _loadBackupPath();
  }

  Future<void> _loadBackupPath() async {
    var result = await sqlDb.readData(
        "SELECT value FROM appSettings WHERE key = 'backupPath'");
    if (result.isNotEmpty) {
      setState(() {
        backupPath = result.first['value'];
      });
    }
  }

  Future<void> _selectBackupPath(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        await sqlDb.updateData(
            "UPDATE appSettings SET value = '$selectedDirectory' WHERE key = 'backupPath'");
        if (await sqlDb.readData(
                "SELECT * FROM appSettings WHERE key = 'backupPath'")
            .then((value) => value.isEmpty)) {
          await sqlDb.insertData(
              "INSERT INTO appSettings (key, value) VALUES ('backupPath', '$selectedDirectory')");
        }
        setState(() {
          backupPath = selectedDirectory;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديد مسار النسخ الاحتياطية بنجاح')),
        );
      }
    } catch (e) {
      handleError(context, e, "خطأ في تحديد مسار النسخ الاحتياطية المحلية");
    }
  }

  Future<void> localBackup(BuildContext context) async {
    if (backupPath == null) {
      await _selectBackupPath(context);
      if (backupPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الرجاء تحديد مسار النسخ الاحتياطية أولاً')),
        );
        return;
      }
    }

    try {
      final currentDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupFileName = 'test.db';
      final backupFolderName = currentDate;

      showLoadingDialog(context, "جارٍ إنشاء النسخة الاحتياطية المحلية...");

      final sourceFile = File(join(databasePath, 'test.db'));
      final destinationDir = Directory('$backupPath\\$backupFolderName');
      await destinationDir.create(recursive: true);
      final localBackupFile = File(join(destinationDir.path, backupFileName));
      await sourceFile.copy(localBackupFile.path);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء النسخة الاحتياطية المحلية بنجاح')),
      );
    } catch (e) {
      handleError(context, e, "خطأ في إنشاء النسخة الاحتياطية المحلية");
    }
  }

  Future<void> onlineBackup(BuildContext context) async {
    try {
      final currentDate =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupFileName = 'test.db';
      final backupFolderName = currentDate;

      showLoadingDialog(context, "جارٍ رفع النسخة الاحتياطية على الإنترنت...");

      final sourceFile = File(join(databasePath, 'test.db'));

      final response = await Supabase.instance.client.storage
          .from('database2025-2026')
          .upload('$backupFolderName/$backupFileName', sourceFile);

      Navigator.of(context).pop(); // إخفاء دائرة التحميل

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم رفع النسخة الاحتياطية على الإنترنت بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم رفع النسخة الاحتياطية على الإنترنت بنجاح')),
        );
      }
    } catch (e) {
      handleError(context, e, "خطأ في رفع النسخة الاحتياطية على الإنترنت");
    }
  }

  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  void handleError(BuildContext context, dynamic error, String errorMessage) {
    Navigator.of(context).pop(); // إخفاء دائرة التحميل في حالة حدوث خطأ
    print("$errorMessage: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$errorMessage: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إنشاء نسخة احتياطية"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'مسار النسخ الاحتياطية المحلية الحالي:',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              backupPath ?? 'لم يتم تحديد المسار بعد',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectBackupPath(context),
              child: Text("تغيير مسار النسخ الاحتياطية المحلية"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => localBackup(context),
              child: Text("إنشاء نسخة احتياطية محلية"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onlineBackup(context),
              child: Text("رفع نسخة احتياطية على الإنترنت"),
            ),
          ],
        ),
      ),
    );
  }
}
