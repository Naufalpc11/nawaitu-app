import 'package:flutter/material.dart';

class DescriptionCard extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? text;

  const DescriptionCard({
    super.key,
    this.controller,
    this.hintText,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInputMode = controller != null;

    return Container(
      width: double.infinity,
      padding: isInputMode
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF7D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF9E79F)),
      ),
      child: isInputMode
          ? TextField(
              controller: controller,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText ?? 'Tambahkan catatan khusus disini..',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              (text != null && text!.isNotEmpty)
                  ? text!
                  : 'Tidak ada catatan khusus.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
    );
  }
}

