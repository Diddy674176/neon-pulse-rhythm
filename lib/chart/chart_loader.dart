import 'dart:convert';
import 'package:flutter/services.dart';
import 'chart_data.dart';

class ChartLoader {
  Future<ChartData> loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  ChartData loadFromString(String raw) {
    return ChartData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
