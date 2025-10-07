import 'package:flutter/material.dart';
import '../backend/api_service.dart';
import '../first_screen/widgets_first_screen.dart';
import '../global/show_message.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showTopSnackBar('Enter your email', context, true);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      showTopSnackBar('Invalid email', context, true);
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.post(
      '/api/forgot-password',
      body: {'email': email},
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      showTopSnackBar('Password reset link sent', context, false);
      Navigator.pop(context);
    } else {
      showTopSnackBar('Failed to send reset email', context, true);
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
              prefixicon: Icon(Icons.email_outlined, color: Colors.white70),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(color: Colors.blueAccent)
                : ElevatedButton(
                    onPressed: _recoverPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Send reset email',
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
