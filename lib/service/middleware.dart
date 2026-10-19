import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/pages/dashboard/dashboard.dart';
import 'package:gamatutor_kanban/pages/login/login.dart';

class AuthMiddleware extends StatelessWidget {
  const AuthMiddleware({super.key});

  Future<bool> _hasValidSession() async {
    final token = await SecureTokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasValidSession(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == true) {
          return const Dashboard();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
