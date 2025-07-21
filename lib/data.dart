import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqlDb {
  static Database? _db;

  Future<Database?> get db async {
    if (_db == null) {
      _db = await initDb();
    }
    return _db;
  }

  Future<Database> initDb() async {
    try {
      String databasePath = await getDatabasesPath();
      String path = join(databasePath, 'test.db');
      Database myDb = await openDatabase(
        path,
        onCreate: _onCreate,
        version: 2, // Update version number to trigger onUpgrade
        onUpgrade: _onUpgrade,
      );
      return myDb;
    } catch (e) {
      print("Error initializing database: $e");
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 2) {
      // Add logoPath column to schools table
      await db.execute('''
        ALTER TABLE schools ADD COLUMN logoPath TEXT
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE "students" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "name" TEXT NOT NULL,
          "stage" TEXT NOT NULL,
          "dateCommencement" TEXT,
          "totalInstallment" INT NOT NULL,
          "level" TEXT,
          "stream" TEXT,
          "section" TEXT,
          "phoneNumber" TEXT,
          "notes" TEXT,
          "school" INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE "installments" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "IDStudent" INTEGER NOT NULL,
          "amount" INT NOT NULL,
          "date" TEXT,
          FOREIGN KEY("IDStudent") REFERENCES "students"("id")
        )
      ''');

      await db.execute('''
        CREATE TABLE "additionalFees" (
         "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
         "studentId" INTEGER NOT NULL,
         "feeType" TEXT NOT NULL,
         "amount" REAL NOT NULL,
         "paymentDate" TEXT NOT NULL,
         "isPaid" INTEGER NOT NULL DEFAULT 0,
         "notes" TEXT,
         FOREIGN KEY("studentId") REFERENCES "students"("id")
       )
     ''');

      await db.execute('''
        CREATE TABLE "appSettings" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "key" TEXT NOT NULL UNIQUE,
          "value" TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE "schools" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "name" TEXT NOT NULL,
          "nameEn" TEXT,
          "schoolTypes" TEXT NOT NULL,
          "address" TEXT,
          "phone" TEXT,
          "logoPath" TEXT
        )
      ''');

      await db.execute('''
       CREATE TABLE "external_income" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "amount" REAL NOT NULL,
        "date" TEXT NOT NULL,
        "notes" TEXT,
        "type" TEXT NOT NULL
      )
      ''');

      await db.execute('''
        CREATE TABLE "accountants" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "name" TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE "class_fees" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "className" TEXT NOT NULL UNIQUE,
          "fee" INTEGER NOT NULL
        )
      ''');

      // Insert default classes with zero fees
      await db.execute('''
        INSERT INTO class_fees (className, fee) VALUES
        ('الأول الإبتدائي', 0),
        ('الثاني الإبتدائي', 0),
        ('الثالث الإبتدائي', 0),
        ('الرابع الإبتدائي', 0),
        ('الخامس الإبتدائي', 0),
        ('السادس الإبتدائي', 0),
        ('الأول المتوسط', 0),
        ('الثاني المتوسط', 0),
        ('الثالث المتوسط', 0),
        ('الرابع', 0),
        ('الخامس', 0),
        ('السادس', 0)
      ''');

      await db
          .insert('appSettings', {'key': 'academicYear', 'value': '2025-2026'});
      await db.insert(
          'appSettings', {'key': 'backupPath', 'value': 'D:\\Backups'});

      print("onCreate =====================================");
    } catch (e) {
      print("Error creating tables: $e");
    }
  }

  Future<List<Map>> readData(String sql) async {
    try {
      Database? myDb = await db;
      List<Map> response = await myDb!.rawQuery(sql);
      return response;
    } catch (e) {
      print("Error reading data: $e");
      return [];
    }
  }

  Future<int> insertData(String sql) async {
    try {
      Database? myDb = await db;
      int response = await myDb!.rawInsert(sql);
      return response;
    } catch (e) {
      print("Error inserting data: $e");
      return 0;
    }
  }

  Future<int> updateData(String sql) async {
    try {
      Database? myDb = await db;
      int response = await myDb!.rawUpdate(sql);
      return response;
    } catch (e) {
      print("Error updating data: $e");
      return 0;
    }
  }

  Future<int> deleteData(String sql) async {
    try {
      Database? myDb = await db;
      int response = await myDb!.rawDelete(sql);
      return response;
    } catch (e) {
      print("Error deleting data: $e");
      return 0;
    }
  }

  Future<void> myDeleteDatabase() async {
    try {
      String databasePath = await getDatabasesPath();
      String path = join(databasePath, 'test.db');
      await deleteDatabase(path);
    } catch (e) {
      print("Error deleting database: $e");
    }
  }

  Future<List<String>> getAccountants() async {
    try {
      Database? myDb = await db;
      // التحقق من وجود محاسبين
      List<Map> count =
          await myDb!.rawQuery('SELECT COUNT(*) as count FROM accountants');
      if (count[0]['count'] == 0) {
        // إذا كان الجدول فارغاً، أضف محاسباً افتراضياً
        await myDb.insert('accountants', {'name': 'المحاسب'});
      }

      List<Map> result = await myDb.query('accountants', columns: ['name']);
      return result.map((item) => item['name'].toString()).toList();
    } catch (e) {
      print("Error fetching accountants: $e");
      return ['المحاسب'];
    }
  }

  Future<int> getStudentCount() async {
    try {
      Database? myDb = await db;
      List<Map> result =
          await myDb!.rawQuery('SELECT COUNT(*) as count FROM students');
      return result.first['count'] as int;
    } catch (e) {
      print("Error counting students: $e");
      return 0;
    }
  }
}
