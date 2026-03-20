import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'backend_gateway.dart';
import 'product_models.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  final AppContent content;
  final AppUserState initialUserState;
  final BackendGateway backendGateway;
  final Future<void> Function(AppSession session) onSignedIn;

  const AuthScreen({
    super.key,
    required this.content,
    required this.initialUserState,
    required this.backendGateway,
    required this.onSignedIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(
    text: 'guest@olive.art',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'guest123',
  );
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _submitting = false;
  String? _errorText;
  String? _successText;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usingRemoteBackend = widget.backendGateway.isRemote;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17110D), Color(0xFF090909)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2B2118), Color(0xFF121212)],
                        ),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlphaValue(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'HERITAGE CLOUD CONSOLE',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '榄雕云艺',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '登录后进入更正式的产品主页、内容沉淀能力和管理入口。当前为本地模拟后台，可直接演示账号、会话与管理流程。',
                            style: TextStyle(
                              color: AppColors.textSecondary.withAlphaValue(
                                0.94,
                              ),
                              fontSize: 14,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _AuthFeatureChip(label: '本地会话持久化'),
                              _AuthFeatureChip(label: '管理员内容后台'),
                              _AuthFeatureChip(label: '产品化首页'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '演示登录',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '推荐先用访客账号看正式首页，再用管理员账号进入后台页。',
                            style: TextStyle(
                              color: AppColors.textSecondary.withAlphaValue(
                                0.9,
                              ),
                              fontSize: 13,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: usingRemoteBackend
                                  ? const Color(0xFF1E3327)
                                  : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              usingRemoteBackend
                                  ? '当前已连接 Supabase 真实后端，可使用真实账号登录。'
                                  : '当前未配置 Supabase，系统会自动回退到本地演示模式。你可以直接编辑 assets/config/supabase_config.json 填入项目 URL 和 Anon Key。',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                height: 1.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SegmentedButton<_AuthMode>(
                            segments: const [
                              ButtonSegment<_AuthMode>(
                                value: _AuthMode.signIn,
                                label: Text('登录'),
                                icon: Icon(Icons.login),
                              ),
                              ButtonSegment<_AuthMode>(
                                value: _AuthMode.signUp,
                                label: Text('注册'),
                                icon: Icon(Icons.person_add_alt_1),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _mode = selection.first;
                                _errorText = null;
                                _successText = null;
                                if (_mode == _AuthMode.signUp) {
                                  _emailController.text = '';
                                  _passwordController.text = '';
                                  _confirmPasswordController.text = '';
                                  _displayNameController.text = '';
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _AuthPresetCard(
                                  title: '访客账号',
                                  subtitle: '查看完整产品流',
                                  credential: 'guest@olive.art / guest123',
                                  onTap: () {
                                    setState(() {
                                      _mode = _AuthMode.signIn;
                                      _emailController.text = 'guest@olive.art';
                                      _passwordController.text = 'guest123';
                                      _confirmPasswordController.text =
                                          'guest123';
                                      _displayNameController.text = '访客用户';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AuthPresetCard(
                                  title: '管理员账号',
                                  subtitle: '进入内容后台',
                                  credential: 'admin@olive.art / admin123',
                                  onTap: () {
                                    setState(() {
                                      _mode = _AuthMode.signIn;
                                      _emailController.text = 'admin@olive.art';
                                      _passwordController.text = 'admin123';
                                      _confirmPasswordController.text =
                                          'admin123';
                                      _displayNameController.text = '项目管理员';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_mode == _AuthMode.signUp) ...[
                            TextField(
                              controller: _displayNameController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                labelText: '昵称',
                                hintText: '请输入展示名称',
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (usingRemoteBackend)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Text(
                                  '如果注册后没有自动进入系统，通常是 Supabase 开启了邮箱确认。先到邮件里完成验证，再回来登录即可。',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.7,
                                  ),
                                ),
                              ),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: '邮箱账号',
                              hintText: '请输入演示账号',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: '密码',
                              hintText: '请输入演示密码',
                            ),
                          ),
                          if (_mode == _AuthMode.signUp) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                labelText: '确认密码',
                                hintText: '请再次输入密码',
                              ),
                            ),
                          ],
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _errorText!,
                              style: const TextStyle(
                                color: Color(0xFFF08A7A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (_successText != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _successText!,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                height: 1.7,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting
                                  ? null
                                  : (_mode == _AuthMode.signIn
                                        ? _submitSignIn
                                        : _submitSignUp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                              ),
                              child: Text(
                                _submitting
                                    ? (_mode == _AuthMode.signIn
                                          ? '登录中...'
                                          : '注册中...')
                                    : (_mode == _AuthMode.signIn
                                          ? '进入产品'
                                          : '注册账号'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorText = null;
      _successText = null;
    });

    try {
      final session = await widget.backendGateway.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      await widget.onSignedIn(session);
    } on SignInFailure catch (error) {
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      setState(() {
        _errorText = '登录失败，请稍后重试。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _submitSignIn() => _submit();

  Future<void> _submitSignUp() async {
    if (_displayNameController.text.trim().isEmpty) {
      setState(() {
        _errorText = '请输入昵称。';
      });
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorText = '密码至少需要 6 位。';
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorText = '两次输入的密码不一致。';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
      _successText = null;
    });

    try {
      final result = await widget.backendGateway.signUp(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      if (result.session != null) {
        await widget.onSignedIn(result.session!);
        return;
      }
      setState(() {
        _successText = result.message;
        _mode = _AuthMode.signIn;
      });
    } on SignInFailure catch (error) {
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      setState(() {
        _errorText = '注册失败，请稍后重试。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _AuthFeatureChip extends StatelessWidget {
  final String label;

  const _AuthFeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}

class _AuthPresetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String credential;
  final VoidCallback onTap;

  const _AuthPresetCard({
    required this.title,
    required this.subtitle,
    required this.credential,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.accent, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                credential,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
