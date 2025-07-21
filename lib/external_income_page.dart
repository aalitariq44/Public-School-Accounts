import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/data.dart';

class ExternalIncomePage extends StatefulWidget {
  @override
  _ExternalIncomePageState createState() => _ExternalIncomePageState();
}

class _ExternalIncomePageState extends State<ExternalIncomePage>
    with SingleTickerProviderStateMixin {
  SqlDb sqlDb = SqlDb();
  List<Map> incomes = [];
  bool isLoading = true;
  late TabController _tabController;
  double cafeteriaTotal = 0;
  double driversTotal = 0;
  double otherTotal = 0;
  double specialTotal = 0;
  double extraTotal = 0;
  String selectedFilter = 'all'; // new variable for filter selection

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // لتحديث العنوان عند تغيير التاب
    });
    getIncomes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void getIncomes() async {
    String whereClause = '';
    final now = DateTime.now();
    
    if (selectedFilter == 'week') {
      // Get start of week (Saturday)
      final startOfWeek = now.subtract(Duration(days: now.weekday + 1));
      whereClause = " WHERE date >= '${DateFormat('yyyy-MM-dd').format(startOfWeek)}'";
    } else if (selectedFilter == 'month') {
      // Get start of month
      final startOfMonth = DateTime(now.year, now.month, 1);
      whereClause = " WHERE date >= '${DateFormat('yyyy-MM-dd').format(startOfMonth)}'";
    }

    List<Map> response = await sqlDb.readData(
        "SELECT * FROM external_income$whereClause ORDER BY date DESC");
    
    // حساب المجاميع
    double cafTotal = 0;
    double drvTotal = 0;
    double othTotal = 0;
    double speTotal = 0;
    double extTotal = 0;
    
    for (var income in response) {
      if (income['type'] == 'الكافتريا') {
        cafTotal += income['amount'];
      } else if (income['type'] == 'السائقون') {
        drvTotal += income['amount'];
      } else if (income['type'] == 'أخرى') {
        othTotal += income['amount'];
      } else if (income['type'] == 'خاصة') {
        speTotal += income['amount'];
      } else if (income['type'] == 'إضافية') {
        extTotal += income['amount'];
      }
    }

    setState(() {
      incomes = response;
      cafeteriaTotal = cafTotal;
      driversTotal = drvTotal;
      otherTotal = othTotal;
      specialTotal = speTotal;
      extraTotal = extTotal;
      isLoading = false;
    });
  }

  // دالة لتنسيق الأرقام بدون أصفار زائدة
  String formatNumber(double number) {
    return NumberFormat('#,##0').format(number);
  }

  void _showAddIncomeModal() {
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int selectedTabIndex = _tabController.index;
    String selectedType = '';

    switch (selectedTabIndex) {
      case 0:
        selectedType = 'الكافتريا';
        break;
      case 1:
        selectedType = 'السائقون';
        break;
      case 2:
        selectedType = 'أخرى';
        break;
      case 3:
        selectedType = 'خاصة';
        break;
      case 4:
        selectedType = 'إضافية';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إضافة وارد جديد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030), // Changed from 2025 to 2030
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('الرجاء إدخال المبلغ')),
                          );
                          return;
                        }
                        
                        String sql = '''
                          INSERT INTO external_income 
                          (amount, date, type, notes) 
                          VALUES 
                          (${amountController.text}, 
                          '${DateFormat('yyyy-MM-dd').format(selectedDate)}', 
                          '$selectedType', 
                          '${notesController.text}')
                        ''';
                        
                        int response = await sqlDb.insertData(sql);
                        if (response > 0) {
                          getIncomes();
                          Navigator.pop(context);
                        }
                      },
                      child: Text('إضافة'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomeList(String type) {
    final filteredIncomes = incomes.where((income) => income['type'] == type).toList();
    
    return ListView.builder(
      itemCount: filteredIncomes.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              '${formatNumber(filteredIncomes[index]['amount'])} د.ع',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التاريخ: ${filteredIncomes[index]['date']}'),
                if (filteredIncomes[index]['notes'] != null &&
                    filteredIncomes[index]['notes'].toString().isNotEmpty)
                  Text('ملاحظات: ${filteredIncomes[index]['notes']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditIncomeModal(filteredIncomes[index]),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('تأكيد الحذف'),
                        content: Text('هل أنت متأكد من حذف هذا الوارد؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('حذف'),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (confirm) {
                      await sqlDb.deleteData(
                          'DELETE FROM external_income WHERE id = ${filteredIncomes[index]['id']}');
                      getIncomes();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditIncomeModal(Map income) {
    TextEditingController amountController = TextEditingController(text: income['amount'].toString());
    TextEditingController notesController = TextEditingController(text: income['notes'] ?? '');
    DateTime selectedDate = DateTime.parse(income['date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تعديل الوارد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('الرجاء إدخال المبلغ')),
                          );
                          return;
                        }

                        String sql = '''
                          UPDATE external_income 
                          SET amount = ${amountController.text},
                              date = '${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                              notes = '${notesController.text}'
                          WHERE id = ${income['id']}
                        ''';

                        int response = await sqlDb.updateData(sql);
                        if (response > 0) {
                          getIncomes();
                          Navigator.pop(context);
                        }
                      },
                      child: Text('حفظ التعديلات'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String getFilterText() {
    switch (selectedFilter) {
      case 'week':
        return '(هذا الأسبوع)';
      case 'month':
        return '(هذا الشهر)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    String totalText = '';
    // حساب المجموع الكلي
    double totalAmount = cafeteriaTotal + driversTotal + otherTotal + specialTotal + extraTotal;
    
    switch (_tabController.index) {
      case 0:
        totalText = 'مجموع واردات الكافتريا: ${formatNumber(cafeteriaTotal)} د.ع';
        break;
      case 1:
        totalText = 'مجموع واردات السائقون: ${formatNumber(driversTotal)} د.ع';
        break;
      case 2:
        totalText = 'مجموع واردات أخرى: ${formatNumber(otherTotal)} د.ع';
        break;
      case 3:
        totalText = 'مجموع واردات خاصة: ${formatNumber(specialTotal)} د.ع';
        break;
      case 4:
        totalText = 'مجموع واردات إضافية: ${formatNumber(extraTotal)} د.ع';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الواردات الخارجية'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
                getIncomes();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text('جميع الواردات'),
              ),
              PopupMenuItem(
                value: 'week',
                child: Text('هذا الأسبوع'),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text('هذا الشهر'),
              ),
            ],
            icon: Icon(Icons.filter_list),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black, // إضافة هذا السطر
          tabs: [
            Tab(text: 'الكافتريا'),
            Tab(text: 'السائقون'),
            Tab(text: 'أخرى'),
            Tab(text: 'خاصة'),
            Tab(text: 'إضافية'),
          ],
        ),
        backgroundColor: Colors.blue[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            totalText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'المجموع: ${formatNumber(totalAmount)} د.ع',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        getFilterText(),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIncomeList('الكافتريا'),
                      _buildIncomeList('السائقون'),
                      _buildIncomeList('أخرى'),
                      _buildIncomeList('خاصة'),
                      _buildIncomeList('إضافية'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIncomeModal,
        child: Icon(Icons.add),
        tooltip: 'إضافة وارد جديد',
      ),
    );
  }
}