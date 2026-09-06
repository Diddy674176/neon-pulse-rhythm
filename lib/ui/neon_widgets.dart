import 'package:flutter/material.dart';
import '../vfx/neon_palette.dart';

class NeonPanel extends StatelessWidget {
  const NeonPanel({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonPalette.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonPalette.tileEdge, width: 1),
      ),
      child: child,
    );
  }
}

class NeonMenuButton extends StatelessWidget {
  const NeonMenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.accent = NeonPalette.text,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: filled
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonPalette.text,
                  foregroundColor: NeonPalette.bg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onPressed,
                child: _labelRow(NeonPalette.bg),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: NeonPalette.tileEdge, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  backgroundColor: NeonPalette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onPressed,
                child: _labelRow(accent),
              ),
      ),
    );
  }

  Widget _labelRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class SafeNeonScaffold extends StatelessWidget {
  const SafeNeonScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonPalette.bg,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: NeonPalette.text),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NeonPalette.text,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
