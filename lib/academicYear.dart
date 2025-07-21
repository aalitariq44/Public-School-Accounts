
import 'package:maryams_school_fees/data.dart';

class AppSettings {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  String _academicYear = '';
  final SqlDb _sqlDb = SqlDb();

  String get academicYear => _academicYear;

  Future<void> loadAcademicYear() async {
    try {
      List<Map> result = await _sqlDb.readData(
          "SELECT value FROM appSettings WHERE key = 'academicYear'");
      if (result.isNotEmpty) {
        _academicYear = result.first['value'];
      }
    } catch (e) {
      print("Error loading academic year: $e");
    }
  }
}