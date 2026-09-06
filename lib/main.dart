import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens/main_menu_screen.dart';
import 'theme/aether_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await AppState.instance.init();
  runApp(const AetherBeatApp());
}

class AetherBeatApp extends StatelessWidget {
  const AetherBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AETHER BEAT',
      debugShowCheckedModeBanner: false,
      theme: buildAetherTheme(),
      home: const MainMenuScreen(),
    );
  }
}
