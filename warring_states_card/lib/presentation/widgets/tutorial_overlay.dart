import 'package:flutter/material.dart';
import '../../l10n/locale_service.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  int _step = 0;
  late AnimationController _fadeCtrl;

  static const _gold = Color(0xFFB8860B);
  static const _parch = Color(0xFFE8D5B7);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _s(LocaleService.I.t('tutorial.welcome'), LocaleService.I.t('tutorial.welcome_desc'), 0.5, 0.35, 80),
      _s(LocaleService.I.t('tutorial.battle'), LocaleService.I.t('tutorial.battle_desc'), 0.5, 0.45, 80),
      _s(LocaleService.I.t('tutorial.hand'), LocaleService.I.t('tutorial.hand_desc'), 0.5, 0.6, 90),
      _s(LocaleService.I.t('tutorial.attack'), LocaleService.I.t('tutorial.attack_desc'), 0.5, 0.5, 70),
      _s(LocaleService.I.t('tutorial.done'), LocaleService.I.t('tutorial.done_desc'), 0.5, 0.5, 40),
    ];
    final s = steps[_step];

    return ColoredBox(
      color: Colors.black.withAlpha(200),
      child: Stack(children: [
        Positioned(
          bottom: 100, left: 24, right: 24,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF3D2B1F), borderRadius: BorderRadius.circular(12), border: Border.all(color: _gold.withAlpha(100))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(s.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
                const SizedBox(height: 8),
                Text(s.desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _parch.withAlpha(200))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _advance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(_step < steps.length - 1 ? LocaleService.I.t('tutorial.next') : LocaleService.I.t('tutorial.start')),
                ),
              ]),
            ),
          ),
        ),
        Positioned(top: 48, right: 16,
          child: TextButton(onPressed: widget.onComplete, child: Text(LocaleService.I.t('tutorial.skip'), style: const TextStyle(color: Colors.white60))),
        ),
      ]),
    );
  }

  void _advance() {
    if (_step < 4) {
      _fadeCtrl.reset();
      setState(() => _step++);
      _fadeCtrl.forward();
    } else {
      widget.onComplete();
    }
  }

  _StepDef _s(String t, String d, double hx, double hy, double hr) => _StepDef(t, d, hx, hy, hr);
}

class _StepDef {
  _StepDef(this.title, this.desc, this.holeX, this.holeY, this.holeR);
  final String title, desc;
  final double holeX, holeY, holeR;
}

class _HolePainter extends CustomPainter {
  _HolePainter({required this.holeCenter, required this.holeRadius});
  final Offset holeCenter; final double holeRadius;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withAlpha(160));
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withAlpha(160));
    canvas.drawCircle(holeCenter, holeRadius, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _HolePainter old) => old.holeCenter != holeCenter || old.holeRadius != holeRadius;
}
