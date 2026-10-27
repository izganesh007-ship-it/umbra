// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra onboarding: 6-step flow matching onboarding.html design
// welcome → identity (mnemonic) → tor animation → handle → qr → success

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show appState, engine, buildHaloUriV3;
import '../theme/theme.dart';
import '../widgets/stagger_in.dart';
import '../widgets/umbra_avatar.dart';
import '../widgets/umbra_nav_bar.dart';
import '../widgets/eclipse_wipe.dart';
import '../l10n/l10n.dart';

class OnboardingScreen extends StatefulWidget {
  final dynamic appState; // Accept appState for compatibility
  final VoidCallback? onComplete;
  const OnboardingScreen({super.key, required this.appState, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 6;

  // Step 1: Welcome
  late final AnimationController _welcomeController;
  late final Animation<double> _welcomeAnim;

  // Step 2: Identity (mnemonic)
  late final AnimationController _identityController;
  late final Animation<double> _revealAnim;
  late final Animation<double> _breathAnim;
  String _mnemonic = '';
  bool _mnemonicRevealed = false;

  // Step 3: Tor animation
  late final AnimationController _torController;
  int _torStage = 0;
  Timer? _torTimer;
  static const _torStages = [
    ('Connecting to Tor...', 'Establishing circuits'),
    ('Handshaking...', 'Negotiating encryption'),
    ('Ready', 'Your connection is private'),
  ];

  // Step 4: Handle
  final _handleController = TextEditingController();
  Timer? _handleDebounce;
  String _handleState = ''; // '', checking, free, taken, error
  bool _handleBusy = false;

  // Step 5: QR
  String _qrData = '';

  @override
  void initState() {
    super.initState();

    // Welcome animations
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _welcomeAnim = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOutBack,
    );

    // Identity animations
    _identityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnim = CurvedAnimation(
      parent: _identityController,
      curve: Curves.easeOutCubic,
    );
    _breathAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _identityController,
        curve: Curves.easeInOut,
      ),
    );

    // Tor animation controller
    _torController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _generateMnemonic();
    _welcomeController.forward();
    _startTorAnimation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _welcomeController.dispose();
    _identityController.dispose();
    _torController.dispose();
    _handleController.dispose();
    _handleDebounce?.cancel();
    _torTimer?.cancel();
    super.dispose();
  }

  void _generateMnemonic() {
    // Generate 12-word mnemonic (simplified - in real app use BIP39)
    const words = [
      'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract',
      'absurd', 'abuse', 'access', 'accident', 'account', 'accuse', 'achieve', 'acid',
      'acoustic', 'acquire', 'across', 'act', 'action', 'actor', 'actress', 'actual',
      'adapt', 'add', 'addict', 'address', 'adjust', 'admit', 'adult', 'advance',
      'advice', 'aerobic', 'affair', 'afford', 'afraid', 'again', 'age', 'agent',
      'agree', 'ahead', 'aim', 'air', 'airport', 'aisle', 'alarm', 'album',
      'alcohol', 'alert', 'alien', 'all', 'alley', 'allow', 'almost', 'alone',
      'alpha', 'already', 'also', 'alter', 'always', 'amateur', 'amazing', 'among',
      'amount', 'amuse', 'analyst', 'anchor', 'ancient', 'anger', 'angle', 'angry',
      'animal', 'ankle', 'announce', 'annual', 'another', 'answer', 'antenna', 'antique',
      'anxiety', 'any', 'apart', 'apology', 'appear', 'apple', 'approve', 'april',
      'arch', 'arctic', 'area', 'arena', 'argue', 'arm', 'armed', 'armor',
      'army', 'around', 'arrange', 'arrest', 'arrive', 'arrow', 'art', 'artefact',
      'artist', 'artwork', 'ask', 'aspect', 'assault', 'asset', 'assist', 'assume',
      'asthma', 'athlete', 'atom', 'attack', 'attend', 'attitude', 'attract', 'auction',
      'audit', 'august', 'aunt', 'author', 'auto', 'autumn', 'average', 'avocado',
      'avoid', 'awake', 'aware', 'away', 'awesome', 'awful', 'awkward', 'axis',
    ];
    final random = math.Random.secure();
    _mnemonic = List.generate(12, (_) => words[random.nextInt(words.length)]).join(' ');
  }

  void _startTorAnimation() {
    _torStage = 0;
    _torController.repeat(reverse: true);
    _torTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _torStage = (_torStage + 1) % _torStages.length;
      });
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: UmbraMotion.durationNormal,
        curve: UmbraMotion.easeSpring,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: UmbraMotion.durationNormal,
        curve: UmbraMotion.easeSpring,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentStep = page);
    if (page == 1) {
      _identityController.forward();
    }
  }

  Future<void> _completeOnboarding() async {
    // Save mnemonic and complete onboarding
    await appState.completeOnboarding(_mnemonic);
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  // Handle checking
  void _onHandleChanged(String value) {
    _handleDebounce?.cancel();
    final h = value.trim().toLowerCase();
    if (h.isEmpty) {
      setState(() => _handleState = '');
      return;
    }
    setState(() => _handleState = 'checking');
    _handleDebounce = Timer(const UmbraMotion.durationSlower, () async {
      final r = await engine.handleCheck(h);
      if (!mounted) return;
      setState(() => _handleState = r);
    });
  }

  Future<void> _claimHandle() async {
    final h = _handleController.text.trim().toLowerCase();
    if (h.isEmpty || _handleState != 'free' || _handleBusy) return;

    setState(() => _handleBusy = true);
    final uri = await buildHaloUriV3(appState.myId, appState.myOnion, appState.fcCounter);
    final r = await engine.handleClaim(h, uri, '');
    if (!mounted) return;
    setState(() => _handleBusy = false);
    if (r == 'ok') {
      await appState.setMyHandle(h, bio: '');
      if (!mounted) return;
      _nextStep();
    } else {
      showHaloToast(context, r.replaceFirst('error: ', ''));
    }
  }

  Future<void> _generateQR() async {
    _qrData = await buildHaloUriV3(appState.myId, appState.myOnion, appState.fcCounter);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).reduceMotion;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Step indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: List.generate(_totalSteps, (i) {
                      final isActive = i == _currentStep;
                      final isComplete = i < _currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: reduceMotion ? Duration.zero : UmbraMotion.durationNormal,
                                curve: UmbraMotion.easeSpring,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isActive || isComplete
                                      ? colors.accent
                                      : colors.separator,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (i < _totalSteps - 1) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                // Page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomeStep(animation: _welcomeAnim),
                      _IdentityStep(
                        mnemonic: _mnemonic,
                        revealAnim: _revealAnim,
                        breathAnim: _breathAnim,
                        onRegenerate: _generateMnemonic,
                        onContinue: _nextStep,
                      ),
                      _TorStep(
                        stage: _torStage,
                        stages: _torStages,
                        controller: _torController,
                        onContinue: _nextStep,
                      ),
                      _HandleStep(
                        controller: _handleController,
                        state: _handleState,
                        busy: _handleBusy,
                        onChanged: _onHandleChanged,
                        onClaim: _claimHandle,
                        onSkip: _nextStep,
                      ),
                      _QRStep(
                        qrData: _qrData,
                        onGenerate: _generateQR,
                        onContinue: _nextStep,
                      ),
                      _SuccessStep(onComplete: _completeOnboarding),
                    ],
                  ),
                ),
                // Navigation
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: colors.separator),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(UmbraRadius.lg),
                              ),
                            ),
                            child: Text(
                              l10n.commonBack,
                              style: TextStyle(
                                fontFamily: UmbraTypography.fontSans,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _currentStep == 3 && _handleState != 'free' && !_handleBusy
                              ? null
                              : (_currentStep == 4 && _qrData.isEmpty ? _generateQR : _nextStep),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: colors.accent,
                            foregroundColor: colors.accentOn,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UmbraRadius.lg),
                            ),
                          ),
                          child: Text(
                            _currentStep == _totalSteps - 1
                                ? l10n.commonDone
                                : _currentStep == 3
                                    ? 'Claim Handle'
                                    : _currentStep == 4
                                        ? l10n.commonContinue
                                        : l10n.commonContinue,
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontSans,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle (top right)
          Positioned(
            top: 16,
            right: 16,
            child: _ThemeToggleButton(),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step 1: Welcome
// ──────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  final Animation<double> animation;

  const _WelcomeStep({required this.animation});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Illustration
          ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.accent.withValues(alpha: 0.2),
                      colors.accentHover.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(
                  painter: _WelcomeIllustrationPainter(colors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          FadeTransition(
            opacity: animation,
            child: Text(
              l10n.onboardingWelcomeToUmbra,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSerif,
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: colors.textPrimary,
                fontStyle: FontStyle.italic,
                height: 1.05,
                letterSpacing: -0.015,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          FadeTransition(
            opacity: animation,
            child: Text(
              l10n.onboardingPrivateMessagingForEveryone,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Features
          FadeTransition(
            opacity: animation,
            child: Column(
              children: [
                _FeatureItem(
                  icon: _lockIcon,
                  title: l10n.onboardingEndToEndEncrypted,
                  desc: l10n.onboardingOnlyYouAndRecipient,
                ),
                const SizedBox(height: 20),
                _FeatureItem(
                  icon: _torIcon,
                  title: l10n.onboardingTorByDefault,
                  desc: l10n.onboardingNoIPLeaksEver,
                ),
                const SizedBox(height: 20),
                _FeatureItem(
                  icon: _burnIcon,
                  title: l10n.onboardingDisappearingMessages,
                  desc: l10n.onboardingSetTimersPerChat,
                ),
                const SizedBox(height: 20),
                _FeatureItem(
                  icon: _noPhoneIcon,
                  title: l10n.onboardingNoPhoneNumber,
                  desc: l10n.onboardingJustAHandleOrQR,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final List<String> icon;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: StrokeIcon(icon, size: 24, color: colors.accent, stroke: 2),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final _lockIcon = ['M12 2a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h6z', 'M8 12h8', 'M8 16h8'];
final _torIcon = ['M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8z', 'M12 6v6l4 2'];
final _burnIcon = ['M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z', 'M12 6v6l4 2'];
final _noPhoneIcon = ['M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8z', 'M17 11v-2a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v2', 'M12 19V13'];

class _WelcomeIllustrationPainter extends CustomPainter {
  final Color color;

  _WelcomeIllustrationPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Draw shield shape
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + radius, center.dy - radius,
      center.dx + radius, center.dy,
    );
    path.quadraticBezierTo(
      center.dx + radius, center.dy + radius,
      center.dx, center.dy + radius * 0.8,
    );
    path.quadraticBezierTo(
      center.dx - radius, center.dy + radius,
      center.dx - radius, center.dy,
    );
    path.quadraticBezierTo(
      center.dx - radius, center.dy - radius,
      center.dx, center.dy - radius,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Inner circle
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.3, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────
// Step 2: Identity (Mnemonic)
// ──────────────────────────────────────────────────────────────

class _IdentityStep extends StatelessWidget {
  final String mnemonic;
  final Animation<double> revealAnim;
  final Animation<double> breathAnim;
  final VoidCallback onRegenerate;
  final VoidCallback onContinue;

  const _IdentityStep({
    required this.mnemonic,
    required this.revealAnim,
    required this.breathAnim,
    required this.onRegenerate,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final words = mnemonic.split(' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Title
          Text(
            l10n.onboardingYourIdentity,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSerif,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.05,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboarding12WordsAreYourKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 40),
          // Identity card
          ScaleTransition(
            scale: revealAnim,
            child: FadeTransition(
              opacity: revealAnim,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(UmbraRadius.xl),
                  border: Border.all(color: colors.separator, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: -10,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Label
                    Text(
                      l10n.onboardingYourRecoveryPhrase,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                        letterSpacing: 0.14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Words grid
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(12, (i) {
                        return AnimatedBuilder(
                          animation: breathAnim,
                          builder: (context, child) {
                            final delay = i * 0.05;
                            final animValue = (breathAnim.value - 1.0) * (1.0 - delay).clamp(0.0, 1.0) + 1.0;
                            return Transform.scale(
                              scale: animValue,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(UmbraRadius.md),
                                  border: Border.all(color: colors.separator, width: 0.5),
                                ),
                                child: Text(
                                  '${i + 1}. ${words[i]}',
                                  style: TextStyle(
                                    fontFamily: UmbraTypography.fontMono,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                    letterSpacing: 0.12,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Warning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.warningSoft,
                        borderRadius: BorderRadius.circular(UmbraRadius.md),
                        border: Border.all(color: colors.warning.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: colors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.onboardingWriteTheseDown,
                              style: TextStyle(
                                fontFamily: UmbraTypography.fontSans,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: colors.textPrimary,
                                height: 1.5,
                                letterSpacing: 0,
                              ),
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
          const SizedBox(height: 32),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRegenerate,
                  icon: StrokeIcon(['M12 4v16', 'M8 8l4 4 4-4'], size: 18, color: colors.textSecondary, stroke: 1.8),
                  label: Text(
                    l10n.onboardingRegenerate,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colors.separator),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onContinue,
                  icon: StrokeIcon(['M5 13l4 4L19 7'], size: 18, color: colors.accentOn, stroke: 2),
                  label: Text(
                    l10n.onboardingIveWrittenItDown,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentOn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step 3: Tor Animation
// ──────────────────────────────────────────────────────────────

class _TorStep extends StatelessWidget {
  final int stage;
  final List<(String, String)> stages;
  final AnimationController controller;
  final VoidCallback onContinue;

  const _TorStep({
    required this.stage,
    required this.stages,
    required this.controller,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).reduceMotion;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          l10n.onboardingConnectingToTor,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: UmbraTypography.fontSerif,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: colors.textPrimary,
            fontStyle: FontStyle.italic,
            height: 1.05,
            letterSpacing: -0.015,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingThisTakesAMoment,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: UmbraTypography.fontSans,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 60),
        // Tor rings animation
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring 3
              _TorRing(
                index: 2,
                stage: stage,
                controller: controller,
                color: colors.accent,
                size: 200,
                reduceMotion: reduceMotion,
              ),
              // Ring 2
              _TorRing(
                index: 1,
                stage: stage,
                controller: controller,
                color: colors.accentHover,
                size: 140,
                reduceMotion: reduceMotion,
              ),
              // Ring 1
              _TorRing(
                index: 0,
                stage: stage,
                controller: controller,
                color: colors.accent.withValues(alpha: 0.7),
                size: 80,
                reduceMotion: reduceMotion,
              ),
              // Center
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accent, colors.accentHover],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: colors.accentOn,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Status text
        AnimatedSwitcher(
          duration: UmbraMotion.durationNormal,
          child: Column(
            key: ValueKey(stage),
            children: [
              Text(
                stages[stage].$1,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stages[stage].$2,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Stage indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stages.length, (i) {
            final isActive = i == stage;
            final isComplete = i < stage;
            return AnimatedContainer(
              duration: UmbraMotion.durationFast,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isComplete
                    ? colors.success
                    : isActive
                        ? colors.accent
                        : colors.separator,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        // Continue button (only on last stage)
        if (stage == stages.length - 1)
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              backgroundColor: colors.accent,
              foregroundColor: colors.accentOn,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UmbraRadius.lg),
              ),
            ),
            child: Text(
              l10n.commonContinue,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _TorRing extends StatelessWidget {
  final int index;
  final int stage;
  final AnimationController controller;
  final Color color;
  final double size;
  final bool reduceMotion;

  const _TorRing({
    required this.index,
    required this.stage,
    required this.controller,
    required this.color,
    required this.size,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = reduceMotion ? 1.0 : controller.value;
        final rotation = (progress + index * 0.33) * 2 * math.pi;
        final opacity = stage >= index ? 1.0 : 0.3;

        return Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              size: Size(size, size),
              painter: _TorRingPainter(color),
            ),
          ),
        );
      },
    );
  }
}

class _TorRingPainter extends CustomPainter {
  final Color color;

  _TorRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw 3 arcs
    for (int i = 0; i < 3; i++) {
      final startAngle = i * 2 * math.pi / 3;
      final sweepAngle = math.pi * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────
// Step 4: Handle
// ──────────────────────────────────────────────────────────────

class _HandleStep extends StatelessWidget {
  final TextEditingController controller;
  final String state;
  final bool busy;
  final ValueChanged<String> onChanged;
  final VoidCallback onClaim;
  final VoidCallback onSkip;

  const _HandleStep({
    required this.controller,
    required this.state,
    required this.busy,
    required this.onChanged,
    required this.onClaim,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final isFree = state == 'free';
    final isChecking = state == 'checking';
    final isTaken = state == 'taken';
    final isError = state.startsWith('error');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Title
          Text(
            l10n.onboardingClaimYourHandle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSerif,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.05,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingOptionalPublicName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 40),
          // Handle input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(UmbraRadius.xl),
              border: Border.all(
                color: isFree
                    ? colors.success.withValues(alpha: 0.5)
                    : isError
                        ? colors.error.withValues(alpha: 0.5)
                        : colors.separator,
                width: isFree || isError ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                // Input field
                Row(
                  children: [
                    Text(
                      '@',
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontMono,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colors.textTertiary,
                        letterSpacing: 0.12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontFamily: UmbraTypography.fontMono,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          letterSpacing: 0.14,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.onboardingHandleHint,
                          hintStyle: TextStyle(
                            fontFamily: UmbraTypography.fontMono,
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: colors.textTertiary,
                            letterSpacing: 0.12,
                          ),
                        ),
                        maxLength: 20,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status
                AnimatedSwitcher(
                  duration: UmbraMotion.durationFast,
                  child: _HandleStatus(state: state, colors: colors),
                ),
                // Rules
                const SizedBox(height: 16),
                _HandleRules(colors: colors),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onSkip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colors.separator),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    ),
                  ),
                  child: Text(
                    l10n.onboardingSkipForNow,
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isFree && !busy ? onClaim : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isFree ? colors.accent : colors.surfaceHover,
                    foregroundColor: isFree ? colors.accentOn : colors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    ),
                  ),
                  child: busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(colors.accentOn),
                          ),
                        )
                      : Text(
                          l10n.onboardingClaimHandle,
                          style: TextStyle(
                            fontFamily: UmbraTypography.fontSans,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HandleStatus extends StatelessWidget {
  final String state;
  final UmbraSemanticColors colors;

  const _HandleStatus({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) return const SizedBox(height: 20);

    late final String text;
    late final Color color;
    late final IconData icon;

    if (state == 'checking') {
      text = l10n.onboardingCheckingAvailability;
      color = colors.textTertiary;
      icon = Icons.schedule_rounded;
    } else if (state == 'free') {
      text = l10n.onboardingAvailable;
      color = colors.success;
      icon = Icons.check_circle_rounded;
    } else if (state == 'taken') {
      text = l10n.onboardingAlreadyTaken;
      color = colors.error;
      icon = Icons.cancel_rounded;
    } else {
      text = state.replaceFirst('error: ', '');
      color = colors.error;
      icon = Icons.error_outline_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: UmbraTypography.fontMono,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
            letterSpacing: 0.12,
          ),
        ),
      ],
    );
  }
}

class _HandleRules extends StatelessWidget {
  final UmbraSemanticColors colors;

  const _HandleRules({required this.colors});

  @override
  Widget build(BuildContext context) {
    final rules = [
      (l10n.onboardingRuleLength, true),
      (l10n.onboardingRuleChars, true),
      (l10n.onboardingRuleNoSpecial, true),
    ];

    return Column(
      children: rules.map((rule) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: colors.success,
              ),
              const SizedBox(width: 8),
              Text(
                rule.$1,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step 5: QR Code
// ──────────────────────────────────────────────────────────────

class _QRStep extends StatelessWidget {
  final String qrData;
  final VoidCallback onGenerate;
  final VoidCallback onContinue;

  const _QRStep({
    required this.qrData,
    required this.onGenerate,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Title
          Text(
            l10n.onboardingYourQRCode,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSerif,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.05,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            qrData.isEmpty
                ? l10n.onboardingGenerateToShare
                : l10n.onboardingScanToAdd,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 40),
          // QR Code container
          Container(
            width: 280,
            height: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(UmbraRadius.xl),
              border: Border.all(color: colors.separator, width: 0.5),
            ),
            child: qrData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_outlined,
                          size: 64,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.onboardingTapToGenerate,
                          style: TextStyle(
                            fontFamily: UmbraTypography.fontSans,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    painter: _QRCodePainter(qrData, colors),
                  ),
          ),
          const SizedBox(height: 32),
          // Actions
          if (qrData.isEmpty) ...[
            ElevatedButton(
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                backgroundColor: colors.accent,
                foregroundColor: colors.accentOn,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UmbraRadius.lg),
                ),
              ),
              child: Text(
                l10n.onboardingGenerateQRCode,
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share QR
                    },
                    icon: StrokeIcon(['M4 12a8 8 0 0 1 8-8h8', 'M4 12a8 8 0 0 0 8 8h8', 'M12 4v16', 'M4 12h16'], size: 18, color: colors.textSecondary, stroke: 1.8),
                    label: Text(
                      l10n.onboardingShare,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.separator),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UmbraRadius.lg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentOn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UmbraRadius.lg),
                      ),
                    ),
                    child: Text(
                      l10n.commonContinue,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Hint
          Text(
            l10n.onboardingQRCodeContainsYourKey,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colors.textTertiary,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _QRCodePainter extends CustomPainter {
  final String data;
  final UmbraSemanticColors colors;

  _QRCodePainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified QR code representation - in real app use a QR code library
    final paint = Paint()
      ..color = colors.textPrimary
      ..style = PaintingStyle.fill;

    final moduleSize = size.width / 25;
    final random = math.Random(data.hashCode);

    // Draw finder patterns (3 corners)
    _drawFinderPattern(canvas, paint, Offset(moduleSize, moduleSize), moduleSize);
    _drawFinderPattern(canvas, paint, Offset(size.width - 8 * moduleSize, moduleSize), moduleSize);
    _drawFinderPattern(canvas, paint, Offset(moduleSize, size.height - 8 * moduleSize), moduleSize);

    // Draw random data pattern (simulated)
    for (int y = 0; y < 25; y++) {
      for (int x = 0; x < 25; x++) {
        // Skip finder pattern areas
        if ((x < 8 && y < 8) ||
            (x > 16 && y < 8) ||
            (x < 8 && y > 16)) continue;

        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(x * moduleSize, y * moduleSize, moduleSize, moduleSize),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, Offset origin, double moduleSize) {
    // Outer square
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, 7 * moduleSize, 7 * moduleSize),
      paint,
    );
    // Inner white square
    final whitePaint = Paint()
      ..color = colors.surface
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(origin.dx + moduleSize, origin.dy + moduleSize, 5 * moduleSize, 5 * moduleSize),
      whitePaint,
    );
    // Center dot
    canvas.drawRect(
      Rect.fromLTWH(origin.dx + 2 * moduleSize, origin.dy + 2 * moduleSize, 3 * moduleSize, 3 * moduleSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────
// Step 6: Success
// ──────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  final VoidCallback onComplete;

  const _SuccessStep({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Success illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.success, colors.success.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.check_rounded,
                color: colors.successOn,
                size: 70,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            l10n.onboardingAllSet,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSerif,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.05,
              letterSpacing: -0.015,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingYoureReadyToMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 48),
          // Features summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(UmbraRadius.xl),
              border: Border.all(color: colors.separator, width: 0.5),
            ),
            child: Column(
              children: [
                _SuccessItem(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.onboardingEndToEndEncrypted,
                  color: colors.success,
                ),
                const SizedBox(height: 16),
                _SuccessItem(
                  icon: Icons.vpn_lock_outlined,
                  title: l10n.onboardingTorRoutingEnabled,
                  color: colors.accent,
                ),
                const SizedBox(height: 16),
                _SuccessItem(
                  icon: Icons.timer_outlined,
                  title: l10n.onboardingDisappearingMessagesReady,
                  color: colors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Start button
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
              backgroundColor: colors.accent,
              foregroundColor: colors.accentOn,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UmbraRadius.lg),
              ),
            ),
            child: Text(
              l10n.onboardingStartMessaging,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SuccessItem({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ),
        Icon(Icons.check_circle_rounded, color: color, size: 22),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Theme Toggle Button
// ──────────────────────────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final controller = UmbraTheme.of(context);

    return GestureDetector(
      onTap: () => controller.toggleTheme(),
      child: AnimatedContainer(
        duration: UmbraMotion.durationFast,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: colors.separator, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: colors.shadowSm.first.color,
              blurRadius: colors.shadowSm.first.blurRadius,
              offset: colors.shadowSm.first.offset,
            ),
          ],
        ),
        child: Icon(
          controller.isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: colors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}
