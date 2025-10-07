import 'package:flutter/material.dart';
import '../backend/api_service.dart';
import '../first_screen/widgets_first_screen.dart';
import '../global/show_message.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showTopSnackBar('Fill in all fields', context, true);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      showTopSnackBar('Invalid email', context, true);
      return;
    }

    if (password.length < 6) {
      showTopSnackBar('Password must be at least 6 characters', context, true);
      return;
    }

    if (password != confirmPassword) {
      showTopSnackBar('Passwords do not match', context, true);
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.post(
      '/api/register',
      body: {'email': email, 'password': password},
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      showTopSnackBar('Account created successfully', context, false);
      Navigator.pop(context);
    } else {
      showTopSnackBar('Registration failed', context, true);
    }
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
            buildTextField(
              label: 'Confirm Password',
              _confirmPasswordController,
              obscure: true,
              prefixicon: Icon(Icons.lock_outline, color: Colors.white70),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(color: Colors.blueAccent)
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back to login',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
