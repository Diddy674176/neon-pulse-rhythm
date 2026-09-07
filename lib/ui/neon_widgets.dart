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

class NeonMenuButton extends StatefulWidget {
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
  State<NeonMenuButton> createState() => _NeonMenuButtonState();
}

class _NeonMenuButtonState extends State<NeonMenuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? 0.97 : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: Listener(
            onPointerDown: (_) => setState(() => _down = true),
            onPointerUp: (_) => setState(() => _down = false),
            onPointerCancel: (_) => setState(() => _down = false),
            child: widget.filled
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
                    onPressed: widget.onPressed,
                    child: _labelRow(NeonPalette.bg),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.accent,
                      side: BorderSide(
                        color: _down ? NeonPalette.accent : NeonPalette.tileEdge,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      backgroundColor: _down ? NeonPalette.bgElevated : NeonPalette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.onPressed,
                    child: _labelRow(widget.accent),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _labelRow(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: color, size: 22),
          const SizedBox(width: 10),
        ],
        Text(
          widget.label,
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

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.accent = NeonPalette.accent,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: NeonPalette.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NeonPalette.tileEdge),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: NeonPalette.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeonPalette.tileEdge),
                  ),
                  child: Icon(Icons.music_note_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: NeonPalette.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: NeonPalette.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: NeonPalette.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: NeonPalette.tileEdge),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: NeonPalette.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow_rounded, color: NeonPalette.muted, size: 28),
              ],
            ),
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
