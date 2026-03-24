import 'dart:convert';
import 'package:http/http.dart' as http;

// ── API base URL ──────────────────────────────────────────────────────────────
// Android emulator  → http://10.0.2.2:8000
// iOS simulator     → http://127.0.0.1:8000
// Physical device   → http://192.168.1.74:8000  (your Mac's current local IP)
// Render (deployed) → https://linear-regression-model-9gg3.onrender.com
const String _baseUrl = 'https://linear-regression-model-a55j.onrender.com';

// ── Input model matching the API body exactly ─────────────────────────────────
class StudentInput {
  final int age;
  final String gender;           // "male" | "female"
  final double studyTimeWeekly;  // 0.0 – 20.0
  final int absences;            // 0 – 30
  final String tutoring;         // "yes" | "no"
  final String extracurricular;  // "yes" | "no"
  final String sports;           // "yes" | "no"
  final String music;            // "yes" | "no"
  final String volunteering;     // "yes" | "no"
  final String ethnicity;        // "caucasian" | "african american" | "asian" | "other"
  final String parentalEducation;// "none" | "high school" | "some college" | "bachelors" | "higher"
  final String parentalSupport;  // "none" | "low" | "moderate" | "high" | "very high"

  const StudentInput({
    required this.age,
    required this.gender,
    required this.studyTimeWeekly,
    required this.absences,
    required this.tutoring,
    required this.extracurricular,
    required this.sports,
    required this.music,
    required this.volunteering,
    required this.ethnicity,
    required this.parentalEducation,
    required this.parentalSupport,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'study_time_weekly': studyTimeWeekly,
        'absences': absences,
        'tutoring': tutoring,
        'extracurricular': extracurricular,
        'sports': sports,
        'music': music,
        'volunteering': volunteering,
        'ethnicity': ethnicity,
        'parental_education': parentalEducation,
        'parental_support': parentalSupport,
      };
}

// ── Service ───────────────────────────────────────────────────────────────────
class PredictionService {
  PredictionService._();
  static final instance = PredictionService._();

  Future<double> predict(StudentInput input) async {
    final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(input.toJson()),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw Exception('Cannot reach the server. Check your connection.\n$e');
    }

    // Guard: make sure response is JSON before decoding
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server returned an unexpected response (HTTP ${response.statusCode}).\n'
        'Make sure the API is running and the URL is correct.',
      );
    }

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (body['predicted_gpa'] as num).toDouble();
    }

    // Surface FastAPI validation errors clearly
    final detail = body['detail'];
    if (detail is List) {
      final msg = detail
          .map((e) => '${e['loc']?.last}: ${e['msg']}')
          .join('\n');
      throw Exception(msg);
    }
    throw Exception(
      detail?.toString() ?? 'Prediction failed (HTTP ${response.statusCode})',
    );
  }
}
