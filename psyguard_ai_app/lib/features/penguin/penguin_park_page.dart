import 'package:flutter/material.dart';

class PenguinParkPage extends StatefulWidget {
  const PenguinParkPage({super.key});

  @override
  State<PenguinParkPage> createState() => _PenguinParkPageState();
}

class _PenguinParkPageState extends State<PenguinParkPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('測試頁面：如果這能跑，代表環境修好了！'),
      ),
    );
  }
}
