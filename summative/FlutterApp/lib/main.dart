import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/prediction_screen.dart';

void main() {
  runApp(const GPAPredictorApp());
}

class GPAPredictorApp extends StatelessWidget {
  const GPAPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student GPA Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B2FE0)),
        textTheme: GoogleFonts.soraTextTheme(),
        useMaterial3: true,
      ),
      home: const PredictionScreen(),
    );
  }
}
