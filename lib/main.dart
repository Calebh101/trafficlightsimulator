import 'package:flutter/material.dart';
import 'package:localpkg/theme.dart';
import 'package:trafficlightsimulator/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: brandTheme(
        darkMode: true,
        seedColor: Colors.black,
        iconSize: 12,
      ),
      home: HomePage(),
    );
  }
}