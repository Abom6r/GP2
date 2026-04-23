import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/services/schedule_service.dart';
import 'src/screens/auth/start_screen.dart';
import 'src/screens/auth_gate.dart';
import 'src/services/tasks_service.dart';
import 'src/services/auth_service.dart';
import 'src/services/profile_service.dart';
import 'src/services/chat_service.dart';

import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bkeuuadujxbtuewgygkm.supabase.co',
    anonKey: 'sb_publishable_A-703Z3wZz8cGn_Ao5HQnw_3tobZwvD',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<ScheduleService>(create: (_) => ScheduleService()),
        Provider<TasksService>(create: (_) => TasksService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Student Orgnizer',
        theme: AppTheme.light(),
        home: const AuthGate(),
        // مثال لو حاب تستخدم AuthGate:
        // home: const AuthGate(),
      ),
    );
  }
}
