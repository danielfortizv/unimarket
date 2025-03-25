import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unimarket/screens/login_screen.dart';
import 'package:unimarket/screens/main_navigation_screen.dart';
import 'package:unimarket/screens/register_screen.dart';
import 'theme/theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  runApp(const UniMarketApp());
}

class UniMarketApp extends StatelessWidget {
  const UniMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniMarket',
      theme: AppTheme.lightTheme,
      
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(initialIndex: 0), // asegúrate de tener esta pantalla
      },
    );
  }
}
