import 'package:flutter/material.dart';
import 'package:maryams_school_fees/custtem_text_field.dart';
import 'package:maryams_school_fees/data.dart';

class DeleteStudentDialog extends StatefulWidget {
  final int studentId;
  final SqlDb sqlDb;
  final Function readData;

  const DeleteStudentDialog({
    Key? key,
    required this.studentId,
    required this.sqlDb,
    required this.readData,
  }) : super(key: key);

  @override
  _DeleteStudentDialogState createState() => _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends State<DeleteStudentDialog> {
  bool incorrectPassword = false;
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 10),
                  child: Text("اكتب كلمة المرور"),
                ),
                CustemTextField(
                  hint: "كلمة السر",
                  controller: passwordController,
                  keyboardType: TextInputType.number,
                ),
                if (incorrectPassword)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "كلمة السر خاطئة",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              SizedBox(width: 10),
              MaterialButton(
                onPressed: () async {
                  if (passwordController.text == "0000") {
                    int response1 = await widget.sqlDb.deleteData(
                        "DELETE FROM students WHERE id = ${widget.studentId}");
                    int response2 = await widget.sqlDb.deleteData(
                        "DELETE FROM installments WHERE IDStudent = ${widget.studentId}");
                    int response3 = await widget.sqlDb.deleteData(
                        "DELETE FROM additionalFees WHERE studentId = ${widget.studentId}");
                    if (response1 > 0 || response2 > 0 || response3 > 0) {
                      widget.readData();
                      Navigator.of(context).pop(); // إغلاق الـ Modal بعد الحذف
                      passwordController.clear();
                    }
                  } else {
                    setState(() {
                      incorrectPassword = true;
                    });
                  }
                },
                child: Text("موافق"),
              ),
              SizedBox(width: 10),
              MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  passwordController.clear();
                },
                child: Text("الغاء"),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
