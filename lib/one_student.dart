import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maryams_school_fees/Delete_Installment.dart';
import 'package:maryams_school_fees/data.dart';
import 'package:maryams_school_fees/printe/print_multiple_additional_fees.dart';
import 'package:maryams_school_fees/printe/print_page.dart';

class OneStudent extends StatefulWidget {
  const OneStudent(
      {super.key,
      required this.id,
      required this.name,
      required this.stage,
      required this.totalInstallment,
      required this.level,
      required this.stream,
      required this.section,
      required this.dateCommencement,
      required this.phoneNumber,
      required this.schoolId});

  final int id;
  final String name;
  final String stage;
  final int totalInstallment;
  final String level;
  final String stream;
  final String section;
  final String dateCommencement;
  final String phoneNumber;

  final dynamic schoolId;

  @override
  State<OneStudent> createState() => _OneStudentState();
}

class _OneStudentState extends State<OneStudent> {
  final premiumAmountController = TextEditingController();
  SqlDb sqlDb = SqlDb();
  bool isLoading = true;
  String studentNotes = '';
  Map<String, dynamic> schoolInfo = {};

  List<Map<String, Object?>> additionalFees = [];

  final _formKey = GlobalKey<FormState>();

  List<Map<String, Object?>> installments = [];
  int totalPaid = 0;
  int remainingInstallment = 0;
  bool isHovering = false;
  bool isPaid = false;

  Future readData() async {
    List<Map> response = await sqlDb
        .readData("SELECT * FROM installments WHERE IDStudent = ${widget.id}");
    installments = List<Map<String, Object?>>.from(response);

    List<Map> additionalFeesResponse = await sqlDb.readData(
        "SELECT * FROM additionalFees WHERE studentId = ${widget.id}");
    additionalFees = List<Map<String, Object?>>.from(additionalFeesResponse);

    totalPaid =
        installments.fold(0, (sum, item) => sum + (item['amount'] as int));
    remainingInstallment = widget.totalInstallment - totalPaid;
    isLoading = false;
    if (mounted) {
      setState(() {});
    }

    List<Map> notesResponse = await sqlDb
        .readData("SELECT notes FROM students WHERE id = ${widget.id}");
    if (notesResponse.isNotEmpty) {
      studentNotes = notesResponse[0]['notes'] ?? '';
    }

    // Fetch school information
    List<Map> schoolResponse = await sqlDb
        .readData("SELECT * FROM schools WHERE id = ${widget.schoolId}");
    if (schoolResponse.isNotEmpty) {
      schoolInfo = Map<String, dynamic>.from(schoolResponse[0]);
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateNotes(String newNotes) async {
    await sqlDb.updateData('''
    UPDATE students
    SET notes = '$newNotes'
    WHERE id = ${widget.id}
  ''');
    readData();
  }

  void _showPrintAllFeesDialog() {
    // Filter out unpaid fees
    List<Map<String, dynamic>> paidFees =
        additionalFees.where((fee) => fee['isPaid'] == 1).toList();

    List<bool> selectedFees = List.filled(paidFees.length, false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('اختر الرسوم الإضافية للطباعة'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: Text('تحديد الكل'),
                      value: selectedFees.every((element) => element),
                      onChanged: (bool? value) {
                        setState(() {
                          for (int i = 0; i < selectedFees.length; i++) {
                            selectedFees[i] = value ?? false;
                          }
                        });
                      },
                    ),
                    ...paidFees.asMap().entries.map((entry) {
                      int index = entry.key;
                      var fee = entry.value;
                      return CheckboxListTile(
                        title: Text('${fee['feeType']} - ${fee['amount']} د.ع'),
                        value: selectedFees[index],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedFees[index] = value ?? false;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('إلغاء'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('طباعة'),
                  onPressed: () {
                    List<Map<String, dynamic>> selectedFeesList = [];
                    for (int i = 0; i < selectedFees.length; i++) {
                      if (selectedFees[i]) {
                        selectedFeesList.add(paidFees[i]);
                      }
                    }
                    Navigator.of(context).pop();
                    _printSelectedFees(selectedFeesList);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _printSelectedFees(List<Map<String, dynamic>> selectedFees) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrintMultipleAdditionalFees(
          name: widget.name,
          stage: widget.stage,
          level: widget.level,
          stream: widget.stream,
          section: widget.section,
          fees: selectedFees,
          schoolName: schoolInfo['name'],
          address: schoolInfo['address'],
          phone: schoolInfo['phone'],
        ),
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context) {
    String newNotes = studentNotes;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل الملاحظات'),
          content: TextField(
            decoration: InputDecoration(hintText: "أدخل الملاحظات الجديدة"),
            onChanged: (value) {
              newNotes = value;
            },
            controller: TextEditingController(text: studentNotes),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('حفظ'),
              onPressed: () {
                updateNotes(newNotes);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAdditionalFee(int feeId) async {
    bool confirmDelete = await _showDeleteConfirmationDialog(context);
    if (confirmDelete) {
      int response = await sqlDb
          .deleteData("DELETE FROM additionalFees WHERE id = $feeId");
      if (response > 0) {
        // تم الحذف بنجاح
        readData(); // إعادة تحميل البيانات
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف الرسم بنجاح')),
        );
      } else {
        // فشل في الحذف
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف الرسم')),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('تأكيد الحذف'),
              content: Text('هل أنت متأكد من حذف هذا الرسم الإضافي؟'),
              actions: <Widget>[
                TextButton(
                  child: Text('إلغاء'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('حذف'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showEditNotesDialog2(Map<String, dynamic> fee) {
    final notesController =
        TextEditingController(text: fee['notes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل الملاحظات'),
          content: TextField(
            controller: notesController,
            decoration: InputDecoration(hintText: "أدخل الملاحظات"),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('حفظ'),
              onPressed: () async {
                String newNotes = notesController.text;
                int response = await sqlDb.updateData('''
                UPDATE additionalFees
                SET notes = '$newNotes'
                WHERE id = ${fee['id']}
              ''');
                if (response > 0) {
                  readData(); // تحديث البيانات
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تحديث الملاحظات بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل في تحديث الملاحظات')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    readData();
  }

  void handleDeleteSuccess() {
    readData(); // إعادة تحميل البيانات عند نجاح الحذف
  }

  void _showAdditionalFeeDialog() {
    String? selectedFeeType;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final customFeeController = TextEditingController();
    bool isPaid = false;
    bool isCustomFee = false;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('إضافة رسوم إضافية'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <String>['تسجيل', 'كتب', 'زي مدرسي', 'رسم آخر']
                          .map((String value) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedFeeType == value
                                ? Colors.blue
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedFeeType = value;
                              isCustomFee = value == 'رسم آخر';
                            });
                          },
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    if (isCustomFee) ...[
                      SizedBox(height: 10),
                      TextFormField(
                        controller: customFeeController,
                        decoration: InputDecoration(
                          labelText: 'أدخل نوع الرسم الجديد',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال نوع الرسم';
                          }
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            child: Text('غير مدفوع'),
                            onPressed: () {
                              setState(() {
                                isPaid = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  !isPaid ? Colors.red : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            child: Text('مدفوع'),
                            onPressed: () {
                              setState(() {
                                isPaid = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isPaid ? Colors.green : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'المبلغ (بالدينار العراقي)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال المبلغ';
                        }
                        if (int.tryParse(value) == null) {
                          return 'الرجاء إدخال رقم صحيح';
                        }
                        if (int.parse(value) <= 0) {
                          return 'المبلغ يجب أن يكون أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('إلغاء'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('حفظ'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        (selectedFeeType != null || isCustomFee)) {
                      String feeType = isCustomFee
                          ? customFeeController.text
                          : selectedFeeType!;
                      int amount = int.parse(amountController.text);
                      String currentDate =
                          DateFormat('yyyy-MM-dd').format(DateTime.now());
                      String notes = notesController.text;
                      int response = await sqlDb.insertData(
                        "INSERT INTO 'additionalFees' ('studentId', 'feeType', 'amount', 'paymentDate', 'isPaid', 'notes') VALUES (${widget.id}, '$feeType', $amount, '$currentDate', ${isPaid ? 1 : 0}, '$notes')",
                      );
                      if (response > 0) {
                        readData();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تمت إضافة الرسم بنجاح'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل في إضافة الرسم'),
                          ),
                        );
                      }
                    } else if (selectedFeeType == null && !isCustomFee) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('الرجاء اختيار نوع الرسم أو إدخال رسم جديد'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _getIconForFeeType(String feeType) {
    switch (feeType) {
      case 'تسجيل':
        return Icon(Icons.how_to_reg, color: Colors.white, size: 20);
      case 'كتب':
        return Icon(Icons.book, color: Colors.white, size: 20);
      case 'زي مدرسي':
        return Icon(Icons.checkroom, color: Colors.white, size: 20);
      default:
        return SizedBox.shrink(); // إرجاع widget فارغ إذا لم يتطابق النوع
    }
  }

  void _showPaymentDialog(Map<String, dynamic> fee) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('دفع الرسم'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('نوع الرسم: ${fee['feeType']}'),
                SizedBox(height: 10),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ (بالدينار العراقي)',
                    errorStyle: TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال مبلغ';
                    }
                    if (int.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    if (int.parse(value) <= 0) {
                      return 'لا يمكن دفع رسم بقيمة 0 أو أقل';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('دفع'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  int amount = int.parse(amountController.text);
                  String currentDate =
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
                  int response = await sqlDb.updateData('''
                  UPDATE additionalFees 
                  SET amount = $amount, paymentDate = '$currentDate', isPaid = 1 
                  WHERE id = ${fee['id']}
                ''');
                  if (response > 0) {
                    readData();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم دفع الرسم بنجاح')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل في دفع الرسم')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الطالب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "اسم الطالب :   ${widget.name}",
                  style: TextStyle(fontSize: 20),
                ),
                Spacer(),
                Text(
                  "رقم الهاتف :   ${widget.phoneNumber}",
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.stream == "null"
                        ? 'الصف :  ${widget.stage} -${widget.section}- '
                        : 'الصف :  ${widget.stage} ${widget.stream}  -${widget.section}',
                    style: TextStyle(fontSize: 20),
                  ),
                  Spacer(),
                  Text(
                    "القسط الكلي  :   ${widget.totalInstallment}   دينار عراقي",
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    "المبالغ المدفوعة :   $totalPaid   دينار عراقي",
                    style: TextStyle(fontSize: 20),
                  ),
                  Spacer(),
                  Text(
                    "القسط المتبقي  :   $remainingInstallment   دينار عراقي",
                    style: TextStyle(
                      fontSize: 20,
                      color:
                          remainingInstallment < 0 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "الملاحظات: ${studentNotes.isEmpty ? 'لا توجد ملاحظات' : studentNotes}",
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditNotesDialog(context);
                  },
                ),
              ],
            ),
            ExpansionTile(
              title: Text(
                "الرسوم الإضافية",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showPrintAllFeesDialog();
                  },
                  child: Text("طباعة الرسوم الإضافية"),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showAdditionalFeeDialog();
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 51, 51, 51)
                                    .withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.credit_card,
                                        color: Colors.black, size: 28),
                                    SizedBox(width: 8),
                                    Column(
                                      children: [
                                        Text(
                                          "اضافة ",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "رسم",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: Colors.black, thickness: 1),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle,
                                        color: Colors.black, size: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...additionalFees
                          .map((fee) => MouseRegion(
                                onEnter: (_) =>
                                    setState(() => isHovering = true),
                                onExit: (_) =>
                                    setState(() => isHovering = false),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: fee['isPaid'] == 1
                                            ? Colors.blue
                                            : Colors.red,
                                        border: Border.all(
                                            color: Colors.black, width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                                    255, 51, 51, 51)
                                                .withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 2,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  fee['feeType']?.toString() ??
                                                      '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 5),
                                                _getIconForFeeType(
                                                    fee['feeType']
                                                            ?.toString() ??
                                                        ''),
                                              ],
                                            ),
                                          ),
                                          Divider(
                                              color: Colors.white,
                                              thickness: 1),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Column(
                                              children: [
                                                Text(
                                                  fee['isPaid'] == 1
                                                      ? "مدفوع"
                                                      : "غير مدفوع",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  "${double.parse(fee['amount'].toString()).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} د.ع",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  "${fee['paymentDate']}",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (fee['notes'] != null &&
                                        fee['notes'].toString().isNotEmpty)
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Tooltip(
                                          message: fee['notes'].toString(),
                                          child: Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    if (isHovering)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    FloatingActionButton(
                                                      mini: true,
                                                      onPressed: () {
                                                        _deleteAdditionalFee(
                                                            fee['id'] as int);
                                                      },
                                                      backgroundColor:
                                                          Colors.white,
                                                      child: Icon(Icons.delete,
                                                          size: 18,
                                                          color: Colors.grey),
                                                    ),
                                                    SizedBox(width: 10),
                                                    FloatingActionButton(
                                                      mini: true,
                                                      onPressed: () {
                                                        _showEditNotesDialog2(
                                                            fee);
                                                      },
                                                      backgroundColor:
                                                          Colors.white,
                                                      child: Icon(Icons.edit,
                                                          size: 18,
                                                          color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "جميع الاقساط",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            SizedBox(height: 10),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: installments.isEmpty
                        ? Center(
                            child: Text(
                              "لم يتم دفع اي قسط لحد الان",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        : ListView.builder(
                            itemCount: installments.length +
                                1, // زيادة العدد بواحد للمساحة الإضافية
                            itemBuilder: (context, index) {
                              if (index == installments.length) {
                                // إضافة مساحة في نهاية القائمة
                                return SizedBox(height: 65);
                              }
                              final installment = installments[index];
                              return Container(
                                margin: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 25, 2, 79),
                                ),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 10),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            radius: 14,
                                            child: Text(
                                              "${index + 1}",
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "مبلغ القسط:  ",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        "${installment['amount']}  ",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        "الف دينار عراقي  ",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Spacer(),
                                      SizedBox(width: 20),
                                      Text(
                                        "${installment['date']}  ",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PrintPage(
                                                name: widget.name,
                                                id: widget.id,
                                                amount:
                                                    "${installment['amount']}",
                                                date:
                                                    '${installment['date']}  ',
                                                satge: widget.stage,
                                                totalPaid: '${totalPaid}',
                                                totalInstallment:
                                                    widget.totalInstallment,
                                                remainingInstallment:
                                                    "${remainingInstallment}",
                                                invoice:
                                                    '${installment['id']}  ',
                                                stage: widget.stage,
                                                level: widget.level,
                                                stream: widget.stream,
                                                section: widget.section,
                                                dateCommencement:
                                                    widget.dateCommencement,
                                                schoolId: widget.schoolId,
                                                schoolName: schoolInfo['name']
                                                        ?.toString() ??
                                                    '',
                                                addres: schoolInfo['address']
                                                        ?.toString() ??
                                                    '',
                                                phone: schoolInfo['phone']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.print),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          showModalBottomSheet(
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (context) {
                                              return DeleteInstallment(
                                                installment: installment,
                                                onDeleteSuccess:
                                                    handleDeleteSuccess,
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.delete),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text("اضافة معلومات القسط"),
                        SizedBox(height: 14),
                        TextFormField(
                          controller: premiumAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'مبلغ القسط',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال مبلغ القسط';
                            }
                            if (int.tryParse(value) == null) {
                              return 'يرجى إدخال رقم صالح';
                            }
                            if (RegExp(r'^0+$').hasMatch(value)) {
                              return 'لايمكن دفع قسط قيمته 0';
                            }
                            if (int.parse(value) < 1000) {
                              return 'لا يجوز دفع قسط أقل من 1000 دينار عراقي';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              DateTime now = DateTime.now();
                              String formattedDate =
                                  DateFormat('yyyy-MM-dd HH:mm').format(now);

                              int response = await sqlDb.insertData(
                                "INSERT INTO 'installments' ('IDStudent', 'amount', 'date') VALUES ('${widget.id}', '${premiumAmountController.text}', '$formattedDate')",
                              );
                              if (response > 0) {
                                readData();
                              }
                              print('Response: $response');

                              Navigator.pop(context);
                              premiumAmountController.clear();
                            }
                          },
                          child: Text("اضافة"),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
