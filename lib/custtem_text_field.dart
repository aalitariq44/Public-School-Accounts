import 'package:flutter/material.dart';

class CustemTextField extends StatelessWidget {
  const CustemTextField({
    super.key,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
    required this.controller,
    required TextInputType keyboardType,
  });
  final String hint;
  final int maxLines;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'لايمكن ترك الحقل فارغا';
        } else {
          return null;
        }
      },
      maxLines: maxLines,
      controller: controller,
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.amber),
          border: buildBorder(),
          enabledBorder: buildBorder(Color.fromARGB(255, 182, 171, 184)),
          focusedBorder: buildBorder(const Color.fromARGB(255, 255, 255, 255)),
          errorBorder: buildBorder(Colors.red)),
    );
  }

  OutlineInputBorder buildBorder([Color]) {
    return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Color ?? Colors.white,
        ));
  }
}
