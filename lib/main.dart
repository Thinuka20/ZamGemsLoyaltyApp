import 'package:flutter/material.dart';
import 'package:genix_reports/pages/login.dart';
import 'package:get/get.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Income Report',
      theme: ThemeData(
        primaryColor: const Color(0xFF2C3440),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
