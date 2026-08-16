import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _float;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _coral = Color(0xFFF08A82);
  static const _blue = Color(0xFF93C5FD);
  static const _green = Color(0xFF86EFAC);
  static const _yellow = Color(0xFFFDE047);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark ||
        appThemeNotifier.value == ThemeMode.dark;

    final bg = isDark ? const Color(0xFF121316) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E1F24) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Floating Showcase Zone ──
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back card: Calendar / Timeline
                    _FloatingCard(
                      ctrl: _float,
                      phase: 1.0,
                      offsetX: 4,
                      offsetY: -70,
                      angle: 0.03,
                      width: 120,
                      height: 145,
                      cardBg: cardBg,
                      icon: Icons.calendar_today_rounded,
                      iconColor: _blue,
                      label: 'Timeline',
                      value: 'Today',
                    ),
                    // Left card: Habits
                    _FloatingCard(
                      ctrl: _float,
                      phase: 2.5,
                      offsetX: -100,
                      offsetY: 20,
                      angle: -0.1,
                      width: 115,
                      height: 135,
                      cardBg: cardBg,
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: _green,
                      label: 'Habits',
                      value: '100%',
                    ),
                    // Right card: Finance
                    _FloatingCard(
                      ctrl: _float,
                      phase: 4.0,
                      offsetX: 100,
                      offsetY: 25,
                      angle: 0.09,
                      width: 115,
                      height: 135,
                      cardBg: cardBg,
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: _yellow,
                      label: 'Finance',
                      value: 'Tracked',
                    ),
                    // Center card: Daily Overview (Hero)
                    _FloatingCard(
                      ctrl: _float,
                      phase: 0.0,
                      offsetX: 0,
                      offsetY: 20,
                      angle: 0,
                      width: 145,
                      height: 165,
                      cardBg: cardBg,
                      icon: Icons.auto_awesome_rounded,
                      iconColor: _coral,
                      label: 'Smart Notes',
                      value: 'Focused',
                      isFront: true,
                    ),
                    // Status tag — top left
                    Positioned(
                      top: 20,
                      left: 18,
                      child: _StatusPill(
                        color: _green,
                        text: 'ALL IN ONE',
                        cardBg: cardBg,
                        textColor: textSecondary,
                      ),
                    ),
                    // Status tag — bottom right
                    Positioned(
                      bottom: 24,
                      right: 18,
                      child: _StatusPill(
                        color: _coral,
                        text: 'STRUCTURED',
                        cardBg: cardBg,
                        textColor: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Content ──
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _coral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ALL-IN-ONE WORKSPACE',
                              style: TextStyle(
                                color: _coral,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Headline
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                          children: const [
                            TextSpan(text: 'Master your daily life, '),
                            TextSpan(
                              text: 'effortlessly.',
                              style: TextStyle(
                                color: _coral,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Clean, structured workspace for your tasks, habits, notes, journal, and finances.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _coral,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sign in link
                      Center(
                        child: GestureDetector(
                          onTap: _onGetStarted,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 13, color: textSecondary),
                              children: const [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: _coral,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating preview card ─────────────────────────────────────────────────────
class _FloatingCard extends StatelessWidget {
  final AnimationController ctrl;
  final double phase, offsetX, offsetY, angle, width, height;
  final Color cardBg, iconColor;
  final IconData icon;
  final String label, value;
  final bool isFront;

  const _FloatingCard({
    required this.ctrl,
    required this.phase,
    required this.offsetX,
    required this.offsetY,
    required this.angle,
    required this.width,
    required this.height,
    required this.cardBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    this.isFront = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final bob = math.sin((ctrl.value * math.pi * 2) + phase) * 8.0;
        return Transform.translate(
          offset: Offset(offsetX, offsetY + bob),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFront
                      ? iconColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: isFront
                    ? [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final Color color, cardBg, textColor;
  final String text;

  const _StatusPill({
    required this.color,
    required this.text,
    required this.cardBg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}