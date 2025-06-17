import 'package:flutter/material.dart';

import 'config/session.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/farmers/farmer_dashboard.dart';
import 'screens/providers/provider_dashboard.dart';
// import 'screens/admin/admin_dashboard.dart';

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = '/login'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Drone App',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/farmer': (context) => const FarmerDashboard(),
        // '/provider': (context) => const ProviderDashboard(),
        // '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}
