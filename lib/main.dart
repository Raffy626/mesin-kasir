import 'package:flutter/material.dart';
import 'splash_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesin Kasir',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.teal[700]!,
          secondary: Colors.teal[300]!,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}