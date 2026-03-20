import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_models.dart';
import 'product_models.dart';

class SignInFailure implements Exception {
  final String message;

  const SignInFailure(this.message);

  @override
  String toString() => message;
}

class SignUpResult {
  final AppSession? session;
  final bool requiresEmailConfirmation;
  final String message;

  const SignUpResult({
    required this.session,
    required this.requiresEmailConfirmation,
    required this.message,
  });
}

abstract class BackendGateway {
  bool get isRemote;

  Future<AppSession?> restoreSession();
  Future<AppSession> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<AdminWorkspace> loadAdminWorkspace(List<Exhibit> exhibits);
  Future<void> saveAdminWorkspace(AdminWorkspace workspace);
}

class BackendConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;

  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}

class BackendConfigLoader {
  static const String _assetPath = 'assets/config/supabase_config.json';

  static Future<BackendConfig> load() async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final envConfig = BackendConfig(
      supabaseUrl: envUrl,
      supabaseAnonKey: envAnonKey,
    );
    if (envConfig.isConfigured) {
      return envConfig;
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return BackendConfig(
        supabaseUrl: decoded['supabaseUrl'] as String? ?? '',
        supabaseAnonKey: decoded['supabaseAnonKey'] as String? ?? '',
      );
    } catch (_) {
      return const BackendConfig(supabaseUrl: '', supabaseAnonKey: '');
    }
  }
}

BackendGateway createBackendGateway(BackendConfig config) {
  if (config.isConfigured) {
    return const SupabaseBackendGateway();
  }
  return const MockBackendGateway();
}

class MockBackendGateway implements BackendGateway {
  static const String _sessionKey = 'olive_carving_session_v1';
  static const String _adminWorkspaceKey = 'olive_carving_admin_workspace_v1';

  const MockBackendGateway();

  @override
  bool get isRemote => false;

  @override
  Future<AppSession?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppSession> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    late final AppSession session;
    if (email.trim().toLowerCase() == 'admin@olive.art' &&
        password == 'admin123') {
      session = const AppSession(
        userId: 'admin_001',
        displayName: '项目管理员',
        email: 'admin@olive.art',
        role: UserRole.admin,
      );
    } else if (email.trim().toLowerCase() == 'guest@olive.art' &&
        password == 'guest123') {
      session = const AppSession(
        userId: 'visitor_001',
        displayName: '访客用户',
        email: 'guest@olive.art',
        role: UserRole.visitor,
      );
    } else {
      throw const SignInFailure('账号或密码不正确，请使用演示账号登录。');
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final normalizedEmail = email.trim().toLowerCase();
    final session = AppSession(
      userId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName.trim().isEmpty ? '新用户' : displayName.trim(),
      email: normalizedEmail,
      role: normalizedEmail == 'admin@olive.art'
          ? UserRole.admin
          : UserRole.visitor,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    return const SignUpResult(
      session: null,
      requiresEmailConfirmation: false,
      message: '本地演示模式下，注册功能仅用于界面演示，请直接使用演示账号登录。',
    );
  }

  @override
  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  @override
  Future<AdminWorkspace> loadAdminWorkspace(List<Exhibit> exhibits) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_adminWorkspaceKey);
    if (raw == null || raw.isEmpty) {
      final seeded = AdminWorkspace.seeded(exhibits);
      await saveAdminWorkspace(seeded);
      return seeded;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final workspace = AdminWorkspace.fromJson(decoded);
      if (workspace.exhibitStates.length < exhibits.length) {
        final patched = _mergeWithSeeded(workspace, exhibits);
        await saveAdminWorkspace(patched);
        return patched;
      }
      return workspace;
    } catch (_) {
      final seeded = AdminWorkspace.seeded(exhibits);
      await saveAdminWorkspace(seeded);
      return seeded;
    }
  }

  @override
  Future<void> saveAdminWorkspace(AdminWorkspace workspace) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _adminWorkspaceKey,
      jsonEncode(workspace.toJson()),
    );
  }

  AdminWorkspace _mergeWithSeeded(
    AdminWorkspace current,
    List<Exhibit> exhibits,
  ) {
    var merged = current;
    for (int i = 0; i < exhibits.length; i++) {
      final exhibit = exhibits[i];
      if (!current.exhibitStates.containsKey(exhibit.id)) {
        merged = merged.update(ManagedExhibitState.seeded(exhibit, i));
      }
    }
    return merged;
  }
}

class SupabaseBackendGateway implements BackendGateway {
  const SupabaseBackendGateway();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  bool get isRemote => true;

  @override
  Future<AppSession?> restoreSession() async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;
    if (session == null || user == null) {
      return null;
    }
    return _mapUserToSession(user);
  }

  @override
  Future<AppSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const SignInFailure('登录成功但未获取到用户信息。');
      }
      return _mapUserToSession(user);
    } on AuthException catch (error) {
      throw SignInFailure(error.message);
    } catch (_) {
      throw const SignInFailure('Supabase 登录失败，请检查项目配置。');
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName.trim(), 'role': 'visitor'},
      );
      final user = response.user;
      final session = response.session;
      if (user == null) {
        throw const SignInFailure('注册成功但未获取到用户信息。');
      }

      if (session == null) {
        return const SignUpResult(
          session: null,
          requiresEmailConfirmation: true,
          message: '注册成功，请先到邮箱中完成验证后再登录。',
        );
      }

      return SignUpResult(
        session: _mapUserToSession(user),
        requiresEmailConfirmation: false,
        message: '注册成功，已自动登录。',
      );
    } on AuthException catch (error) {
      throw SignInFailure(error.message);
    } catch (_) {
      throw const SignInFailure('注册失败，请检查邮箱格式或项目认证设置。');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<AdminWorkspace> loadAdminWorkspace(List<Exhibit> exhibits) async {
    try {
      final rows = await _client
          .from('managed_exhibits')
          .select('exhibit_id, featured, published, admin_tag');

      final list = (rows as List<dynamic>)
          .map(
            (item) =>
                ManagedExhibitState.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (list.isEmpty) {
        final seeded = AdminWorkspace.seeded(exhibits);
        await saveAdminWorkspace(seeded);
        return seeded;
      }

      final workspace = AdminWorkspace(
        exhibitStates: {for (final item in list) item.exhibitId: item},
      );
      if (workspace.exhibitStates.length < exhibits.length) {
        final patched = _mergeWithSeeded(workspace, exhibits);
        await saveAdminWorkspace(patched);
        return patched;
      }
      return workspace;
    } catch (_) {
      return AdminWorkspace.seeded(exhibits);
    }
  }

  @override
  Future<void> saveAdminWorkspace(AdminWorkspace workspace) async {
    final payload = workspace.exhibitStates.values
        .map((item) => item.toJson())
        .toList();
    await _client
        .from('managed_exhibits')
        .upsert(payload, onConflict: 'exhibit_id');
  }

  AppSession _mapUserToSession(User user) {
    final metadata = {...?user.userMetadata, ...user.appMetadata};
    final roleName = metadata['role'] as String?;
    final role = UserRole.values.firstWhere(
      (item) => item.name == roleName,
      orElse: () =>
          user.email == 'admin@olive.art' ? UserRole.admin : UserRole.visitor,
    );
    final displayName =
        metadata['display_name'] as String? ??
        metadata['name'] as String? ??
        user.email?.split('@').first ??
        '用户';
    return AppSession(
      userId: user.id,
      displayName: displayName,
      email: user.email ?? '',
      role: role,
    );
  }

  AdminWorkspace _mergeWithSeeded(
    AdminWorkspace current,
    List<Exhibit> exhibits,
  ) {
    var merged = current;
    for (int i = 0; i < exhibits.length; i++) {
      final exhibit = exhibits[i];
      if (!current.exhibitStates.containsKey(exhibit.id)) {
        merged = merged.update(ManagedExhibitState.seeded(exhibit, i));
      }
    }
    return merged;
  }
}
