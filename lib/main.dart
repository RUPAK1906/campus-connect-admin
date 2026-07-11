import 'package:flutter/foundation.dart'; // REQUIRED for platform detection
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
    // Note: ensure this parameter matches your SDK version (usually 'anonKey')
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

      // NEW: Wrap the entire routing system with the DesktopMobileWrapper
      builder: (context, child) {
        return DesktopMobileWrapper(
          child: child!,
        );
      },

      // Automatically check if we have a valid session
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginScreen()
          : const AdminDashboard(),
    );
  }
}

// NEW: Desktop/Mobile Wrapper Widget with 75% Zoom Scale
class DesktopMobileWrapper extends StatelessWidget {
  final Widget child;

  const DesktopMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Detect if the app is running on a Desktop OS
    final isDesktopOS = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopOS) {
      return Container(
        color: const Color(0xFF121212),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 1. The actual logical size of the phone
              const double logicalWidth = 430.0;
              const double logicalHeight = 940.0;

              // 2. The shrink factor (75% = 0.75)
              const double scale = 0.75;

              // 3. The physical size the box will actually take on your desktop monitor
              final double scaledWidth = logicalWidth * scale;
              final double scaledHeight = logicalHeight * scale;

              return Container(
                width: scaledWidth,
                height: scaledHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  // We scale the border radius so the corners look correct at 75%
                  borderRadius: BorderRadius.circular(24.0 * scale),
                ),
                // 4. FittedBox acts exactly like Chrome DevTools zoom.
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: logicalWidth,
                    height: logicalHeight,
                    // 5. MediaQuery override ensures the internal app still thinks it has full space
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: const Size(logicalWidth, logicalHeight),
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // If it is a Mobile OS, return the app completely full-screen
    return child;
  }
}