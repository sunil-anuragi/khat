import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/app_constants.dart';
import 'package:flutter_chat_demo/constants/color_constants.dart';
import 'package:flutter_chat_demo/controllers/auth_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../widgets/widgets.dart';
import 'pages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (_formKey.currentState!.validate()) {
      bool isSuccess;
      
      if (_isLogin) {
        isSuccess = await _authController.handleEmailPasswordSignIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        isSuccess = await _authController.handleEmailPasswordSignUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (isSuccess) {
        Get.off(() => HomePage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ever(_authController.status, (status) {
      switch (status) {
        case AuthStatus.authenticateError:
          Get.snackbar(
            'Error',
            'Authentication failed',
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case AuthStatus.authenticateCanceled:
          Get.snackbar(
            'Info',
            'Authentication canceled',
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case AuthStatus.authenticated:
          Get.snackbar(
            'Success',
            'Authentication successful',
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        default:
          break;
      }
    });

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     _isLogin ? AppConstants.loginTitle : 'Sign Up',
      //     style: TextStyle(color: ColorConstants.primaryColor),
      //   ),
      //   centerTitle: true,
      // ),
      
      body: Center(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _handleEmailPasswordAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Login',
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          bool isSuccess = await _authController.handleSignIn();
                          if (isSuccess) {
                            Get.off(() => HomePage());
                          }
                        },
                        icon: Icon(Icons.g_mobiledata_rounded),
                        label: Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          minimumSize: Size(double.infinity, 50),
                          side: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() => _authController.isLoading.value
              ? Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
