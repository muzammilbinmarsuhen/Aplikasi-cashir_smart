import 'login.dart';
import 'produk.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  runApp(const SmartCashierApp());
}

class SmartCashierApp extends StatelessWidget {
  const SmartCashierApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cashier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      ),
      home: api.token != null ? const HomePage() : const LoginPage(),
    );
  }
}



