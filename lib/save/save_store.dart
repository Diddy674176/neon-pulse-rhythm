import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/game_settings.dart';

class SaveStore {
  static const _settingsKey = 'aether_settings_v1';
  static const _profileKey = 'aether_profile_v1';
  static const _scoresKey = 'aether_scores_v1';

  Future<GameSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return GameSettings();
    return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(GameSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
  }

  Future<Map<String, dynamic>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) {
      return {
        'displayName': 'Runner',
        'totalPlays': 0,
        'bestScore': 0,
        'favoriteSongId': 'circuit_mirage',
      };
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile));
  }

  Future<void> recordScore(String songId, Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoresKey);
    final map = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final prev = map[songId] as Map<String, dynamic>?;
    final best = (prev?['score'] as int? ?? 0);
    if ((result['score'] as int? ?? 0) >= best) {
      map[songId] = result;
      await prefs.setString(_scoresKey, jsonEncode(map));
    }
    final profile = await loadProfile();
    profile['totalPlays'] = (profile['totalPlays'] as int? ?? 0) + 1;
    final bs = profile['bestScore'] as int? ?? 0;
    if ((result['score'] as int? ?? 0) > bs) {
      profile['bestScore'] = result['score'];
    }
    await saveProfile(profile);
  }
}
