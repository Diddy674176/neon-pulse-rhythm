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
        color: NeonPalette.bgElevated.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonPalette.cyan.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: NeonPalette.magenta.withOpacity(0.15),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
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
    this.accent = NeonPalette.cyan,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            backgroundColor: accent.withOpacity(0.08),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
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
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14082C), NeonPalette.bg, Color(0xFF03060C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: NeonPalette.cyan),
                        ),
                      Expanded(
                        child: Text(
                          title!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: NeonPalette.cyan,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontSize: 18,
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
      ),
    );
  }
}
