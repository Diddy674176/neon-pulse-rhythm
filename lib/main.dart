import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens/main_menu_screen.dart';
import 'theme/aether_theme.dart';
import 'vfx/neon_palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Never show a blank red/white error rectangle without context.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: NeonPalette.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              'UI error\n${details.exceptionAsString()}',
              style: const TextStyle(
                color: NeonPalette.danger,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  };

  // Paint the first frame immediately — never await init before runApp.
  runApp(const AetherBeatApp());
}

class AetherBeatApp extends StatefulWidget {
  const AetherBeatApp({super.key});

  @override
  State<AetherBeatApp> createState() => _AetherBeatAppState();
}

class _AetherBeatAppState extends State<AetherBeatApp> {
  bool _loading = true;
  String? _fatalError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } catch (e) {
        // Orientation / system UI can fail on some embeds; non-fatal.
        debugPrint('SystemChrome setup skipped: $e');
      }

      await AppState.instance.init();

      if (!mounted) return;
      setState(() {
        _loading = false;
        _fatalError = null;
      });
    } catch (e, st) {
      debugPrint('Bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fatalError = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AETHER BEAT',
      debugShowCheckedModeBanner: false,
      theme: buildAetherTheme(),
      home: _loading
          ? const _BootSplash()
          : (_fatalError != null
              ? _BootError(message: _fatalError!, onRetry: _retry)
              : const MainMenuScreen()),
    );
  }

  void _retry() {
    setState(() {
      _loading = true;
      _fatalError = null;
    });
    _bootstrap();
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: NeonPalette.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AETHER BEAT',
              style: TextStyle(
                color: NeonPalette.text,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: NeonPalette.accent, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Loading…',
              style: TextStyle(color: NeonPalette.muted, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonPalette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'STARTUP ERROR',
                style: TextStyle(
                  color: NeonPalette.danger,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: NeonPalette.danger,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
