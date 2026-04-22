import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  String _role = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _authService = AuthService();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPwd = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _licenseNo = TextEditingController();
  final _plateNo = TextEditingController();
  final _todaNo = TextEditingController();

  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _agreedTerms = false;
  bool _loading = false;

  File? _profilePhoto;
  File? _licensePhoto;
  File? _vehiclePhoto;
  File? _todaClearancePhoto;

  final ImagePicker _picker = ImagePicker();

  static const Color _bgDeep = Color(0xFF0B1B35);
  static const Color _bgCard = Color(0xFF102245);
  static const Color _inputBg = Color(0xFF0D1E3D);
  static const Color _accent = Color(0xFF3D7FD4);
  static const Color _accentLight = Color(0xFF5B9BF0);
  static const Color _orange = Color(0xFFE8863A);
  static const Color _green = Color(0xFF22C55E);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFE8EEF7);
  static const Color _textMuted = Color(0xFF8A9BC0);
  static const Color _border = Color(0xFF1E3A6E);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in [
      _username,
      _password,
      _confirmPwd,
      _fullName,
      _phone,
      _email,
      _address,
      _licenseNo,
      _plateNo,
      _todaNo
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToForm(String role) {
    setState(() {
      _role = role;
      _page = role == 'commuter' ? 1 : 2;
    });
    _animController
      ..reset()
      ..forward();
  }

  void _backToRoles() {
    setState(() => _page = 0);
    _animController
      ..reset()
      ..forward();
  }

  Future<void> _pickImage({required _ImageSlot slot}) async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      switch (slot) {
        case _ImageSlot.profile:
          _profilePhoto = File(picked.path);
          break;
        case _ImageSlot.license:
          _licensePhoto = File(picked.path);
          break;
        case _ImageSlot.vehicle:
          _vehiclePhoto = File(picked.path);
          break;
        case _ImageSlot.todaClearance:
          _todaClearancePhoto = File(picked.path);
          break;
      }
    });
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('📷  Choose Image Source',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('📸', style: TextStyle(fontSize: 22)),
              ),
              title: const Text('Take Photo',
                  style: TextStyle(color: _textPrimary, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🖼️', style: TextStyle(fontSize: 22)),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: _textPrimary, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_agreedTerms) {
      _showSnack('Please agree to the Terms & Conditions.', _errorRed);
      return;
    }
    if (_password.text != _confirmPwd.text) {
      _showSnack('Passwords do not match.', _errorRed);
      return;
    }

    if (_role == 'driver') {
      if (_licensePhoto == null) {
        _showSnack(
            "Please upload a photo of your Driver's License.", _errorRed);
        return;
      }
      if (_vehiclePhoto == null) {
        _showSnack('Please upload a photo of your Vehicle / Plate.', _errorRed);
        return;
      }
      if (_todaClearancePhoto == null) {
        _showSnack('Please upload your TODA Clearance photo.', _errorRed);
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final data = {
        'username': _username.text.trim(),
        'password': _password.text,
        'fullName': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'role': _role,
        if (_role == 'driver') ...{
          'licenseNo': _licenseNo.text.trim(),
          'plateNo': _plateNo.text.trim(),
          'todaNo': _todaNo.text.trim(),
          'address': _address.text.trim(),
        }
      };
      await _authService.register(data);
      if (!mounted) return;
      _showSnack('✅ Registered! Awaiting admin verification.', _green);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (_) {
      _showSnack('❌ Registration failed. Try again.', _errorRed);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _page == 0
                ? _buildRoleSelection()
                : _page == 1
                    ? _buildCommuterForm()
                    : _buildDriverForm(),
          ),
        ),
      ),
    );
  }

  // ── PAGE 0 — Role Selection ───────────────────────────────────────────────
  Widget _buildRoleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildBrand(),
          const SizedBox(height: 40),
          const Text('Create Account 🎉',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Who are you registering as?',
              style: TextStyle(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: _roleCard(
                emoji: '👤',
                iconBg: _accent.withOpacity(0.15),
                emojiSize: 32,
                label: 'Commuter',
                desc: 'Book tricycle rides around the city',
                role: 'commuter',
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _roleCard(
                emoji: '🛺',
                iconBg: _orange.withOpacity(0.15),
                emojiSize: 32,
                label: 'Driver',
                desc: 'Register your tricycle & earn',
                role: 'driver',
                highlighted: true,
              )),
            ],
          ),
          const SizedBox(height: 40),
          _buildSignInFooter(),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String emoji,
    required Color iconBg,
    required double emojiSize,
    required String label,
    required String desc,
    required String role,
    bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: () => _goToForm(role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFF162B50) : _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted ? _orange.withOpacity(0.5) : _border,
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                      color: _orange.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
              ),
            ),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textMuted, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }

  // ── PAGE 1 — Commuter Form ────────────────────────────────────────────────
  Widget _buildCommuterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBackLink(),
          const SizedBox(height: 16),
          _buildBrand(),
          const SizedBox(height: 12),
          Center(child: _roleBadge('👤  COMMUTER', _accent)),
          const SizedBox(height: 16),
          const Text('Create Account 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Join PasadaNow and ride today! 🛺',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _sectionDivider('🔐  ACCOUNT INFO'),
          const SizedBox(height: 14),
          _field(
            controller: _username,
            label: '✏️  Username *',
            hint: 'Choose a username',
            suffixEmoji: '🙍',
          ),
          const SizedBox(height: 14),
          _sectionDivider('👤  PERSONAL INFO'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _field(
                    controller: _fullName,
                    label: '🙎  Full Name',
                    hint: 'Full name')),
            const SizedBox(width: 12),
            Expanded(
                child: _field(
                    controller: _phone,
                    label: '📞  Phone Number',
                    hint: '09xx-xxx-xxxx',
                    keyboardType: TextInputType.phone)),
          ]),
          const SizedBox(height: 14),
          _field(
              controller: _email,
              label: '📧  Email Address',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              suffixEmoji: '✉️'),
          const SizedBox(height: 20),
          _sectionDivider('🔒  ACCOUNT SECURITY'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _passwordField(
                    controller: _password,
                    label: '🔑  Password',
                    hint: 'Password',
                    obscure: _obscurePwd,
                    onToggle: () =>
                        setState(() => _obscurePwd = !_obscurePwd))),
            const SizedBox(width: 12),
            Expanded(
                child: _passwordField(
                    controller: _confirmPwd,
                    label: '✅  Confirm Password',
                    hint: 'Confirm',
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm))),
          ]),
          const SizedBox(height: 16),
          _termsCheckbox(),
          const SizedBox(height: 20),
          _buildSubmitButton('🚀  Create Commuter Account', _accent),
          const SizedBox(height: 16),
          _buildSignInFooter(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── PAGE 2 — Driver Form ──────────────────────────────────────────────────
  Widget _buildDriverForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBackLink(),
          const SizedBox(height: 16),
          _buildBrand(),
          const SizedBox(height: 12),
          Center(child: _roleBadge('🛺  DRIVER', _orange)),
          const SizedBox(height: 16),
          const Text('Create Driver Account 🛺',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Register to start accepting rides on PasadaNow!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _sectionDivider('🔐  ACCOUNT INFO'),
          const SizedBox(height: 14),
          _field(
            controller: _username,
            label: '✏️  Username *',
            hint: 'Choose a username',
            suffixEmoji: '🙍',
          ),
          const SizedBox(height: 20),
          _sectionDivider('👤  PERSONAL INFO'),
          const SizedBox(height: 14),
          _buildProfilePhotoUpload(),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _field(
                    controller: _fullName,
                    label: '🙎  Full Name *',
                    hint: 'Juan dela Cruz')),
            const SizedBox(width: 12),
            Expanded(
                child: _field(
                    controller: _phone,
                    label: '📞  Contact Number *',
                    hint: '09xx-xxx-xxxx',
                    keyboardType: TextInputType.phone)),
          ]),
          const SizedBox(height: 14),
          _field(
              controller: _email,
              label: '📧  Email Address *',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _field(
              controller: _address,
              label: '📍  Home Address',
              hint: 'Barangay, City, Province'),
          const SizedBox(height: 20),
          _sectionDivider('🚗  VEHICLE & LICENSE'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _field(
                    controller: _plateNo,
                    label: '🪪  Plate Number *',
                    hint: 'E.G. ABC 1234')),
            const SizedBox(width: 12),
            Expanded(
                child: _field(
                    controller: _licenseNo,
                    label: "📋  Driver's License No. *",
                    hint: 'e.g. N01-23-456789')),
          ]),
          const SizedBox(height: 14),
          _field(
              controller: _todaNo,
              label: '🏢  Branch / TODA / Party',
              hint: 'e.g. Center TODA, Session Road Terminal'),
          const SizedBox(height: 20),
          _sectionDivider('📄  CREDENTIAL DOCUMENTS'),
          const SizedBox(height: 6),
          _buildCredentialNote(),
          const SizedBox(height: 14),
          _buildCredentialUpload(
            slot: _ImageSlot.license,
            file: _licensePhoto,
            emoji: '🪪',
            label: "Driver's License Photo",
            sublabel: 'Front side clearly visible',
            required: true,
          ),
          const SizedBox(height: 12),
          _buildCredentialUpload(
            slot: _ImageSlot.vehicle,
            file: _vehiclePhoto,
            emoji: '🛺',
            label: 'Vehicle / Plate Photo',
            sublabel: 'Plate number must be readable',
            required: true,
          ),
          const SizedBox(height: 12),
          _buildCredentialUpload(
            slot: _ImageSlot.todaClearance,
            file: _todaClearancePhoto,
            emoji: '📄',
            label: 'TODA Clearance',
            sublabel: 'Official TODA or franchise document',
            required: true,
          ),
          const SizedBox(height: 20),
          _sectionDivider('🔒  ACCOUNT SECURITY'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _passwordField(
                    controller: _password,
                    label: '🔑  Password *',
                    hint: 'Password',
                    obscure: _obscurePwd,
                    onToggle: () =>
                        setState(() => _obscurePwd = !_obscurePwd))),
            const SizedBox(width: 12),
            Expanded(
                child: _passwordField(
                    controller: _confirmPwd,
                    label: '✅  Confirm Password *',
                    hint: 'Confirm',
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm))),
          ]),
          const SizedBox(height: 16),
          _termsCheckbox(),
          const SizedBox(height: 20),
          _buildSubmitButton('🛺  Create Driver Account', _orange),
          const SizedBox(height: 16),
          _buildSignInFooter(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── SHARED WIDGETS ─────────────────────────────────────────────────────────

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFF2A5FC0), Color(0xFF1A3A80)]),
            boxShadow: [
              BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const Center(
            child: Text('🛺', style: TextStyle(fontSize: 26)),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            children: [
              TextSpan(text: 'Pasada', style: TextStyle(color: _textPrimary)),
              TextSpan(text: 'Now', style: TextStyle(color: _orange)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('TRICYCLE RIDE HAILING SYSTEM',
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 2.5,
                color: _textMuted,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: _backToRoles,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('◀️', style: TextStyle(fontSize: 14)),
          SizedBox(width: 6),
          Text('Back to role selection',
              style: TextStyle(color: _textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionDivider(String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: _border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: const TextStyle(
                  color: _textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: _border, thickness: 1)),
      ],
    );
  }

  Widget _buildCredentialNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _orange.withOpacity(0.25), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 15)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'All credential photos are required for admin verification. '
              'Ensure images are clear and legible before uploading.',
              style: TextStyle(color: _orange, fontSize: 11.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialUpload({
    required _ImageSlot slot,
    required File? file,
    required String emoji,
    required String label,
    required String sublabel,
    bool required = false,
  }) {
    final bool hasFile = file != null;

    return GestureDetector(
      onTap: () => _pickImage(slot: slot),
      child: Container(
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? _green.withOpacity(0.5) : _border,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(11)),
              child: hasFile
                  ? Image.file(file, width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                      width: 80,
                      height: 80,
                      color: _orange.withOpacity(0.08),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 30)),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (required)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _errorRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Required',
                              style: TextStyle(
                                  color: _errorRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(sublabel,
                      style: const TextStyle(color: _textMuted, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        hasFile ? '✅' : '⬆️',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasFile
                            ? 'Uploaded — tap to change'
                            : 'Tap to upload photo',
                        style: TextStyle(
                          color: hasFile ? _green : _accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? suffixEmoji,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _textPrimary, fontSize: 13),
            cursorColor: _accentLight,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
              suffixIcon: suffixEmoji != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(suffixEmoji,
                          style: const TextStyle(fontSize: 16)),
                    )
                  : null,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 44, minHeight: 44),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border, width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: _textPrimary, fontSize: 13),
            cursorColor: _accentLight,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    obscure ? '🙈' : '👁️',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 44, minHeight: 44),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
                color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: '🖼️  Profile Photo '),
              TextSpan(
                  text: '(optional)',
                  style: TextStyle(
                      color: _textMuted, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(slot: _ImageSlot.profile),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _profilePhoto != null ? _green.withOpacity(0.5) : _border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: _profilePhoto != null
                      ? ClipOval(
                          child: Image.file(_profilePhoto!,
                              width: 44, height: 44, fit: BoxFit.cover))
                      : const Center(
                          child: Text('🤳', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profilePhoto != null
                          ? '✅ Photo uploaded — tap to change'
                          : '⬆️  Upload Profile Photo',
                      style: TextStyle(
                          color: _profilePhoto != null ? _green : _textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    const Text('JPG, PNG or WEBP · Max 3 MB',
                        style: TextStyle(color: _textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _termsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedTerms = !_agreedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _agreedTerms,
              onChanged: (v) => setState(() => _agreedTerms = v!),
              activeColor: _accent,
              checkColor: Colors.white,
              side: const BorderSide(color: _textMuted, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: _textPrimary),
              children: [
                const TextSpan(text: '📜  I agree to the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Terms & Conditions',
                        style: TextStyle(
                            color: _accentLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(String label, Color color) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSignInFooter() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: _textMuted),
          children: [
            const TextSpan(text: 'Already have an account? '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('🔑  Sign in',
                    style: TextStyle(
                        color: _accentLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImageSlot { profile, license, vehicle, todaClearance }
