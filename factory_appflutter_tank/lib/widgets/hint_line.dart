import 'package:flutter/material.dart';

class HintLine extends StatelessWidget {
  final String text;
  const HintLine({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ],
    );
  }
}