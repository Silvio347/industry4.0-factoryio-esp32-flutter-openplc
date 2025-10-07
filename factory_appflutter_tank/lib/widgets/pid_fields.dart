import 'package:flutter/material.dart';

// --- Custom PID ---
enum PidAdjustMode { preset, custom }

class PidFields extends StatefulWidget {
  final double kp, ki, kd;
  final void Function(double kp, double ki, double kd)? onApply; // <-- NOVO

  const PidFields({
    required this.kp,
    required this.ki,
    required this.kd,
    this.onApply, // <-- NOVO
  });

  @override
  State<PidFields> createState() => _PidFieldsState();
}

class _PidFieldsState extends State<PidFields> {
  late final TextEditingController _kpC = TextEditingController(
    text: widget.kp.toStringAsFixed(3),
  );
  late final TextEditingController _kiC = TextEditingController(
    text: widget.ki.toStringAsFixed(3),
  );
  late final TextEditingController _kdC = TextEditingController(
    text: widget.kd.toStringAsFixed(3),
  );

  final _formKey = GlobalKey<FormState>();

  @override
  void didUpdateWidget(covariant PidFields old) {
    super.didUpdateWidget(old);
    if (old.kp != widget.kp) _kpC.text = widget.kp.toStringAsFixed(3);
    if (old.ki != widget.ki) _kiC.text = widget.ki.toStringAsFixed(3);
    if (old.kd != widget.kd) _kdC.text = widget.kd.toStringAsFixed(3);
  }

  double _parse(TextEditingController c, double fallback) {
    final v = double.tryParse(c.text.replaceAll(',', '.'));
    return (v == null || v.isNaN || v.isInfinite) ? fallback : v;
  }

  // Dispara no botão Apply -> pai decide publicar
  void _onApplyBtn() {
    final kp = _parse(_kpC, widget.kp);
    final ki = _parse(_kiC, widget.ki);
    final kd = _parse(_kdC, widget.kd);
    widget.onApply?.call(kp, ki, kd);
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(controller: _kpC, decoration: _dec('Kp')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _kiC,
                  decoration: _dec('Ki'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _kdC,
                  decoration: _dec('Kd'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _onApplyBtn, // <<< agora chama onApply (publicação)
              icon: const Icon(Icons.save),
              label: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }
}
