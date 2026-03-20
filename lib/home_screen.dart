import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'product_models.dart';

class HomeScreen extends StatelessWidget {
  final AppSession session;
  final AppContent content;
  final AppUserState userState;
  final AdminWorkspace adminWorkspace;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenProcess;
  final VoidCallback onOpenInteraction;
  final VoidCallback onOpenAdmin;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.session,
    required this.content,
    required this.userState,
    required this.adminWorkspace,
    required this.onOpenGallery,
    required this.onOpenProcess,
    required this.onOpenInteraction,
    required this.onOpenAdmin,
    required this.onLogout,
  });

  List<Exhibit> get _publishedExhibits => content.exhibits
      .where((item) => adminWorkspace.stateFor(item.id).published)
      .toList();

  List<Exhibit> get _featuredExhibits {
    final featured = _publishedExhibits
        .where((item) => adminWorkspace.stateFor(item.id).featured)
        .toList();
    return featured.isEmpty ? _publishedExhibits.take(3).toList() : featured;
  }

  List<Exhibit> get _recentExhibits => userState.recentExhibitIds
      .map(
        (id) => _publishedExhibits.cast<Exhibit?>().firstWhere(
          (item) => item?.id == id,
          orElse: () => null,
        ),
      )
      .whereType<Exhibit>()
      .toList();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeroCard(
                  session: session,
                  publishedCount: _publishedExhibits.length,
                  featuredCount: _featuredExhibits.length,
                  onLogout: onLogout,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HomeMetricCard(
                        label: '馆藏可见',
                        value: '${_publishedExhibits.length}',
                        hint: '后台可控发布',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeMetricCard(
                        label: '我的收藏',
                        value: '${userState.favoriteExhibitIds.length}',
                        hint: '跨会话保留',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeMetricCard(
                        label: '已归档作品',
                        value: '${userState.carvingHistory.length}',
                        hint: '互动沉淀',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '快速进入',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionCard(
                      title: '进入展馆',
                      subtitle: '浏览全部展品与作品细节',
                      icon: Icons.photo_library_outlined,
                      onTap: onOpenGallery,
                    ),
                    _QuickActionCard(
                      title: '继续学习',
                      subtitle: '工艺步骤与阅读进度',
                      icon: Icons.layers_outlined,
                      onTap: onOpenProcess,
                    ),
                    _QuickActionCard(
                      title: '开始创作',
                      subtitle: '进入指尖互动工作台',
                      icon: Icons.gesture_outlined,
                      onTap: onOpenInteraction,
                    ),
                    if (session.role == UserRole.admin)
                      _QuickActionCard(
                        title: '管理后台',
                        subtitle: '内容状态与发布控制',
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: onOpenAdmin,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  '首页精选',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredExhibits.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final exhibit = _featuredExhibits[index];
                      return _FeaturedExhibitCard(
                        exhibit: exhibit,
                        tag: adminWorkspace.stateFor(exhibit.id).adminTag,
                        onTap: onOpenGallery,
                      );
                    },
                  ),
                ),
                if (_recentExhibits.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    '继续浏览',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._recentExhibits.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentExhibitRow(
                        exhibit: item,
                        onTap: onOpenGallery,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '产品状态',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '当前版本已具备登录会话、本地后台模拟、内容发布状态控制与首页内容编排能力。后续如果接真实服务端，可直接把本地模拟网关替换成线上 API。',
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlphaValue(0.92),
                          fontSize: 13,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  final AppSession session;
  final int publishedCount;
  final int featuredCount;
  final VoidCallback onLogout;

  const _HomeHeroCard({
    required this.session,
    required this.publishedCount,
    required this.featuredCount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2218), Color(0xFF121212)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  session.role == UserRole.admin
                      ? 'ADMIN CONSOLE'
                      : 'PRODUCT HOME',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('退出登录'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '你好，${session.displayName}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '榄雕云艺已经从答辩原型升级为更接近正式产品的内容应用：有首页、有会话、有后台、有内容编排能力。',
            style: TextStyle(
              color: AppColors.textSecondary.withAlphaValue(0.94),
              fontSize: 14,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '当前已发布展品 $publishedCount 件，首页精选 $featuredCount 件，可继续浏览、学习或进入创作工作台。',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _HomeMetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlphaValue(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.6,
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
    );
  }
}

class _FeaturedExhibitCard extends StatelessWidget {
  final Exhibit exhibit;
  final String tag;
  final VoidCallback onTap;

  const _FeaturedExhibitCard({
    required this.exhibit,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(exhibit.image, fit: BoxFit.cover),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exhibit.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${exhibit.era} · ${exhibit.technique}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
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
    );
  }
}

class _RecentExhibitRow extends StatelessWidget {
  final Exhibit exhibit;
  final VoidCallback onTap;

  const _RecentExhibitRow({required this.exhibit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  exhibit.image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exhibit.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exhibit.story,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
