import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://xjswyyleoscbuxkvsife.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhqc3d5eWxlb3NjYnV4a3ZzaWZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0Mzg1OTEsImV4cCI6MjA5ODAxNDU5MX0.oX5klH4PD7wWDQlmPKpOqzGqPjdc-m5riAUJMKqrICk',
  );

  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
        useMaterial3: true,
      ),
      // Automatically check if we have a valid session
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginScreen()
          : const AdminDashboard(),
    );
  }
}