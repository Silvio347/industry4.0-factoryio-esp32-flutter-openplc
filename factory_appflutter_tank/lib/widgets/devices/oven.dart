import 'dart:math' as math;
import 'package:flutter/material.dart';

class FancyOven extends StatefulWidget {
  final double temperature; // em °C (valor já mapeado pela UI)
  final double setpoint;    // em °C
  final bool heating;       // true = resistência ligada (para o “glow”)
  final double minTemp;
  final double maxTemp;
  final bool showLabels;
  final Color borderColor;
  final Color backgroundColor;
  final Color coilColor;

  const FancyOven({
    super.key,
    required this.temperature,
    required this.setpoint,
    this.heating = false,
    this.minTemp = 0,
    this.maxTemp = 300,
    this.showLabels = true,
    this.borderColor = const Color(0xCCFFFFFF),
    this.backgroundColor = const Color(0xFF111417),
    this.coilColor = Colors.orangeAccent,
  });

  @override
  State<FancyOven> createState() => _FancyOvenState();
}

class _FancyOvenState extends State<FancyOven>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.4, // forno mais “deitado”
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                _GlassOvenFrame(
                  borderColor: widget.borderColor,
                  backgroundColor: widget.backgroundColor,
                ),

                // Câmara interna com resistência/ondas de calor
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _OvenInteriorPainter(
                      t: t,
                      heating: widget.heating,
                      coil: widget.coilColor,
                    ),
                  ),
                ),

                // “vidro” com brilho diagonal
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

                // Barra vertical de temperatura (termômetro) à direita
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        // espaço para a câmara
                        const Expanded(child: SizedBox()),
                        SizedBox(
                          width: 48,
                          child: _ThermoBar(
                            value: widget.temperature,
                            setpoint: widget.setpoint,
                            min: widget.minTemp,
                            max: widget.maxTemp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Display T/SP no topo direito
                if (widget.showLabels)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _TempDisplay(
                        key: ValueKey<int>(widget.temperature.round()),
                        temperature: widget.temperature,
                        setpoint: widget.setpoint,
                      ),
                    ),
                  ),

                // Pill de status no rodapé esquerdo
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _StatusPill(
                    text: widget.heating ? 'Aquecendo' : 'Standby',
                    color: widget.heating
                        ? widget.coilColor
                        : Colors.white70,
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

class _GlassOvenFrame extends StatelessWidget {
  final Color borderColor;
  final Color backgroundColor;
  const _GlassOvenFrame({
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

class _OvenInteriorPainter extends CustomPainter {
  final double t;      // 0..1 animação
  final bool heating;
  final Color coil;

  _OvenInteriorPainter({
    required this.t,
    required this.heating,
    required this.coil,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo sutil com vinheta
    final chamber = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF12161A),
          Color(0xFF0E1114),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(chamber, bg);

    // Resistências: 3 ondas senoidais horizontais “brilhando”
    final lines = [0.28, 0.50, 0.72]; // posições relativas em altura
    final baseAmp = math.max(4.0, size.height * 0.03);
    final k = 2 * math.pi / math.max(60.0, size.width * 0.9);

    for (int i = 0; i < lines.length; i++) {
      final y0 = size.height * lines[i];
      final phase = 2 * math.pi * ((t * (1.4 + i * 0.15)) % 1.0);
      final amp = baseAmp * (0.8 + 0.25 * math.sin(phase * 0.8));

      final path = Path()..moveTo(0, y0);
      for (double x = 0; x <= size.width; x++) {
        final y = y0 + amp * math.sin(k * x + phase);
        path.lineTo(x, y);
      }

      // brilho/“glow” quando heating = true
      final intensity =
          heating ? 0.7 + 0.3 * math.sin(phase * 1.3 + i) : 0.15;
      final pMain = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3.5, size.shortestSide * 0.012)
        ..color = coil.withOpacity(intensity.clamp(0.0, 1.0));

      final pGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pMain.strokeWidth * 2.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = coil.withOpacity((intensity * 0.65).clamp(0.0, 0.7));

      canvas.drawPath(path, pGlow);
      canvas.drawPath(path, pMain);
    }

    // “Haze” de calor subindo (faixas sutis)
    final haze = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          coil.withOpacity(heating ? 0.10 : 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Offset(0, size.height * 0.35) &
          Size(size.width, size.height * 0.65));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65),
      haze,
    );
  }

  @override
  bool shouldRepaint(covariant _OvenInteriorPainter old) {
    return old.t != t || old.heating != heating || old.coil != coil;
  }
}

class _ThermoBar extends StatelessWidget {
  final double value;
  final double setpoint;
  final double min;
  final double max;
  const _ThermoBar({
    required this.value,
    required this.setpoint,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max);
    final sp = setpoint.clamp(min, max);
    final frac = (v - min) / (max - min);
    final spFrac = (sp - min) / (max - min);

    return CustomPaint(
      painter: _ThermoPainter(level: frac, sp: spFrac),
    );
  }
}

class _ThermoPainter extends CustomPainter {
  final double level; // 0..1
  final double sp;    // 0..1
  _ThermoPainter({required this.level, required this.sp});

  @override
  void paint(Canvas canvas, Size size) {
    final r = 12.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(r),
    );

    // trilha
    final pTrack = Paint()
      ..color = const Color(0xFF0D1013)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(track, pTrack);

    // preenchimento (nível atual)
    final fillH = size.height * (1 - level);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, fillH, size.width, size.height - fillH),
      Radius.circular(r),
    );
    final pFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE6A36B),
          Color(0xFFFFC78A),
          Color(0xFFFFD9A6),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(fillRect, pFill);

    // marca do setpoint
    final spY = size.height * (1 - sp);
    final pSP = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final line = Path()
      ..moveTo(4, spY)
      ..lineTo(size.width - 4, spY);
    canvas.drawPath(line, pSP);

    // moldura
    final pBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white24;
    canvas.drawRRect(track, pBorder);
  }

  @override
  bool shouldRepaint(covariant _ThermoPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.sp != sp;
  }
}

class _TempDisplay extends StatelessWidget {
  final double temperature;
  final double setpoint;
  const _TempDisplay({
    super.key,
    required this.temperature,
    required this.setpoint,
  });

  @override
  Widget build(BuildContext context) {
    final t = temperature.clamp(-999, 999).toStringAsFixed(0);
    final sp = setpoint.clamp(-999, 999).toStringAsFixed(0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.thermostat, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              Text('T: $t °C'),
              const SizedBox(width: 10),
              Text('SP: $sp °C'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.8)),
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
                    Icons.local_fire_department_rounded,
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
