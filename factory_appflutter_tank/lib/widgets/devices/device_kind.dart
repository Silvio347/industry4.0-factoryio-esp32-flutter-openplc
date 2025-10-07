import 'package:flutter/material.dart';

enum DeviceKind { tank, forno }

extension DeviceKindX on DeviceKind {
  String get label => this == DeviceKind.tank ? 'Tanque' : 'Forno';

  IconData get icon => this == DeviceKind.tank
      ? Icons.water_drop
      : Icons.local_fire_department;
}


class SwitcherPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SwitcherPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Click to change the view',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x3300FFFF), // light translucent cyan
              border: Border.all(color: const Color(0x8800FFFF)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black45,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.cyanAccent),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.expand_more,
                    size: 16,
                    color: Colors.cyanAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}