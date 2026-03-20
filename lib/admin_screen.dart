import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'product_models.dart';

class AdminScreen extends StatelessWidget {
  final AdminWorkspace workspace;
  final List<Exhibit> exhibits;
  final ValueChanged<ManagedExhibitState> onUpdateExhibitState;

  const AdminScreen({
    super.key,
    required this.workspace,
    required this.exhibits,
    required this.onUpdateExhibitState,
  });

  @override
  Widget build(BuildContext context) {
    final publishedCount = exhibits
        .where((item) => workspace.stateFor(item.id).published)
        .length;
    final featuredCount = exhibits
        .where((item) => workspace.stateFor(item.id).featured)
        .length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 176,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            title: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '管理后台',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF261D16), Color(0xFF0F0F0F)],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '这里是本地模拟后台，后续替换成真实 API 后，可继续沿用这套发布状态与精选位的管理方式。',
                  style: TextStyle(
                    color: AppColors.textSecondary.withAlphaValue(0.92),
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AdminMetricCard(
                        label: '已发布展品',
                        value: '$publishedCount',
                        hint: '对外可见内容',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AdminMetricCard(
                        label: '首页精选',
                        value: '$featuredCount',
                        hint: '首页焦点内容',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AdminMetricCard(
                        label: '内容总量',
                        value: '${exhibits.length}',
                        hint: '当前库内作品',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          sliver: SliverList.builder(
            itemCount: exhibits.length,
            itemBuilder: (context, index) {
              final exhibit = exhibits[index];
              final state = workspace.stateFor(exhibit.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdminExhibitCard(
                  exhibit: exhibit,
                  state: state,
                  onTogglePublished: () {
                    onUpdateExhibitState(
                      state.copyWith(published: !state.published),
                    );
                  },
                  onToggleFeatured: () {
                    onUpdateExhibitState(
                      state.copyWith(featured: !state.featured),
                    );
                  },
                  onTagChanged: (value) {
                    onUpdateExhibitState(state.copyWith(adminTag: value));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _AdminMetricCard({
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

class _AdminExhibitCard extends StatelessWidget {
  final Exhibit exhibit;
  final ManagedExhibitState state;
  final VoidCallback onTogglePublished;
  final VoidCallback onToggleFeatured;
  final ValueChanged<String> onTagChanged;

  const _AdminExhibitCard({
    required this.exhibit,
    required this.state,
    required this.onTogglePublished,
    required this.onToggleFeatured,
    required this.onTagChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  exhibit.image,
                  width: 68,
                  height: 68,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${exhibit.category} · ${exhibit.technique}',
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '发布',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  value: state.published,
                  onChanged: (_) => onTogglePublished(),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '首页精选',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  value: state.featured,
                  onChanged: (_) => onToggleFeatured(),
                ),
              ),
            ],
          ),
          TextFormField(
            initialValue: state.adminTag,
            onFieldSubmitted: onTagChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: '后台标记',
              hintText: '例如：首页精选 / 推荐上新 / 教学重点',
            ),
          ),
        ],
      ),
    );
  }
}
