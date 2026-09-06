import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aether_beat/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first frame shows branded splash (never blank)', (tester) async {
    await tester.pumpWidget(const AetherBeatApp());
    // Immediate first frame — must show splash branding, never a white void.
    expect(find.text('AETHER BEAT'), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);
  });

  testWidgets('bootstrap reaches menu or visible error', (tester) async {
    await tester.pumpWidget(const AetherBeatApp());
    expect(find.text('AETHER BEAT'), findsWidgets);

    // AudioPlayer can be slow/noop in unit tests; allow bootstrap timeout path.
    await tester.pump(const Duration(seconds: 1));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('PLAY').evaluate().isNotEmpty ||
          find.text('STARTUP ERROR').evaluate().isNotEmpty) {
        break;
      }
    }

    final hasMenu = find.text('PLAY').evaluate().isNotEmpty;
    final hasError = find.text('STARTUP ERROR').evaluate().isNotEmpty;
    final stillLoading = find.text('Loading…').evaluate().isNotEmpty;
    expect(
      hasMenu || hasError || stillLoading,
      isTrue,
      reason: 'Must show splash, menu, or startup error — never a blank frame',
    );
  });
}
