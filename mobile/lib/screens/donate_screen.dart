// SPDX-License-Identifier: GPL-3.0-or-later
// the backing screen: tiers, custom amount, crypto addresses. only bitcoin
// can earn a badge, through the signed receipt the invoice screen checks
// against our pinned key. the other coins end at the address.
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../supporter.dart';
import '../badge_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/press_scale.dart';
import '../widgets/motion.dart' show haloRoute;
import '../address_text.dart';
import '../main.dart' show appState;
import 'modes_screen.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n.dart';
import '../l10n/marked.dart';
import '../l10n/numbers.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});
  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _Coin {
  final String key, name, sym, note;
  final Color tint;
  const _Coin(this.key, this.name, this.sym, this.note, this.tint);
}

// only bitcoin unlocks a badge: we verify it with our own node. the others
// would need a third-party api that sees the payer's ip.
List<_Coin> get _coins => [
  _Coin(
    'btc',
    l10n.donateBitcoin,
    l10n.donateText,
    l10n.donateBadgeUnlocks,
    Color(0xFFF7931A),
  ),
  _Coin(
    'xmr',
    l10n.donateMonero,
    '\u0271',
    l10n.donateManualNoBadge,
    Color(0xFFFF6600),
  ),
  _Coin(
    'sol',
    l10n.donateSolana,
    '\u25CE',
    l10n.donateManualNoBadge,
    Color(0xFF9945FF),
  ),
  _Coin(
    'eth',
    l10n.donateEthereum,
    l10n.donateText2,
    l10n.donateManualNoBadge,
    Color(0xFF8AA0F0),
  ),
];

// the real backing wallets
const _addrs = {
  'btc': 'bc1qdewmhrwkh8elts8ldehfq5qaj68ymexfnzkk7j',
  'xmr':
      '4ApyZS72ZYCG3z8rtwwX6JgdjSdAcphHSFRxiKrL5yLnYYz8fvXQayWMyw79AxFoQ7BXLfzEExk5f7Z2xPdEPWyRBXtVwiD',
  'sol': 'DrxaQPM8wD63EErdGN9GrazGVnxwiCB9Pc6RYR3v2x4a',
  'eth': '0x55014AF792d54E4350b7f4bfc7be7D62EbbCfE43',
};

class _DonateScreenState extends State<DonateScreen> {
  int _amount = 20;

  @override
  void initState() {
    super.initState();
    // an invoice the screen gave up on last time may have been honoured
    // since. ask once, quietly, and say so if it was.
    if (appState.sendMode == 'private') {
      settleOpenInvoice().then((t) {
        if (t != null && mounted) {
          HapticFeedback.mediumImpact();
          showHaloToast(
            context,
            l10n.donateYourEarlierBitcoinPayment(tierKey(t)),
          );
        }
      });
    }
  }

  final _customCtl = TextEditingController();
  String _coin = 'btc';

  SupporterTier _tierFor(int amt) {
    if (amt >= 100) return SupporterTier.guardian;
    if (amt >= 50) return SupporterTier.patron;
    if (amt >= 20) return SupporterTier.supporter;
    return SupporterTier.none;
  }

  void _pickTier(int amt) {
    setState(() {
      _amount = amt;
      _customCtl.clear();
    });
  }

  @override
  void dispose() {
    _customCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        backgroundColor: colors.ink,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          l10n.donateSupport,
          style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(),
              const SizedBox(height: 22),
              _tiers(),
              const SizedBox(height: 22),
              // todo: card payments, once a processor is behind them
              _cryptoPane(),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.accent, colors.accentHover],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.5),
                blurRadius: 36,
                spreadRadius: -6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '\u2726',
            style: TextStyle(fontSize: 38, color: colors.accentOn),
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: markedSpans(
              l10n.donateKeepKryfo,
              TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 25, fontWeight: FontWeight.w400, color: colors.accent, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
            ),
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 25, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.donateNoAdsNoInvestors,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.separator),
          ),
          child: Text.rich(
            TextSpan(
              children: markedSpans(
                l10n.donateBackItAnonymouslyBadge,
                TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12),
              ),
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
          ),
        ),
      ],
    );
  }

  Widget _tiers() {
    return Row(
      children: [
        _tierCard(20, l10n.donateTierSupporter, '\u25CF', const [
          Color(0xFF60A5FA),
          Color(0xFF2563EB),
        ], const Color(0xFF0C1F3F)),
        const SizedBox(width: 8),
        _tierCard(50, l10n.donateTierPatron, '\u25C6', const [
          Color(0xFFA78BFA),
          Color(0xFF6D28D9),
        ], const Color(0xFF1E1B4B)),
        const SizedBox(width: 8),
        _tierCard(100, l10n.donateTierGuardian, '\u2726', const [
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ], colors.accentOn),
      ],
    );
  }

  Widget _tierCard(
    int amt,
    String name,
    String glyph,
    List<Color> grad,
    Color fg,
  ) {
    final sel = _amount == amt && _customCtl.text.isEmpty;
    return Expanded(
      // the chosen tier grows a touch and gets its amber ring, like a face
      // picked on the introduce sheet
      child: PressScale(
        onTap: () {
          HapticFeedback.selectionClick();
          _pickTier(amt);
        },
        child: AnimatedScale(
          scale: sel ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: UmbraMotion.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
            decoration: BoxDecoration(
              color: sel ? colors.accentSoft : colors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: sel ? colors.accent : colors.separator,
                width: sel ? 1.4 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.25),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: grad),
                  ),
                  alignment: Alignment.center,
                  child: Text(glyph, style: TextStyle(fontSize: 13, color: fg)),
                ),
                const SizedBox(height: 7),
                Text(
                  dollars(amt),
                  style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 17, fontWeight: FontWeight.w400, color: sel ? colors.accent : colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
                ),
                Text(
                  name,
                  style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 8, fontWeight: FontWeight.w500, color: sel ? colors.accent : colors.textSecondary, letterSpacing: 0.12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cryptoPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _coinCard(_coins[0]),
            const SizedBox(width: 8),
            _coinCard(_coins[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _coinCard(_coins[2]),
            const SizedBox(width: 8),
            _coinCard(_coins[3]),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const UmbraMotion.durationNormal,
          switchInCurve: UmbraMotion.easeOut,
          switchOutCurve: UmbraMotion.easeSharp,
          child: KeyedSubtree(key: ValueKey(_coin), child: _addressBox()),
        ),
      ],
    );
  }

  Widget _coinCard(_Coin c) {
    final sel = _coin == c.key;
    return Expanded(
      child: PressScale(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _coin = c.key);
        },
        child: AnimatedContainer(
          duration: const UmbraMotion.durationNormal,
          curve: UmbraMotion.easeOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: sel ? colors.accent : colors.separator),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.tint.withValues(alpha: 0.16),
                ),
                alignment: Alignment.center,
                child: Text(
                  c.sym,
                  style: TextStyle(color: c.tint, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                    ),
                    if (c.note.isNotEmpty)
                      Text(
                        c.note,
                        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 8, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // the badge is granted only when a signed receipt checks out in
  // _InvoiceScreen, never on a tap. the service is an onion: off onion mode
  // a plain client would ask the local resolver for its name, the one
  // hostname this app must never leak. so no request unless on onion.
  bool get _onOnion => appState.sendMode == 'private';

  Future<void> _openBitcoinInvoice() async {
    if (!_onOnion) return;
    final tier = _tierFor(_amount);
    // under twenty there is no tier, so there is no invoice to make
    if (tier == SupporterTier.none) return;
    final key = tierKey(tier);
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      haloRoute(
        _InvoiceScreen(
          tier: tier,
          tierKey: key,
          fallbackAddress: _addrs['btc'] ?? '',
        ),
      ),
    );
  }

  Widget _addressBox() {
    final coin = _coins.firstWhere((c) => c.key == _coin);
    final addr = _addrs[_coin] ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // the qr leads: a scan cannot be swapped by a clipboard hijacker
          Center(child: _QrCard(data: addr, size: 168)),
          const SizedBox(height: 12),
          Text(
            l10n.donateAddressCheckItAgainst(coin.name),
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.ink,
              borderRadius: BorderRadius.circular(UmbraRadius.md),
              border: Border.all(color: colors.separator),
            ),
            child: Text(
              chunkAddress(addr),
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11.5, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12).copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 10),
          PressScale(
            onTap: () {
              HapticFeedback.mediumImpact();
              copySensitive(addr);
              showHaloToast(context, l10n.donateAddressCopiedClearsIn);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(UmbraRadius.md),
              ),
              child: Text(
                l10n.donateCopyAddress,
                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: colors.accentOn, letterSpacing: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: colors.ink,
              borderRadius: BorderRadius.circular(UmbraRadius.md),
              border: Border.all(color: colors.separator),
            ),
            child: Text(
              _coin == 'btc'
                  ? l10n.donateBitcoinIsVerifiedBy
                  : l10n.donateWeCanTVerify,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9.5, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
            ),
          ),
          // only bitcoin has a next step: our node watches for it. the other
          // coins end here, since a button anyone can press proves nothing.
          if (_coin == 'btc' && !_onOnion) ...[
            const SizedBox(height: 10),
            Text(
              l10n.donateBitcoinBadgesNeedOnion,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 8),
            PressScale(
              onTap: () async {
                HapticFeedback.selectionClick();
                await Navigator.of(
                  context,
                ).push(haloRoute(const ModesScreen()));
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UmbraRadius.md),
                  border: Border.all(color: colors.separator),
                ),
                child: Text(
                  l10n.donateSwitchToOnion,
                  style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                ),
              ),
            ),
          ] else if (_coin == 'btc') ...[
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final can = _tierFor(_amount) != SupporterTier.none;
                return PressScale(
                  onTap: can ? _openBitcoinInvoice : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(UmbraRadius.md),
                      border: Border.all(
                        color: can ? colors.accent : colors.separator,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      can
                          ? l10n.donatePayWithBitcoin
                          : l10n.donateBadgesStartAt20,
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: can ? colors.accent : colors.textTertiary, height: 1.5, letterSpacing: 0),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────── live bitcoin invoice flow ───────────────────────

enum _Phase { needsOnion, loading, unreachable, invoice, confirmed, expired }

class _InvoiceScreen extends StatefulWidget {
  final SupporterTier tier;
  final String tierKey;
  final String fallbackAddress;
  const _InvoiceScreen({
    required this.tier,
    required this.tierKey,
    required this.fallbackAddress,
  });
  @override
  State<_InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<_InvoiceScreen>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.loading;
  BadgeInvoice? _inv;
  Timer? _poll;
  Timer? _tick;
  int _secsLeft = 15 * 60;
  int _lateChecks = 0;
  late final AnimationController _pulse;
  // the wait for the invoice, in seconds, so the screen can show it is
  // alive. each ask has a number: one the person walked away from must not
  // flip the screen when it finally answers.
  int _waited = 0;
  Timer? _waitTick;
  int _ask = 0;
  bool _gaveUp = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    _waitTick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    // never touch the service off onion mode: no request, no lookup
    if (appState.sendMode != 'private') {
      setState(() => _phase = _Phase.needsOnion);
      return;
    }
    final ask = ++_ask;
    setState(() {
      _phase = _Phase.loading;
      _waited = 0;
      _gaveUp = false;
    });
    _waitTick?.cancel();
    _waitTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _phase == _Phase.loading) setState(() => _waited++);
    });
    final inv = await createInvoice(widget.tierKey);
    if (!mounted || ask != _ask) return;
    _waitTick?.cancel();
    if (inv == null) {
      // tor or the service is unreachable: the static address still takes a
      // donation, with no badge
      setState(() => _phase = _Phase.unreachable);
      return;
    }
    setState(() {
      _inv = inv;
      _phase = _Phase.invoice;
    });
    await saveOpenInvoice(inv.id, widget.tier);
    _secsLeft = 15 * 60;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // never override a payment that already confirmed
      if (_phase != _Phase.invoice) {
        _tick?.cancel();
        return;
      }
      setState(() {
        _secsLeft--;
        if (_secsLeft <= 0) {
          _tick?.cancel();
          _poll?.cancel();
          _phase = _Phase.expired;
          // our clock ran out, not necessarily the service's. keep asking,
          // slowly, for another quarter hour: a payment made at the edge
          // can still be honoured, and money must never vanish quietly.
          _lateChecks = 0;
          _poll = Timer.periodic(const Duration(seconds: 60), (t) {
            if (!mounted || _phase != _Phase.expired || _lateChecks++ >= 15) {
              t.cancel();
              return;
            }
            _check();
          });
          _check();
        }
      });
    });
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _check());
    _check();
  }

  Future<void> _check() async {
    final inv = _inv;
    // one ask at a time: over a slow circuit a check can outlast the six
    // seconds to the next
    if (inv == null || _checking) return;
    _checking = true;
    final BadgeReceipt r;
    try {
      r = await fetchReceipt(inv.id);
    } finally {
      _checking = false;
    }
    if (!mounted) return;
    switch (r.state) {
      case ReceiptState.paid:
        _poll?.cancel();
        _tick?.cancel();
        await clearOpenInvoice();
        // signature already verified inside fetchReceipt. grant the tier and
        // keep the receipt so the badge stays provable without the network.
        if (widget.tier != SupporterTier.none) {
          await saveSupporterTier(widget.tier);
          if (r.payload != null && r.sig != null) {
            await saveBadgeReceipt(r.payload!, r.sig!);
          }
        }
        if (!mounted) return;
        setState(() => _phase = _Phase.confirmed);
        break;
      case ReceiptState.expired:
        // the service itself says so: nothing left to wait for
        _poll?.cancel();
        await clearOpenInvoice();
        if (mounted) setState(() => _phase = _Phase.expired);
        break;
      default:
        break; // pending: keep polling
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        backgroundColor: colors.ink,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(
          l10n.donateBitcoin,
          style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: UmbraMotion.easeOut,
          switchOutCurve: UmbraMotion.easeSharp,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.needsOnion:
        return _needsOnionView();
      case _Phase.loading:
        return _loadingView();
      case _Phase.unreachable:
        return _unreachableView();
      case _Phase.invoice:
        return _invoiceView();
      case _Phase.confirmed:
        return _ConfirmedView(tier: widget.tier);
      case _Phase.expired:
        return _expiredView();
    }
  }

  // ── loading ──
  String _fmtLeft() {
    final m = _secsLeft ~/ 60;
    final sec = _secsLeft % 60;
    return '${whole(m)}:${twoDigits(sec)}';
  }

  Widget _loadingView() {
    return Center(
      key: const ValueKey('load'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_pulse.value + i * 0.25) % 1.0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent.withValues(alpha: 0.3 + t * 0.6),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.donateReachingThePaymentService,
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
          ),
          const SizedBox(height: 8),
          Text(
            _waited < 5
                ? l10n.donateThisCanTakeUp
                : l10n.donateSThisCanTake(whole(_waited)),
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
          ),
          // held back until the wait is long enough to doubt
          if (_waited >= 20 && widget.fallbackAddress.isNotEmpty) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: _ghostButton(l10n.donateUseTheAddressInstead, () {
                _ask++;
                _waitTick?.cancel();
                setState(() {
                  _gaveUp = true;
                  _phase = _Phase.unreachable;
                });
              }),
            ),
          ],
        ],
      ),
    );
  }

  // ── off onion: nothing was asked ──
  Widget _needsOnionView() {
    return Center(
      key: const ValueKey('onion'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.donateBitcoinBadgesNeedOnion,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.donateThePaymentServiceIs,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 24),
            _fillButton(l10n.donateSwitchToOnion, () async {
              await Navigator.of(context).push(haloRoute(const ModesScreen()));
              if (mounted) _start();
            }),
          ],
        ),
      ),
    );
  }

  // ── unreachable → static fallback ──
  Widget _unreachableView() {
    final addr = widget.fallbackAddress;
    return SingleChildScrollView(
      key: const ValueKey('unreach'),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.separator),
            ),
            child: Text(
              _gaveUp
                  ? l10n.donateTorWasSlowTo
                  : l10n.donateThePaymentServiceIsHavingTrouble,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
          ),
          const SizedBox(height: 16),
          if (addr.isNotEmpty) _StaticAddress(address: addr),
          const SizedBox(height: 14),
          _ghostButton(l10n.commonTryAgain, _start),
        ],
      ),
    );
  }

  // ── live invoice ──
  Widget _invoiceView() {
    final inv = _inv!;
    return SingleChildScrollView(
      key: const ValueKey('inv'),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              l10n.donateBtc(inv.btc),
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 26, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              l10n.donateSendExactlyThisAmount(_fmtLeft()),
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _QrCard(data: inv.uri, size: 190)),
          const SizedBox(height: 16),
          _copyRow(l10n.donateAddress, inv.address),
          const SizedBox(height: 14),
          _watchingPill(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _fillButton(l10n.donateOpenWallet, () async {
                  final uri = Uri.parse(inv.uri);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ghostButton(l10n.donateCopy, () => _copy(inv.address)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              l10n.donateThisScreenUpdatesItself,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9.5, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _watchingPill() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.separator),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(
                  alpha: 0.35 + _pulse.value * 0.55,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.donateWatchingTheChainFor,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
            ),
          ],
        ),
      ),
    );
  }

  // ── expired ──
  Widget _expiredView() {
    return Center(
      key: const ValueKey('exp'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.donateThisInvoiceExpired,
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.donateInvoicesTimeOutIf,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 24),
            _fillButton(l10n.donateNewInvoice, _start),
            const SizedBox(height: 10),
            _ghostButton(l10n.donateIPaidCheckAgain, _check),
          ],
        ),
      ),
    );
  }

  // ── shared bits ──
  Widget _copyRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12)),
          const SizedBox(height: 6),
          Text(
            chunkAddress(value),
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11.5, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  void _copy(String v) {
    HapticFeedback.mediumImpact();
    copySensitive(v);
    showHaloToast(context, l10n.donateAddressCopiedClearsIn);
  }

  Widget _fillButton(String label, VoidCallback onTap) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: colors.accentOn, height: 1.5, letterSpacing: 0),
        ),
      ),
    );
  }

  Widget _ghostButton(String label, VoidCallback onTap) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.accent),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: colors.accent, height: 1.5, letterSpacing: 0),
        ),
      ),
    );
  }
}

// static copy-address block reused by the unreachable fallback.
class _StaticAddress extends StatelessWidget {
  final String address;
  const _StaticAddress({required this.address});
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _QrCard(data: address, size: 168)),
          const SizedBox(height: 10),
          Text(
            chunkAddress(address),
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11.5, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12).copyWith(height: 1.6),
          ),
          const SizedBox(height: 10),
          PressScale(
            onTap: () {
              HapticFeedback.mediumImpact();
              copySensitive(address);
              showHaloToast(context, l10n.donateAddressCopiedClearsIn);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(UmbraRadius.md),
              ),
              child: Text(
                l10n.donateCopyAddress,
                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: colors.accentOn, letterSpacing: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// confirmed: animated check that draws itself, then rolls into badge opt-in.
class _ConfirmedView extends StatefulWidget {
  final SupporterTier tier;
  const _ConfirmedView({required this.tier});
  @override
  State<_ConfirmedView> createState() => _ConfirmedViewState();
}

class _ConfirmedViewState extends State<_ConfirmedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _showBadge = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _showBadge = true);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _choose(bool show) async {
    if (show) await saveShowBadgeSelf(true);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final t = widget.tier;
    return Center(
      key: const ValueKey('ok'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(
                  painter: _CheckPainter(_c.value, colors.accent),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.donatePaymentConfirmed,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 24, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
            ),
            const SizedBox(height: 10),
            Text(
              t == SupporterTier.none
                  ? l10n.donateThankYouForKeeping
                  : l10n.donateVerifiedOnChainYou(tierKey(t)),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.55, letterSpacing: 0),
            ),
            const SizedBox(height: 32),
            AnimatedOpacity(
              opacity: _showBadge ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              child: t == SupporterTier.none
                  ? _fill(l10n.donateDone, () => _choose(false))
                  : Column(
                      children: [
                        _fill(l10n.donateWearMyBadge, () => _choose(true)),
                        const SizedBox(height: 10),
                        PressScale(
                          onTap: () => _choose(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.donateJustGladToHelp,
                              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fill(String label, VoidCallback onTap) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentOn, height: 1.5, letterSpacing: 0),
        ),
      ),
    );
  }
}

// a checkmark that draws its circle then its tick as t goes 0..1.
class _CheckPainter extends CustomPainter {
  final double t;
  final Color color;
  _CheckPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    final circleT = (t / 0.6).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5708,
      6.2832 * circleT,
      false,
      ring,
    );
    if (t > 0.6) {
      final tickT = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
      final p1 = Offset(size.width * 0.30, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.66);
      final p3 = Offset(size.width * 0.72, size.height * 0.36);
      final path = Path()..moveTo(p1.dx, p1.dy);
      if (tickT < 0.5) {
        final k = tickT / 0.5;
        path.lineTo(p1.dx + (p2.dx - p1.dx) * k, p1.dy + (p2.dy - p1.dy) * k);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final k = (tickT - 0.5) / 0.5;
        path.lineTo(p2.dx + (p3.dx - p2.dx) * k, p2.dy + (p3.dy - p2.dy) * k);
      }
      canvas.drawPath(path, ring);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}

// a qr on the light card, settling in the way the my kryfo one does: the
// frame first, then the code fades and eases up into it
class _QrCard extends StatefulWidget {
  final String data;
  final double size;
  const _QrCard({required this.data, required this.size});
  @override
  State<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<_QrCard> {
  bool _shown = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: BorderRadius.circular(UmbraRadius.lg),
      ),
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        curve: UmbraMotion.easeOut,
        child: AnimatedScale(
          scale: _shown ? 1 : 0.94,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          child: QrImageView(
            data: widget.data,
            version: QrVersions.auto,
            size: widget.size,
            backgroundColor: colors.textPrimary,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: colors.ink,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
