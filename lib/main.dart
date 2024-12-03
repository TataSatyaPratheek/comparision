import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import the game logic file (create it in `lib/`).
import 'comparison_game.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComparisonGameStateProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Comparison Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ComparisonScreen(),
    );
  }
}
