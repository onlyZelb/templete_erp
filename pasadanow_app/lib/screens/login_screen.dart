import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'pending_screen.dart';
import 'commuter/commuter_home.dart';
import 'driver/driver_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;
  String? _usernameError;
  String? _passwordError;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _bgDeep        = Color(0xFF0B1B35);
  static const Color _bgCard        = Color(0xFF102245);
  static const Color _accent        = Color(0xFF3D7FD4);
  static const Color _accentLight   = Color(0xFF5B9BF0);
  static const Color _orange        = Color(0xFFE8863A);
  static const Color _errorRed      = Color(0xFFE05555);
  static const Color _textPrimary   = Color(0xFFE8EEF7);
  static const Color _textMuted     = Color(0xFF8A9BC0);
  static const Color _borderDefault = Color(0xFF1E3A6E);
  static const Color _inputBg       = Color(0xFF0D1E3D);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _usernameError = _username.text.trim().isEmpty
          ? 'Please enter your username.'
          : null;
      _passwordError =
          _password.text.isEmpty ? 'Please enter your password.' : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_username.text.trim(), _password.text);
    if (!mounted) return;
    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error!),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (auth.verifiedStatus != 'verified') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PendingScreen()));
      return;
    }
    if (auth.role == 'ROLE_DRIVER') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DriverHome()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const CommuterHome()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _buildBrandHeader(),
                  const SizedBox(height: 36),
                  Container(
                    decoration: BoxDecoration(
                      color: _bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderDefault, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Welcome Back! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to continue your journey',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: _textMuted),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              _buildFieldLabel(
                                icon: Icons.person_outline_rounded,
                                label: 'Username',
                              ),
                              const SizedBox(height: 6),
                              _buildInputField(
                                controller: _username,
                                hint: 'Enter your username',
                                prefixIcon:
                                    Icons.person_outline_rounded,
                                suffixIcon: Icons.edit_outlined,
                                hasError: _usernameError != null,
                                onChanged: (_) {
                                  if (_usernameError != null) {
                                    setState(
                                        () => _usernameError = null);
                                  }
                                },
                              ),
                              if (_usernameError != null) ...[
                                const SizedBox(height: 5),
                                _buildErrorText(_usernameError!),
                              ],
                              const SizedBox(height: 18),
                              _buildFieldLabel(
                                icon: Icons.lock_outline_rounded,
                                label: 'Password',
                              ),
                              const SizedBox(height: 6),
                              _buildPasswordField(),
                              if (_passwordError != null) ...[
                                const SizedBox(height: 5),
                                _buildErrorText(_passwordError!),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _rememberMe = !_rememberMe),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (v) => setState(
                                                () => _rememberMe =
                                                    v!),
                                            activeColor: _accent,
                                            checkColor: Colors.white,
                                            side: const BorderSide(
                                                color: _textMuted,
                                                width: 1.5),
                                            shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                4)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: _textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.vpn_key_outlined,
                                            size: 14,
                                            color: _accentLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _accentLight,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildSignInButton(auth),
                              const SizedBox(height: 20),
                              _buildOrDivider(),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSocialButton(
                                      label: 'Facebook',
                                      bgColor:
                                          const Color(0xFF1877F2),
                                      icon: Icons.facebook_rounded,
                                      iconColor: Colors.white,
                                      hasBorder: false,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSocialButton(
                                      label: 'Google',
                                      bgColor: _inputBg,
                                      icon:
                                          Icons.g_mobiledata_rounded,
                                      iconColor: _textMuted,
                                      hasBorder: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                  color: _borderDefault,
                                  thickness: 1),
                              const SizedBox(height: 16),
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: _textMuted),
                                    children: [
                                      const TextSpan(
                                          text:
                                              "Don't have an account? "),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterScreen()),
                                          ),
                                          child: const Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _accentLight,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accentLight.withOpacity(0.55),
                blurRadius: 28,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: _accent.withOpacity(0.35),
                blurRadius: 55,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentLight.withOpacity(0.5),
                width: 2.5,
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF2A5FC0), Color(0xFF0D1E3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A3A80),
                  child: const Center(
                    child: Icon(Icons.directions_bike,
                        color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                  text: 'Pasada',
                  style: TextStyle(color: _textPrimary)),
              TextSpan(
                  text: 'Now', style: TextStyle(color: _orange)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'TRICYCLE RIDE HAILING SYSTEM',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.5,
            color: _textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _textPrimary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: 0.2,
            )),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required IconData suffixIcon,
    required bool hasError,
    void Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? _errorRed : _borderDefault,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        cursorColor: _accentLight,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(prefixIcon, size: 20, color: _textMuted),
          suffixIcon: Icon(suffixIcon, size: 18, color: _textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    final hasError = _passwordError != null;
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? _errorRed : _borderDefault,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: _password,
        obscureText: _obscure,
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        cursorColor: _accentLight,
        onChanged: (_) {
          if (_passwordError != null) {
            setState(() => _passwordError = null);
          }
        },
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              size: 20, color: _textMuted),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: _textMuted,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildErrorText(String message) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 14, color: _errorRed),
        const SizedBox(width: 5),
        Text(message,
            style: const TextStyle(color: _errorRed, fontSize: 12)),
      ],
    );
  }

  Widget _buildSignInButton(AuthProvider auth) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563C8), Color(0xFF3D7FD4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: auth.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_outlined,
                      size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: _borderDefault, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 10,
              color: _textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: _borderDefault, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required bool hasBorder,
  }) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        side: BorderSide(
          color: hasBorder ? _borderDefault : Colors.transparent,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}