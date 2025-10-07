import 'package:flutter/material.dart';

Widget buildTextField(
  TextEditingController controller, {
  String label = '',
  bool obscure = false,
  Widget? prefixicon,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    cursorColor: Colors.blueAccent,
    decoration: InputDecoration(hintText: label, prefixIcon: prefixicon),
  );
}

class AuthBackground extends StatelessWidget {
  final Widget child;
  final double logoHeight;

  const AuthBackground({required this.child, this.logoHeight = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Color.fromARGB(41, 28, 179, 255)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset('assets/images/fire.png', height: logoHeight),
              const SizedBox(height: 20),
              const Text('FireFlow',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent)),
              const SizedBox(height: 40),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
