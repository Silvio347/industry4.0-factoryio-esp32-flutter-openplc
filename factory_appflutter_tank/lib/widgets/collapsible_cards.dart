import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollapsibleCard extends StatefulWidget {
  final String title;
  final Widget child;
  final String? storageKey;
  final bool initiallyExpanded; // usado só como fallback quando não há prefs
  final EdgeInsets padding;

  const CollapsibleCard({
    super.key,
    required this.title,
    required this.child,
    this.storageKey,
    this.initiallyExpanded = false, // começa FECHADO por padrão
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    // carrega do storage (se tiver); se não tiver, fica no fallback (fechado)
    if (widget.storageKey != null) {
      SharedPreferences.getInstance().then((p) {
        final has = p.getBool('cc_${widget.storageKey!}');
        if (has != null && mounted) setState(() => _expanded = has);
      });
    }
  }

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (widget.storageKey != null) {
      final p = await SharedPreferences.getInstance();
      await p.setBool('cc_${widget.storageKey!}', _expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(.06),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: _expanded ? 'Recolher' : 'Expandir',
                      onPressed: _toggle,
                      icon: AnimatedRotation(
                        turns: _expanded ? 0 : 0.5, // gira 180° quando fechado
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 180),
                firstChild: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
                secondChild: const SizedBox(height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
