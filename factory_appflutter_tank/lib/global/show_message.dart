import 'package:flutter/material.dart';

void showTopSnackBar(String message, BuildContext context, bool error) {
  final overlay = Overlay.of(context);

  late final OverlayEntry entry; // precisa estar acessível dentro do builder

  final controller = AnimationController(
    duration: Duration(milliseconds: 300),
    vsync: Navigator.of(context),
  );

  final animation = CurvedAnimation(parent: controller, curve: Curves.easeOut);

  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: 40,
        left: 24,
        right: 24,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, -0.3),
              end: Offset.zero,
            ).animate(animation),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: error
                      ? Colors.redAccent.shade200.withOpacity(0.95)
                      : Colors.green.shade400.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  controller.forward();

  Future.delayed(Duration(seconds: 2), () async {
    await controller.reverse();
    entry.remove();
    controller.dispose();
  });
}
