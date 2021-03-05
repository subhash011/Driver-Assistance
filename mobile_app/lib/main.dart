import 'package:PotholeDetector/services/obstacle.dart';
import 'package:PotholeDetector/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// GetIt getIt = GetIt.instance;

void main() {
  // getIt.registerSingleton<Obstacles>(Obstacles());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}
