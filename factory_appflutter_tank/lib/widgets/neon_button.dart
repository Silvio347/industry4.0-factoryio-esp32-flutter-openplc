
import 'package:flutter/material.dart';

Widget neonButton({
  required BuildContext context,
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
}) {
  final cs = Theme.of(context).colorScheme;
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(.75)],
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
