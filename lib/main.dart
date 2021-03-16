import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(primary: Colors.green))),
      home: LoginPage(),
    );
  }
}
