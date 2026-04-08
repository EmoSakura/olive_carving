import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'experience_insights.dart';
import 'product_models.dart';

class HomeScreen extends StatelessWidget {
  final AppSession session;
  final AppContent content;
  final AppUserState userState;
  final AdminWorkspace adminWorkspace;
  final bool isRemoteBackend;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenProcess;
  final VoidCallback onOpenInteraction;
  final VoidCallback onOpenService;
  final VoidCallback onOpenAdmin;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.session,
    required this.content,
    required this.userState,
    required this.adminWorkspace,
    required this.isRemoteBackend,
    required this.onOpenGallery,
    required this.onOpenProcess,
    required this.onOpenInteraction,
    required this.onOpenService,
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

  Exhibit? _findExhibitById(Iterable<Exhibit> exhibits, String id) {
    for (final exhibit in exhibits) {
      if (exhibit.id == id) {
        return exhibit;
      }
    }
    return null;
  }

  Exhibit? _coverExhibitFor(FeaturedCollection collection) {
    for (final exhibitId in collection.exhibitIds) {
      final publishedMatch = _findExhibitById(_publishedExhibits, exhibitId);
      if (publishedMatch != null) {
        return publishedMatch;
      }
    }
    for (final exhibitId in collection.exhibitIds) {
      final fallbackMatch = _findExhibitById(content.exhibits, exhibitId);
      if (fallbackMatch != null) {
        return fallbackMatch;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final insights = ExperienceInsights.fromState(
      content: content,
      userState: userState,
      adminWorkspace: adminWorkspace,
    );
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionReveal(
                  delayMs: 40,
                  child: _HomeHeroCard(
                    session: session,
                    insights: insights,
                    featuredQuote: content.featuredQuote,
                    isRemoteBackend: isRemoteBackend,
                    publishedCount: _publishedExhibits.length,
                    featuredCount: _featuredExhibits.length,
                    onOpenGallery: onOpenGallery,
                    onOpenService: onOpenService,
                    onLogout: onLogout,
                  ),
                ),
                const SizedBox(height: 18),
                _SectionReveal(
                  delayMs: 110,
                  child: Row(
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
                          label: '学习进度',
                          value:
                              '${(insights.learningProgress * 100).round()}%',
                          hint: '工艺阅读沉淀',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeMetricCard(
                          label: '转化线索',
                          value: '${userState.serviceInquiries.length}',
                          hint: '服务登记入口',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionReveal(
                  delayMs: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          _QuickActionCard(
                            title: '服务中心',
                            subtitle: '课程、展陈与品牌合作入口',
                            icon: Icons.workspaces_outline,
                            onTap: onOpenService,
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
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionReveal(
                  delayMs: 250,
                  child: _RecommendationCard(
                    insights: insights,
                    content: content,
                    onOpenGallery: onOpenGallery,
                    onOpenService: onOpenService,
                  ),
                ),
                if (content.featuredCollections.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionReveal(
                    delayMs: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '策展路线',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 280,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: content.featuredCollections.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final item = content.featuredCollections[index];
                              return _SectionReveal(
                                delayMs: 360 + index * 60,
                                offsetY: 18,
                                child: _CollectionCard(
                                  item: item,
                                  coverExhibit: _coverExhibitFor(item),
                                  recommended:
                                      insights.recommendedCollection?.id ==
                                      item.id,
                                  onTap: onOpenGallery,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _SectionReveal(
                  delayMs: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            return _SectionReveal(
                              delayMs: 450 + index * 70,
                              offsetY: 24,
                              child: _FeaturedExhibitCard(
                                exhibit: exhibit,
                                tag: adminWorkspace
                                    .stateFor(exhibit.id)
                                    .adminTag,
                                onTap: onOpenGallery,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_recentExhibits.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _SectionReveal(
                    delayMs: 520,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '继续浏览',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._recentExhibits.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SectionReveal(
                              delayMs: 560 + entry.key * 40,
                              offsetY: 16,
                              child: _RecentExhibitRow(
                                exhibit: entry.value,
                                onTap: onOpenGallery,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (content.timeline.isNotEmpty) ...[
                  _SectionReveal(
                    delayMs: 620,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '品牌时间线',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 188,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: content.timeline.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) => _SectionReveal(
                              delayMs: 660 + index * 45,
                              offsetY: 16,
                              child: _TimelineCard(
                                item: content.timeline[index],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                _SectionReveal(
                  delayMs: 740,
                  child: _ServicePreviewCard(
                    inquiryCount: userState.serviceInquiries.length,
                    latestInquiry: insights.latestInquiry,
                    dominantCategory: insights.dominantCategory,
                    onOpenService: onOpenService,
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
  final ExperienceInsights insights;
  final String featuredQuote;
  final bool isRemoteBackend;
  final int publishedCount;
  final int featuredCount;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenService;
  final VoidCallback onLogout;

  const _HomeHeroCard({
    required this.session,
    required this.insights,
    required this.featuredQuote,
    required this.isRemoteBackend,
    required this.publishedCount,
    required this.featuredCount,
    required this.onOpenGallery,
    required this.onOpenService,
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
      child: Stack(
        children: [
          const Positioned.fill(child: _HeroAtmosphere()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroPill(
                    label: isRemoteBackend
                        ? 'SUPABASE CONNECTED'
                        : 'LOCAL EXPERIENCE',
                  ),
                  const SizedBox(width: 10),
                  _HeroPill(label: insights.stageLabel.toUpperCase()),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('退出登录'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.96, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    alignment: Alignment.centerLeft,
                    child: child,
                  );
                },
                child: Text(
                  '你好，${session.displayName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '这不是普通毕业设计首页，而是一张带策展逻辑、进度沉淀和服务入口的文化产品主屏。',
                style: TextStyle(
                  color: AppColors.textSecondary.withAlphaValue(0.94),
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlphaValue(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前已发布展品 $publishedCount 件，首页精选 $featuredCount 件，偏好题材为 ${insights.dominantCategory}。',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      insights.stageSummary,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      featuredQuote,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onOpenGallery,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('进入推荐路线'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenService,
                    icon: const Icon(Icons.workspaces_outline),
                    label: const Text('查看服务中心'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Colors.white12),
                    ),
                  ),
                ],
              ),
            ],
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

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlphaValue(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ExperienceInsights insights;
  final AppContent content;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenService;

  const _RecommendationCard({
    required this.insights,
    required this.content,
    required this.onOpenGallery,
    required this.onOpenService,
  });

  @override
  Widget build(BuildContext context) {
    final collection = insights.recommendedCollection;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlphaValue(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '为你推荐',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '参与度 ${insights.engagementScore}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            collection?.title ?? '先从首页精选开始建立观看节奏',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insights.recommendationReason,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.8,
            ),
          ),
          if (collection != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${collection.subtitle}\n\n${collection.highlight}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.8,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onOpenGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('进入展馆'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenService,
                icon: const Icon(Icons.trending_up_outlined),
                label: const Text('进入服务中心'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final FeaturedCollection item;
  final Exhibit? coverExhibit;
  final bool recommended;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.item,
    required this.coverExhibit,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: recommended
                    ? [const Color(0xFF4A381F), const Color(0xFF1C1814)]
                    : [const Color(0xFF2A211B), AppColors.surface],
              ),
              border: Border.all(
                color: recommended ? AppColors.accent : Colors.white10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverExhibit != null)
                          Image.asset(
                            coverExhibit!.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _CollectionCoverFallback(
                                icon: Icons.photo_outlined,
                              );
                            },
                          )
                        else
                          const _CollectionCoverFallback(
                            icon: Icons.photo_outlined,
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.52),
                              ],
                            ),
                          ),
                        ),
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
                              recommended
                                  ? '推荐路线'
                                  : '${item.exhibitIds.length} 件重点展品',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Text(
                            coverExhibit?.title ?? '策展封面待补充',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              recommended
                                  ? Icons.auto_awesome
                                  : Icons.north_east,
                              color: recommended
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.highlight,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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

class _CollectionCoverFallback extends StatelessWidget {
  final IconData icon;

  const _CollectionCoverFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2D21), AppColors.surface],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.accent, size: 34),
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
                        Image.asset(
                          exhibit.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surfaceSoft,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.museum_outlined,
                                color: AppColors.accent,
                                size: 36,
                              ),
                            );
                          },
                        ),
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
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.asset(
                    exhibit.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surfaceSoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.museum_outlined,
                          color: AppColors.accent,
                        ),
                      );
                    },
                  ),
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

class _TimelineCard extends StatelessWidget {
  final TimelineMilestone item;

  const _TimelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.year,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.summary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicePreviewCard extends StatelessWidget {
  final int inquiryCount;
  final ServiceInquiry? latestInquiry;
  final String dominantCategory;
  final VoidCallback onOpenService;

  const _ServicePreviewCard({
    required this.inquiryCount,
    required this.latestInquiry,
    required this.dominantCategory,
    required this.onOpenService,
  });

  @override
  Widget build(BuildContext context) {
    final headline = latestInquiry == null
        ? '你的内容体验已经形成偏好，可以继续推进成方案演示。'
        : '最近一条需求已沉淀到本地档案，可继续扩展为更完整的提案材料。';
    final detail = latestInquiry == null
        ? '当前偏好集中在 $dominantCategory，可直接从课程、展陈或品牌合作包里选择一个方向进入。'
        : '最近登记：${latestInquiry!.packageTitle} · ${latestInquiry!.budget}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2118), Color(0xFF181818)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inquiryCount == 0 ? '服务转化入口' : '已沉淀的合作线索',
            style: TextStyle(
              color: AppColors.accent.withAlphaValue(0.96),
              fontSize: 12,
              letterSpacing: 2.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenService,
            icon: const Icon(Icons.arrow_forward),
            label: Text(inquiryCount == 0 ? '开始登记需求' : '继续完善需求'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;

  const _SectionReveal({
    required this.child,
    required this.delayMs,
    this.offsetY = 28,
  });

  @override
  State<_SectionReveal> createState() => _SectionRevealState();
}

class _SectionRevealState extends State<_SectionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _HeroAtmosphere extends StatefulWidget {
  const _HeroAtmosphere();

  @override
  State<_HeroAtmosphere> createState() => _HeroAtmosphereState();
}

class _HeroAtmosphereState extends State<_HeroAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: -50 + value * 22,
                right: -20 + value * 28,
                child: _GlowOrb(
                  size: 170,
                  color: AppColors.accent.withAlphaValue(0.12),
                ),
              ),
              Positioned(
                left: -30 + value * 16,
                bottom: -42 + value * 18,
                child: _GlowOrb(
                  size: 140,
                  color: const Color(0xFF8B6442).withAlphaValue(0.18),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _HeroLinePainter(progress: value)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlphaValue(0)]),
      ),
    );
  }
}

class _HeroLinePainter extends CustomPainter {
  final double progress;

  const _HeroLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlphaValue(0.06)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.2 + i * 0.16);
      path.reset();
      path.moveTo(-20, y);
      for (double x = 0; x <= size.width + 30; x += 24) {
        final wave = math.sin((x / 42) + progress * math.pi * 2 + i * 0.8) * 10;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
