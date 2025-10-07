import 'package:factory_appflutter_tank/mqtt/mqtt_manager.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TankState {
  double pv = 0; // 0..1
  double sp = 0; // 0..1
  bool auto = true;
  int preset = 1; // 0=Cons,1=Std,2=Agr
  double kp = 0, ki = 0, kd = 0;
  bool filling = false; // legacy
  bool discharging = false; // legacy

  void applyTele(String topic, String payload, MqttManager m) {
    int toInt(String s) => int.tryParse(s.trim()) ?? 0;
    double p2unit(int v) => (v / 10000.0).clamp(0.0, 1.0);

    if (topic == m.tTelePV) pv = p2unit(toInt(payload));
    if (topic == m.tTeleSP) sp = p2unit(toInt(payload));
    if (topic == m.tTeleMode) auto = toInt(payload) == 1;

    // PID gains (payload tipo "1.2345")
    double toD(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
    if (topic == m.tTeleKp) kp = toD(payload);
    if (topic == m.tTeleKi) ki = toD(payload);
    if (topic == m.tTeleKd) kd = toD(payload);

    // legado:
    if (topic == m.tStateFill) filling = payload.trim() == '1';
    if (topic == m.tStateDischarge) discharging = payload.trim() == '1';
    if (topic == m.tStateDisplay) {
      final raw = toInt(payload); // 0..32767
      pv = (raw / 32767.0).clamp(0.0, 1.0);
    }
  }
}

class FancyTank extends StatefulWidget {
  final double level; // 0..1
  final bool filling;
  final bool discharging;
  final bool showPercent;
  final Color? liquidColor;
  final Color borderColor;
  final Color backgroundColor;

  const FancyTank({
    super.key,
    required this.level,
    this.filling = false,
    this.discharging = false,
    this.showPercent = true,
    this.liquidColor,
    this.borderColor = const Color(0xCCFFFFFF),
    this.backgroundColor = const Color(0xFF111417),
  });

  @override
  State<FancyTank> createState() => _FancyTankState();
}

class _FancyTankState extends State<FancyTank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _resolveLiquidColor() {
    if (widget.filling) return Colors.greenAccent;
    if (widget.discharging) return Colors.redAccent;
    return widget.liquidColor ?? Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    final liquid = _resolveLiquidColor();

    return AspectRatio(
      aspectRatio: 0.52, // tanque alto
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _GlassTankFrame(
                  borderColor: widget.borderColor,
                  backgroundColor: widget.backgroundColor,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _LiquidPainter(
                      level: widget.level.clamp(0.0, 1.0),
                      t: _ctrl.value,
                      color: liquid,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x33FFFFFF),
                          Color(0x11000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.showPercent)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.1, -0.3),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        '${(widget.level * 100).clamp(0, 100).toStringAsFixed(0)} %',
                        key: ValueKey<int>((widget.level * 100).round()),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.filling || widget.discharging)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _StatusPill(
                      text: widget.filling ? 'Enchendo' : 'Esvaziando',
                      color: widget.filling
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassTankFrame extends StatelessWidget {
  final Color borderColor;
  final Color backgroundColor;
  const _GlassTankFrame({
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Colors.black54,
          ),
        ],
        border: Border.all(color: borderColor, width: 2.5),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double level; // 0..1
  final double t; // 0..1 animação
  final Color color;

  _LiquidPainter({required this.level, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final waterline = size.height * (1 - level);
    final rect = Offset.zero & size;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.85),
        color.withOpacity(0.75),
      ],
    ).createShader(rect);

    final a1 = math.max(4.0, size.height * 0.02);
    final a2 = math.max(6.0, size.height * 0.03);
    final k = 2 * math.pi / math.max(40.0, size.width * 0.9);
    final phase1 = 2 * math.pi * t;
    final phase2 = 2 * math.pi * (t * 1.6 % 1.0);

    final p1 = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = waterline + a1 * math.sin(k * x + phase1);
      p1.lineTo(x, y);
    }
    p1
      ..lineTo(size.width, size.height)
      ..close();

    final p2 = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = waterline + a2 * math.sin(k * x + phase2 + math.pi / 2);
      p2.lineTo(x, y);
    }
    p2
      ..lineTo(size.width, size.height)
      ..close();

    final paint1 = Paint()..shader = gradient;
    final paint2 = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.plus;

    canvas.drawPath(p1, paint1);
    canvas.drawPath(p2, paint2);

    _drawBubbles(canvas, size, waterline);
  }

  void _drawBubbles(Canvas canvas, Size size, double waterline) {
    final bubbles = 8;
    final rnd = math.Random(7);
    for (int i = 0; i < bubbles; i++) {
      final bx = (rnd.nextDouble() * 0.8 + 0.1) * size.width;
      final r = size.shortestSide * (0.008 + rnd.nextDouble() * 0.012);
      final speed = 0.5 + rnd.nextDouble() * 0.8;
      final phase = (t * speed + i * 0.13) % 1.0;
      final by = math.max(
        waterline + r,
        size.height - phase * (size.height - waterline),
      );
      final bubblePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.35);
      canvas.drawCircle(Offset(bx, by), r, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) {
    return old.level != level || old.t != t || old.color != color;
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black45,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    text == 'Enchendo'
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: .2,
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
