import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/screens/home_screen.dart';

void main() {
  runApp(const XsmbManagerApp());
}

class XsmbManagerApp extends StatelessWidget {
  const XsmbManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff9f1d20);
    return MaterialApp(
      title: 'Xổ số 24/7',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xfffffbf5),
        ),
        scaffoldBackgroundColor: const Color(0xfff7f1e7),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
