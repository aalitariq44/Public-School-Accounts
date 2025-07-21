import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/academicYear.dart';
import 'package:maryams_school_fees/password_screen.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class ThemeNotifier with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  _saveToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }
}

class BackupStatus {
  static bool success = false;
  static String message = '';
}

Future<void> performAutoBackup() async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDocDir.path}/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final databasesPath = await databaseFactoryFfi.getDatabasesPath();
    final databasePath = path.join(databasesPath, 'test.db');
    final currentDate =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final backupFileName = 'test.db';
    final backupFolderName = currentDate;

    // Local backup
    final sourceFile = File(databasePath);
    final destinationDir = Directory('${backupDir.path}/$backupFolderName');
    await destinationDir.create(recursive: true);
    final localBackupFile =
        File(path.join(destinationDir.path, backupFileName));
    await sourceFile.copy(localBackupFile.path);

    print('Local backup created successfully at: ${localBackupFile.path}');

    // Online backup
    final response = await Supabase.instance.client.storage
        .from('database2025-2026')
        .upload('$backupFolderName/$backupFileName', sourceFile);

    if (response.isEmpty) {
      print('Online backup uploaded successfully');
      BackupStatus.success = true;
      BackupStatus.message = 'تم إنشاء النسخة الاحتياطية بنجاح';
    } else {
      print('Online backup upload failed');
      BackupStatus.success = true;
      BackupStatus.message = 'نجح في رفع النسخة الاحتياطية عبر الإنترنت';
    }
  } catch (e) {
    print('Error during auto backup: $e');
    BackupStatus.success = false;
    BackupStatus.message = 'حدث خطأ أثناء إنشاء النسخة الاحتياطية: $e';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
  IOClient ioClient = IOClient(httpClient);

  await Supabase.initialize(
    url: 'https://tsyvpjhpogxmqcpeaowb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzeXZwamhwb2d4bXFjcGVhb3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY2ODE1MjgsImV4cCI6MjAzMjI1NzUyOH0.30rbkShbpM_h06pZIAw39Ma2SC0thZi9WiV__lhh4Lk',
    httpClient: ioClient,
  );

  databaseFactory = databaseFactoryFfi;
  await AppSettings().loadAcademicYear();

  // Perform auto backup
  await performAutoBackup();

  final themeNotifier = ThemeNotifier();
  await themeNotifier._loadFromPrefs();

  runApp(
    ChangeNotifierProvider.value(
      value: themeNotifier,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Localizations Sample App',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
          ],
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              backgroundColor:Colors.blue,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontFamily: 'Cairo',
              ),
            ),
            primarySwatch: Colors.blue,
            fontFamily: 'Cairo',
          ),
          darkTheme: ThemeData.dark().copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue[900],
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: BackupStatusWrapper(child: PasswordScreen()),
        );
      },
    );
  }
}

class BackupStatusWrapper extends StatelessWidget {
  final Widget child;

  const BackupStatusWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (BackupStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BackupStatus.message),
            backgroundColor: Colors.green,
          ),
        );
      } else if (BackupStatus.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BackupStatus.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return child;
  }
}
