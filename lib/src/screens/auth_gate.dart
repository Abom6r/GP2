import 'package:flutter/material.dart';
import 'package:iu_community/src/screens/auth/start_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        // أثناء تحميل حالة المستخدم
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          // المستخدم مو مسجل دخول → نعرض شاشة البداية 
          return const StartScreen();
         
        } else {
          // المستخدم مسجل دخول → نروح للهوم
          return const HomeScreen();
        }
      },
    );
  }
}
