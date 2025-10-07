import 'dart:ui';
import 'package:flutter/material.dart';

Widget glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(.06),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: child,
      ),
    ),
  );
}
