import 'package:flutter/material.dart';

import '../ui/screens/sweep_shell.dart';
import 'theme.dart';

class SweepApp extends StatelessWidget {
  const SweepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweep',
      debugShowCheckedModeBanner: false,
      theme: SweepTheme.light,
      home: const SweepShell(),
    );
  }
}
