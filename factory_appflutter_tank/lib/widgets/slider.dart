import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ValueSlider extends StatefulWidget {
  final String title;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  const ValueSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<ValueSlider> createState() => _ValueSliderState();
}

class _ValueSliderState extends State<ValueSlider> {
  static const _decimals = 1; // <<< defina quantas casas quer mostrar
  late final TextEditingController _ctrl;

  String _fmtPct(double v) => (v * 100).toStringAsFixed(_decimals);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmtPct(widget.value));
  }

  @override
  void didUpdateWidget(covariant ValueSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mantém o campo em sync quando valor muda externamente (sem arredondar para inteiro)
    _ctrl.text = _fmtPct(widget.value);
  }

  void _commit() {
    final raw = _ctrl.text.trim().replaceAll(',', '.');
    final n = double.tryParse(raw);
    if (n == null) return;
    // n está em %, converte e limita a min/max
    final clampedPct = n.clamp(widget.min * 100, widget.max * 100);
    final asFrac = (clampedPct / 100).toDouble();
    widget.onChanged(asFrac);

    // Atualiza o campo com o formato correto e 1 casa
    _ctrl.text = _fmtPct(asFrac);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    // Permite dígitos, vírgula e ponto
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    // (Opcional) limita a 1 casa decimal:
                    TextInputFormatter.withFunction((oldV, newV) {
                      final t = newV.text;
                      final m = RegExp(
                        r'^\d{0,3}([.,]\d{0,1})?$',
                      ).firstMatch(t);
                      return m == null ? oldV : newV;
                    }),
                  ],
                  onSubmitted: (_) => _commit(),
                  onEditingComplete: _commit,
                ),
              ),
            ],
          ),
          Slider(
            value: widget.value,
            onChanged: (v) {
              widget.onChanged(v);
              // Atualiza o campo mantendo 1 casa decimal
              _ctrl.text = _fmtPct(v);
            },
            min: widget.min,
            max: widget.max,
          ),
        ],
      ),
    );
  }
}
