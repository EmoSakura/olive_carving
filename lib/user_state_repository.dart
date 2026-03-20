import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_models.dart';

class UserStateRepository {
  static const String _storageKey = 'olive_carving_user_state_v2';

  const UserStateRepository();

  Future<AppUserState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return AppUserState.empty();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppUserState.fromJson(decoded);
    } catch (_) {
      return AppUserState.empty();
    }
  }

  Future<void> save(AppUserState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(state.toJson()));
  }
}
