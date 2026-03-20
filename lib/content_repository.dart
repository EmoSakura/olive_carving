import 'dart:convert';

import 'package:flutter/services.dart';

import 'app_models.dart';

class LocalContentRepository {
  const LocalContentRepository();

  Future<AppContent> load() async {
    final rawJson = await rootBundle.loadString('assets/data/content.json');
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return AppContent.fromJson(decoded);
  }
}
