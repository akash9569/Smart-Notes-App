import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../app_theme.dart';

// =============================================================================
// LOGIN SCREEN
// =============================================================================
class LoginScreen extends StatefulWidget {
  final void Function(String email) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _biometricAvailable = false;
  bool _rememberMe = false;
  bool _enableBiometric = true;

  String? _emailError;
  String? _passError;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _coral = Color(0xFFF08A82);

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_rebuildOnFocus);
    _passFocus.addListener(_rebuildOnFocus);
    _checkBiometric();
    _loadSavedCredentials();
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = canCheck && isSupported);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && mounted) {
      setState(() {
        _rememberMe = true;
        _emailCtrl.text = prefs.getString('saved_email') ?? '';
        _passCtrl.text = prefs.getString('saved_password') ?? '';
      });
    }
  }

  void _rebuildOnFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _clearErr() => _emailError = _passError = null;

  void _goToSignup() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (result == true) {
      _loadSavedCredentials();
    }
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _clearErr();
      final e = _emailCtrl.text.trim();
      if (e.isEmpty) {
        _emailError = 'Email is required';
        ok = false;
      } else if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(e)) {
        _emailError = 'Enter a valid email';
        ok = false;
      }
      if (_passCtrl.text.isEmpty) {
        _passError = 'Password is required';
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final prefs = await SharedPreferences.getInstance();

    final savedPass = prefs.getString('password_$email');
    if (savedPass != null && savedPass != pass) {
      setState(() {
        _passError = 'Incorrect password';
        _isLoading = false;
      });
      return;
    }

    await prefs.setString('last_user_email', email);
    await prefs.setString('password_$email', pass);

    List<String> users = prefs.getStringList('all_users') ?? [];
    if (!users.contains(email)) {
      users.add(email);
      await prefs.setStringList('all_users', users);
    }

    if (_biometricAvailable) {
      await prefs.setBool('biometric_enabled_$email', _enableBiometric);
    }

    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', pass);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }

    setState(() => _isLoading = false);
    widget.onLoginSuccess(email);
  }

  Future<void> _handleBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail =
          prefs.getString('last_user_email') ?? prefs.getString('saved_email');

      if (lastEmail == null || lastEmail.isEmpty) {
        _snack('No saved account found. Please sign in with password first.',
            err: true);
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your workspace',
        options:
            const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (ok && mounted) {
        widget.onLoginSuccess(lastEmail);
      }
    } catch (_) {
      _snack('Biometric authentication failed.', err: true);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: err ? Colors.redAccent : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(
        msg,
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // App Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: _coral,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Smart Notes',
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Login Card Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.themeTextPrimary.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue to your workspace.',
                          style: TextStyle(
                            color: context.themeTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildField(
                          label: 'EMAIL ADDRESS',
                          hint: 'name@example.com',
                          icon: Icons.alternate_email_rounded,
                          ctrl: _emailCtrl,
                          focus: _emailFocus,
                          kb: TextInputType.emailAddress,
                          error: _emailError,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'PASSWORD',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          ctrl: _passCtrl,
                          focus: _passFocus,
                          obscure: _obscurePassword,
                          error: _passError,
                          suffix: _eye(
                            _obscurePassword,
                            () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCheckbox(
                              label: 'Remember me',
                              value: _rememberMe,
                              onChanged: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                            ),
                            TextButton(
                              onPressed: () => _snack(
                                  'Password reset instructions sent to email.'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: _coral,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_biometricAvailable) ...[
                          const SizedBox(height: 12),
                          _buildCheckbox(
                            label: 'Enable Biometric Login',
                            value: _enableBiometric,
                            onChanged: () => setState(
                                () => _enableBiometric = !_enableBiometric),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _buildPrimaryButton(
                          label: 'Sign In',
                          isLoading: _isLoading,
                          onTap: _handleSubmit,
                        ),

                        if (_biometricAvailable) ...[
                          const SizedBox(height: 12),
                          _buildBiometricButton(),
                        ],

                        const SizedBox(height: 20),

                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: _goToSignup,
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: _coral,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    FocusNode? focus,
    bool obscure = false,
    Widget? suffix,
    TextInputType? kb,
    String? error,
  }) {
    final focused = focus?.hasFocus ?? false;
    final hasErr = error != null && error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.themeTextSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasErr
                  ? Colors.redAccent
                  : focused
                      ? _coral
                      : context.themeTextPrimary.withValues(alpha: 0.04),
            ),
          ),
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            obscureText: obscure,
            keyboardType: kb,
            onChanged: (_) {
              if (error != null) setState(_clearErr);
            },
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.themeTextSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: hasErr
                    ? Colors.redAccent
                    : focused
                        ? _coral
                        : context.themeTextSecondary,
              ),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        if (hasErr)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _eye(bool obscure, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18,
            color: context.themeTextSecondary,
          ),
        ),
      );

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return GestureDetector(
      onTap: onChanged,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? _coral : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value
                    ? _coral
                    : context.themeTextSecondary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: context.themeTextSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: context.themeTextPrimary.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBiometric,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: _coral,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Sign in with Biometrics',
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SIGN UP SCREEN
// =============================================================================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  static const _coral = Color(0xFFF08A82);

  @override
  void initState() {
    super.initState();
    for (final fn in [_nameFocus, _emailFocus, _passFocus, _confirmFocus]) {
      fn.addListener(_rebuildOnFocus);
    }
  }

  void _rebuildOnFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearErr() =>
      _nameError = _emailError = _passError = _confirmError = null;

  bool _validate() {
    bool ok = true;
    setState(() {
      _clearErr();
      if (_nameCtrl.text.trim().isEmpty) {
        _nameError = 'Name is required';
        ok = false;
      }
      final e = _emailCtrl.text.trim();
      if (e.isEmpty) {
        _emailError = 'Email is required';
        ok = false;
      } else if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(e)) {
        _emailError = 'Enter a valid email';
        ok = false;
      }
      if (_passCtrl.text.isEmpty) {
        _passError = 'Password is required';
        ok = false;
      } else if (_passCtrl.text.length < 6) {
        _passError = 'At least 6 characters required';
        ok = false;
      }
      if (_confirmCtrl.text != _passCtrl.text) {
        _confirmError = 'Passwords do not match';
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _handleSignup() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name_$email', name);
    await prefs.setString('password_$email', pass);
    await prefs.setString('last_user_email', email);

    List<String> users = prefs.getStringList('all_users') ?? [];
    if (!users.contains(email)) {
      users.add(email);
      await prefs.setStringList('all_users', users);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.themeTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.themeTextPrimary.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join Smart Notes and start organizing your life.',
                          style: TextStyle(
                            color: context.themeTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildField(
                          label: 'FULL NAME',
                          hint: 'Alex Morgan',
                          icon: Icons.person_outline_rounded,
                          ctrl: _nameCtrl,
                          focus: _nameFocus,
                          error: _nameError,
                        ),
                        const SizedBox(height: 14),

                        _buildField(
                          label: 'EMAIL ADDRESS',
                          hint: 'name@example.com',
                          icon: Icons.alternate_email_rounded,
                          ctrl: _emailCtrl,
                          focus: _emailFocus,
                          kb: TextInputType.emailAddress,
                          error: _emailError,
                        ),
                        const SizedBox(height: 14),

                        _buildField(
                          label: 'PASSWORD',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          ctrl: _passCtrl,
                          focus: _passFocus,
                          obscure: _obscurePassword,
                          error: _passError,
                          suffix: _eye(
                            _obscurePassword,
                            () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildField(
                          label: 'CONFIRM PASSWORD',
                          hint: '••••••••',
                          icon: Icons.lock_reset_rounded,
                          ctrl: _confirmCtrl,
                          focus: _confirmFocus,
                          obscure: _obscureConfirm,
                          error: _confirmError,
                          suffix: _eye(
                            _obscureConfirm,
                            () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _coral,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: _coral,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    FocusNode? focus,
    bool obscure = false,
    Widget? suffix,
    TextInputType? kb,
    String? error,
  }) {
    final focused = focus?.hasFocus ?? false;
    final hasErr = error != null && error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.themeTextSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasErr
                  ? Colors.redAccent
                  : focused
                      ? _coral
                      : context.themeTextPrimary.withValues(alpha: 0.04),
            ),
          ),
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            obscureText: obscure,
            keyboardType: kb,
            onChanged: (_) {
              if (error != null) setState(_clearErr);
            },
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.themeTextSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: hasErr
                    ? Colors.redAccent
                    : focused
                        ? _coral
                        : context.themeTextSecondary,
              ),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        if (hasErr)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _eye(bool obscure, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18,
            color: context.themeTextSecondary,
          ),
        ),
      );
}