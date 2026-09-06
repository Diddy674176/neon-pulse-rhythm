import 'package:flutter/material.dart';
import '../app_state.dart';
import '../ui/neon_widgets.dart';
import '../vfx/neon_palette.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    AppState.instance.save.loadProfile().then((p) {
      if (mounted) setState(() => profile = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return SafeNeonScaffold(
      title: 'PROFILE',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: NeonPanel(
          child: p == null
              ? const Center(child: CircularProgressIndicator(color: NeonPalette.accent))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['displayName']}',
                      style: const TextStyle(
                        color: NeonPalette.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Total plays: ${p['totalPlays']}',
                        style: const TextStyle(color: NeonPalette.text)),
                    Text('Best score: ${p['bestScore']}',
                        style: const TextStyle(color: NeonPalette.text)),
                    Text('Favorite: ${p['favoriteSongId']}',
                        style: const TextStyle(color: NeonPalette.muted)),
                  ],
                ),
        ),
      ),
    );
  }
}
