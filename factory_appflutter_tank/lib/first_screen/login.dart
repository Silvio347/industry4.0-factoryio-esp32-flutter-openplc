import 'package:factory_appflutter_tank/first_screen/create_account.dart';
import 'package:factory_appflutter_tank/first_screen/forgot_pwd.dart';
import 'package:factory_appflutter_tank/first_screen/widgets_first_screen.dart';
import 'package:factory_appflutter_tank/main/main_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    // final email = _emailController.text.trim();
    // final password = _passwordController.text.trim();

    // if (email.isEmpty || password.isEmpty) {
    //   showTopSnackBar('Preencha todos os campos', context);
    //   return;
    // }

    // final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    // if (!emailRegex.hasMatch(email)) {
    //   showTopSnackBar('Email inválido', context);
    //   return;
    // }

    // if (password.length < 6) {
    //   showTopSnackBar('A senha deve ter no mínimo 6 caracteres', context);
    //   return;
    // }

    // setState(() => _isLoading = true);

    // final response = await ApiService.post(
    //   '/api/login',
    //   body: {'email': email, 'password': password},
    // );

    // setState(() => _isLoading = false);

    // if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    // } else {
    //   showTopSnackBar('Credenciais inválidas', context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          children: [
            buildTextField(
              label: 'Email',
              _emailController,
              prefixicon: Icon(Icons.email, color: Colors.white70),
            ),
            SizedBox(height: 20),
            buildTextField(
              label: 'Password',
              _passwordController,
              obscure: true,
              prefixicon: Icon(Icons.lock, color: Colors.white70),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(color: Colors.blueAccent)
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );
                  },
                  child: Text(
                    'Create account',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                Text(
                  '|',
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
