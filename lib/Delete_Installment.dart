

import 'package:flutter/material.dart';
import 'package:maryams_school_fees/custtem_text_field.dart';
import 'package:maryams_school_fees/data.dart';

class DeleteInstallment extends StatefulWidget {
  final Map<String, Object?> installment;
  final Function onDeleteSuccess;

  const DeleteInstallment({
    Key? key,
    required this.installment,
    required this.onDeleteSuccess,
  }) : super(key: key);

  @override
  _DeleteInstallmentState createState() => _DeleteInstallmentState();
}

class _DeleteInstallmentState extends State<DeleteInstallment> {
  final passwordController = TextEditingController();
  SqlDb sqlDb = SqlDb();
  bool incorrectPassword = false;

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
                    int response = await sqlDb.deleteData(
                      "DELETE FROM installments WHERE id = ${widget.installment['id']}",
                    );
                    if (response > 0) {
                      widget.onDeleteSuccess();
                      Navigator.of(context).pop();
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
