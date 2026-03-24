import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/prediction_service.dart';

// ── Colours ───────────────────────────────────────────────────────────────────
const _purpleStart = Color(0xFF7B2FE0);
const _purpleEnd   = Color(0xFF4A90D9);
const _bgColor     = Color(0xFFF2F4F8);
const _cardColor   = Colors.white;
const _titleColor  = Color(0xFF1A1A2E);
const _subColor    = Color(0xFF888899);
const _labelColor  = Color(0xFF999AAA);

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});
  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Text controllers ──────────────────────────────────────────────────────
  final _ageCtrl       = TextEditingController();
  final _studyTimeCtrl = TextEditingController();
  final _absencesCtrl  = TextEditingController();

  // ── Popup selector state ──────────────────────────────────────────────────
  String _gender            = 'male';
  String _tutoring          = 'no';
  String _extracurricular   = 'no';
  String _sports            = 'no';
  String _music             = 'no';
  String _volunteering      = 'no';
  String _ethnicity         = 'caucasian';
  String _parentalEducation = 'none';
  String _parentalSupport   = 'none';

  bool _loading = false;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _studyTimeCtrl.dispose();
    _absencesCtrl.dispose();
    super.dispose();
  }

  // ── Show a bottom-sheet picker and return the chosen value ────────────────
  Future<void> _showPicker({
    required String title,
    required Map<String, String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: title,
        options: options,
        current: current,
        onSelected: (val) {
          onSelected(val);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Validate form then call API, show result popup ─────────────────────────
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final input = StudentInput(
      age:               int.parse(_ageCtrl.text.trim()),
      gender:            _gender,
      studyTimeWeekly:   double.parse(_studyTimeCtrl.text.trim()),
      absences:          int.parse(_absencesCtrl.text.trim()),
      tutoring:          _tutoring,
      extracurricular:   _extracurricular,
      sports:            _sports,
      music:             _music,
      volunteering:      _volunteering,
      ethnicity:         _ethnicity,
      parentalEducation: _parentalEducation,
      parentalSupport:   _parentalSupport,
    );

    try {
      final gpa = await PredictionService.instance.predict(input);
      setState(() => _loading = false);
      if (mounted) _showResultPopup(gpa);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showErrorPopup(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Result popup ──────────────────────────────────────────────────────────
  void _showResultPopup(double gpa) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9B59F5), Color(0xFF4A8FD4)],
            ),
            boxShadow: [
              BoxShadow(
                color: _purpleStart.withAlpha(100),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, color: Colors.white70, size: 40),
              const SizedBox(height: 16),
              Text(
                'PREDICTED GPA',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                gpa.toStringAsFixed(2),
                style: GoogleFonts.sora(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                'out of 4.0',
                style: GoogleFonts.sora(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              // GPA label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _gpaLabel(gpa),
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Center(
                    child: Text(
                      'Close',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _gpaLabel(double gpa) {
    if (gpa >= 3.7) return 'Excellent';
    if (gpa >= 3.0) return 'Good';
    if (gpa >= 2.0) return 'Average';
    return 'Needs Improvement';
  }

  // ── Error popup ───────────────────────────────────────────────────────────
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935)),
            const SizedBox(width: 8),
            Text('Error', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: GoogleFonts.sora(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.sora(
                    color: _purpleStart, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAvatar(),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 28),

                // ── Student Details ──────────────────────────────────────
                _buildSectionLabel('STUDENT DETAILS'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _ageCtrl,
                  label: 'Age',
                  hint: '15 – 18',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Enter a number';
                    if (n < 15 || n > 18) return 'Age must be 15–18';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Gender',
                  icon: Icons.person_outline,
                  current: _gender,
                  display: _gender == 'male' ? 'Male' : 'Female',
                  onTap: () => _showPicker(
                    title: 'Select Gender',
                    options: const {'male': 'Male', 'female': 'Female'},
                    current: _gender,
                    onSelected: (v) => setState(() => _gender = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _studyTimeCtrl,
                  label: 'Weekly Study Hours',
                  hint: '0.0 – 20.0',
                  icon: Icons.menu_book_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null) return 'Enter a number';
                    if (n < 0 || n > 20) return 'Must be 0–20 hours';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _absencesCtrl,
                  label: 'Number of Absences',
                  hint: '0 – 30',
                  icon: Icons.event_busy_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Enter a number';
                    if (n < 0 || n > 30) return 'Must be 0–30';
                    return null;
                  },
                ),

                // ── Activities ───────────────────────────────────────────
                const SizedBox(height: 20),
                _buildSectionLabel('ACTIVITIES'),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Tutoring',
                  icon: Icons.school_outlined,
                  current: _tutoring,
                  display: _tutoring == 'yes' ? 'Yes' : 'No',
                  onTap: () => _showPicker(
                    title: 'Tutoring',
                    options: const {'no': 'No', 'yes': 'Yes'},
                    current: _tutoring,
                    onSelected: (v) => setState(() => _tutoring = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Extracurricular',
                  icon: Icons.groups_outlined,
                  current: _extracurricular,
                  display: _extracurricular == 'yes' ? 'Yes' : 'No',
                  onTap: () => _showPicker(
                    title: 'Extracurricular Activities',
                    options: const {'no': 'No', 'yes': 'Yes'},
                    current: _extracurricular,
                    onSelected: (v) => setState(() => _extracurricular = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Sports',
                  icon: Icons.sports_soccer_outlined,
                  current: _sports,
                  display: _sports == 'yes' ? 'Yes' : 'No',
                  onTap: () => _showPicker(
                    title: 'Sports',
                    options: const {'no': 'No', 'yes': 'Yes'},
                    current: _sports,
                    onSelected: (v) => setState(() => _sports = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Music',
                  icon: Icons.music_note_outlined,
                  current: _music,
                  display: _music == 'yes' ? 'Yes' : 'No',
                  onTap: () => _showPicker(
                    title: 'Music',
                    options: const {'no': 'No', 'yes': 'Yes'},
                    current: _music,
                    onSelected: (v) => setState(() => _music = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Volunteering',
                  icon: Icons.volunteer_activism_outlined,
                  current: _volunteering,
                  display: _volunteering == 'yes' ? 'Yes' : 'No',
                  onTap: () => _showPicker(
                    title: 'Volunteering',
                    options: const {'no': 'No', 'yes': 'Yes'},
                    current: _volunteering,
                    onSelected: (v) => setState(() => _volunteering = v),
                  ),
                ),

                // ── Background ───────────────────────────────────────────
                const SizedBox(height: 20),
                _buildSectionLabel('BACKGROUND'),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Ethnicity',
                  icon: Icons.diversity_3_outlined,
                  current: _ethnicity,
                  display: _ethnicityDisplay(_ethnicity),
                  onTap: () => _showPicker(
                    title: 'Select Ethnicity',
                    options: const {
                      'caucasian':        'Caucasian',
                      'african american': 'African American',
                      'asian':            'Asian',
                      'other':            'Other',
                    },
                    current: _ethnicity,
                    onSelected: (v) => setState(() => _ethnicity = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Parental Education',
                  icon: Icons.family_restroom_outlined,
                  current: _parentalEducation,
                  display: _eduDisplay(_parentalEducation),
                  onTap: () => _showPicker(
                    title: 'Parental Education Level',
                    options: const {
                      'none':         'None',
                      'high school':  'High School',
                      'some college': 'Some College',
                      'bachelors':    "Bachelor's",
                      'higher':       'Higher',
                    },
                    current: _parentalEducation,
                    onSelected: (v) => setState(() => _parentalEducation = v),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPopupSelector(
                  label: 'Parental Support',
                  icon: Icons.support_outlined,
                  current: _parentalSupport,
                  display: _supDisplay(_parentalSupport),
                  onTap: () => _showPicker(
                    title: 'Parental Support Level',
                    options: const {
                      'none':      'None',
                      'low':       'Low',
                      'moderate':  'Moderate',
                      'high':      'High',
                      'very high': 'Very High',
                    },
                    current: _parentalSupport,
                    onSelected: (v) => setState(() => _parentalSupport = v),
                  ),
                ),

                const SizedBox(height: 32),
                _buildPredictButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Display helpers ───────────────────────────────────────────────────────
  String _ethnicityDisplay(String v) => const {
    'caucasian':        'Caucasian',
    'african american': 'African American',
    'asian':            'Asian',
    'other':            'Other',
  }[v] ?? v;

  String _eduDisplay(String v) => const {
    'none':         'None',
    'high school':  'High School',
    'some college': 'Some College',
    'bachelors':    "Bachelor's",
    'higher':       'Higher',
  }[v] ?? v;

  String _supDisplay(String v) => const {
    'none':      'None',
    'low':       'Low',
    'moderate':  'Moderate',
    'high':      'High',
    'very high': 'Very High',
  }[v] ?? v;

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9B59F5),
              Color(0xFF6A3DE8),
              Color(0xFF4A8FD4),
              Color(0xFF5BC8E8),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _purpleStart.withAlpha(89),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.school, color: Colors.white, size: 44),
            Positioned(
              top: 20, right: 20,
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
            Positioned(
              bottom: 22, left: 24,
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white70, size: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Student GPA Predictor',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _titleColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in the details below to predict your GPA',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
              fontSize: 13, color: _subColor, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _labelColor,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.sora(fontSize: 15, color: _titleColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF6A6A8A), size: 22),
          labelStyle: GoogleFonts.sora(color: _subColor, fontSize: 14),
          hintStyle: GoogleFonts.sora(color: _labelColor, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  // ── Popup selector tile ───────────────────────────────────────────────────
  Widget _buildPopupSelector({
    required String label,
    required IconData icon,
    required String current,
    required String display,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6A6A8A), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sora(
                        fontSize: 12, color: _subColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: _subColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictButton() {
    return GestureDetector(
      onTap: _loading ? null : _predict,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [_purpleStart, _purpleEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _purpleStart.withAlpha(89),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Predict',
                  style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Bottom-sheet picker widget ────────────────────────────────────────────────
class _PickerSheet extends StatelessWidget {
  final String title;
  final Map<String, String> options;
  final String current;
  final ValueChanged<String> onSelected;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 16),
          ...options.entries.map((e) {
            final isSelected = e.key == current;
            return GestureDetector(
              onTap: () => onSelected(e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _purpleStart.withAlpha(20)
                      : const Color(0xFFF6F6FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _purpleStart : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? _purpleStart : _titleColor,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: _purpleStart, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
