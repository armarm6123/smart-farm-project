import 'package:flutter/material.dart';
import 'login_screen.dart'; // import ไฟล์ login ที่คุณสร้างไว้

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Farm Platform',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginScreen(), // กำหนดให้หน้าแรกคือหน้า Login
    );
  }
}
