import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/pages/dashboard/dashboard.dart';
import 'package:gamatutor_kanban/pages/login/login.dart';
import 'package:gamatutor_kanban/service/loginService.dart';
import 'package:gamatutor_kanban/model/user.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = LoginService();
  bool _isChecking = true;
  User? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final user = await _authService.tryAutoLogin();
    if (mounted) {
      setState(() {
        _authenticatedUser = user;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
        ),
      );
    }

    if (_authenticatedUser != null) {
      return Dashboard(user: _authenticatedUser);
    }

    return const LoginPage();
  }
}