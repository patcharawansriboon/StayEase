import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tenant_auth_service.dart';
import '../widgets/sign_up_background.dart';

import '../widgets/app_sizes.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TenantGoogleSignupScreen
//
//  Flow:
//   Step 1 → กด "ดำเนินการต่อด้วย Google" → Google OAuth
//   Step 2 → กรอกข้อมูลเพิ่มเติม (ชื่อ, เบอร์, รหัสหอพัก)
//   Submit → ตรวจสอบรหัสหอพัก → สร้าง dormitory_members(pending)
//          → onRequestSent()
// ─────────────────────────────────────────────────────────────────────────────
class TenantGoogleSignupScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRequestSent; // → pending_approval
  final VoidCallback onNavigateToSignIn;

  const TenantGoogleSignupScreen({
    super.key,
    required this.onBack,
    required this.onRequestSent,
    required this.onNavigateToSignIn,
  });

  @override
  State<TenantGoogleSignupScreen> createState() =>
      _TenantGoogleSignupScreenState();
}

class _TenantGoogleSignupScreenState extends State<TenantGoogleSignupScreen> {
  final _service = TenantAuthService();

  // Step 1 = แสดงปุ่ม Google / Step 2 = กรอกข้อมูลเพิ่มเติม
  bool _googleDone = false;
  bool _isLoading = false;

  // ข้อมูลจาก Google
  String _googleName = '';
  String _googleEmail = '';
  String _googleAvatar = '';

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dormCodeController = TextEditingController();

  // Error states
  String? _phoneError;
  String? _dormCodeError;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dormCodeController.dispose();
    super.dispose();
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    final user = await _service.signInWithGoogle();

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _generalError = 'ไม่สามารถเข้าสู่ระบบด้วย Google ได้ กรุณาลองอีกครั้ง';
      });
      return;
    }

    // ดึงข้อมูลจาก Google / auth metadata
    final meta = user.userMetadata ?? {};
    final googleName = meta['full_name'] ?? meta['name'] ?? '';
    final googleEmail = user.email ?? '';
    final googleAvatar = meta['avatar_url'] ?? meta['picture'] ?? '';

    // ตรวจสอบว่ามี profile + dormitory_members แล้วหรือยัง (กรณี login ซ้ำ)
    final status = await _service.checkTenantMemberStatus();
    if (!mounted) return;

    if (status == 'approved' || status == 'pending') {
      // มี request อยู่แล้ว → ส่งกลับไปตรวจสถานะ
      widget.onRequestSent();
      return;
    }

    setState(() {
      _isLoading = false;
      _googleDone = true;
      _googleName = googleName;
      _googleEmail = googleEmail;
      _googleAvatar = googleAvatar;
      _nameController.text = googleName;
    });
  }

  // ── Submit form ───────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    // validate
    setState(() {
      _phoneError = null;
      _dormCodeError = null;
      _generalError = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final dormCode = _dormCodeController.text.trim();

    bool hasError = false;

    if (name.isEmpty) {
      setState(() => _generalError = 'กรุณากรอกชื่อ-นามสกุล');
      hasError = true;
    }
    if (phone.length != 10) {
      setState(() => _phoneError = 'กรุณากรอกเบอร์โทรศัพท์ให้ครบ 10 หลัก');
      hasError = true;
    }
    if (dormCode.isEmpty) {
      setState(() => _dormCodeError = 'กรุณากรอกรหัสหอพัก');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    // ตรวจสอบรหัสหอพัก
    final dorm = await _service.validateDormCode(dormCode);
    if (!mounted) return;

    if (dorm == null) {
      setState(() {
        _isLoading = false;
        _dormCodeError = 'ไม่พบรหัสหอพัก "$dormCode" กรุณาตรวจสอบอีกครั้ง';
      });
      return;
    }

    // สร้าง tenant request
    final success = await _service.submitTenantRequest(
      fullName: name,
      phone: phone,
      dormitoryId: dorm['id'] as String,
      avatarUrl: _googleAvatar.isNotEmpty ? _googleAvatar : null,
    );
    if (!mounted) return;

    if (!success) {
      setState(() {
        _isLoading = false;
        _generalError = 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง';
      });
      return;
    }

    widget.onRequestSent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SignUpBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // รูปหดตามพื้นที่ที่เหลือ (แป้นพิมพ์ขึ้นแล้วพื้นที่แคบ รูปจะเล็กลง/หายไป ฟอร์มได้พื้นที่ก่อน)
            final imageScale = ((constraints.maxHeight - 60 - 380) / 180)
                .clamp(0.0, 1.0)
                .toDouble();
            return Column(
              children: [
                // ── Back button ──
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          size: kBackIconSize,
                          color: Color(0xFF1A1A2E),
                        ),
                        onPressed: _isLoading ? null : widget.onBack,
                      ),
                    ),
                  ),
                ),

                // ── Illustration ──
                if (imageScale > 0.02)
                  Align(
                    alignment: Alignment.centerRight, // ชิดขวา
                    // ครอปพื้นที่ขาวด้านล่างของรูปออก เพื่อให้การ์ดสีฟ้าอยู่ใกล้รูป
                    child: SizedBox(
                      width: 250 * imageScale,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.8,
                          child: Image.asset(
                            'assets/images/sign_up2.png',
                            height: 225 * imageScale,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),

                // ── Blue form panel ──
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ), // เว้นระยะจากขอบจอ
                    clipBehavior: Clip
                        .antiAlias, // ตัดเนื้อหาที่เลื่อนให้อยู่ในรูปทรง card
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4F8FDB),
                            ),
                          )
                        : _googleDone
                        ? _buildFormStep()
                        : _buildGoogleStep(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Step 1: ปุ่ม Google ───────────────────────────────────────────────────
  Widget _buildGoogleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 32, 12, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สมัครใช้งาน\nสำหรับผู้เช่า',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'เข้าสู่ระบบด้วยบัญชี Google ของคุณ\nเพื่อสมัครเข้าหอพัก',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Google button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A2E),
                elevation: 2,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google logo (G icon)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const _GoogleLogo(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ดำเนินการต่อด้วย Google',
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_generalError != null) ...[
            const SizedBox(height: 16),
            _buildErrorBox(_generalError!),
          ],

          const SizedBox(height: 32),

          // Link to sign in
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'มีบัญชีอยู่แล้ว?  ',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 14,
                  color: Color(0xFF000000),
                ),
              ),
              GestureDetector(
                onTap: widget.onNavigateToSignIn,
                child: const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4181CB),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF4181CB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: กรอกข้อมูลเพิ่มเติม ──────────────────────────────────────────
  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 28, 12, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google profile badge
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4F8FDB),
                backgroundImage: _googleAvatar.isNotEmpty
                    ? NetworkImage(_googleAvatar)
                    : null,
                child: _googleAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _googleEmail,
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Color(0xFF555555),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'เชื่อมต่อกับ Google แล้ว ✓',
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // General error
          if (_generalError != null) ...[
            _buildErrorBox(_generalError!),
            const SizedBox(height: 12),
          ],

          // หัวข้อ
          const Text(
            'สมัครสมาชิก',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A3282),
            ),
          ),
          const SizedBox(height: 16),

          // ชื่อ-นามสกุล
          _buildLabel('ชื่อ-นามสกุล'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'กรุณากรอกชื่อ-นามสกุล',
          ),
          const SizedBox(height: 16),

          // เบอร์โทรศัพท์
          _buildLabelWithError('เบอร์โทรศัพท์', _phoneError),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: 'กรุณากรอกเบอร์โทรศัพท์',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            hasError: _phoneError != null,
            onChanged: (_) => setState(() => _phoneError = null),
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 4),
            Text(
              _phoneError!,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 11,
                color: Color(0xFFFF0303),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // รหัสหอพัก
          _buildLabelWithError('รหัสหอพัก', _dormCodeError),
          const SizedBox(height: 4),
          const Text(
            'ตัวอย่าง: SE-2569-001',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _dormCodeController,
            hint: 'กรุณากรอกรหัสหอพัก เช่น SE-2569-001',
            hasError: _dormCodeError != null,
            onChanged: (_) => setState(() => _dormCodeError = null),
            textCapitalization: TextCapitalization.characters,
          ),
          if (_dormCodeError != null) ...[
            const SizedBox(height: 4),
            Text(
              _dormCodeError!,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 11,
                color: Color(0xFFFF0303),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // ปุ่มสมัคร
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B93D4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'สมัครใช้งาน',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildLabelWithError(String label, String? error) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Noto Sans Thai',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A2E),
          ),
        ),
        if (error != null) ...[
          const SizedBox(width: 8),
          Text(
            '• กรุณากรอกให้ถูกต้อง',
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 11,
              color: Color(0xFFFF0303),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool hasError = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontFamily: 'Noto Sans Thai',
        fontSize: 14,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 13,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF0303) : const Color(0xFFD9D9D9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF0303) : const Color(0xFFD9D9D9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFFF0303) : const Color(0xFF4F8FDB),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9090)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE05C5C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFFCC0000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google G Logo (painted) ───────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    // Draw simplified "G" letter
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
