import 'package:factory_appflutter_tank/first_screen/login.dart';
import 'package:flutter/material.dart';

void main() => runApp(const FactoryHMI());

class FactoryHMI extends StatelessWidget {
  const FactoryHMI({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E676),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Factory HMI (MQTT)',
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: LoginScreen(),
    );
  }
}
