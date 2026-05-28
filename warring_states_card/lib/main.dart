import 'package:flutter/material.dart' hide Card, Hero;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: WarringStatesApp()));
}

class WarringStatesApp extends StatelessWidget {
  const WarringStatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '战国卡牌',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5E6D3),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
      home: const HomeScreen(),
    );
  }
}