import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'product_models.dart';

class AdminScreen extends StatelessWidget {
  final AdminWorkspace workspace;
  final List<Exhibit> exhibits;
  final List<ServiceInquiry> inquiries;
  final ValueChanged<ManagedExhibitState> onUpdateExhibitState;
  final ValueChanged<ServiceInquiry> onUpdateInquiry;

  const AdminScreen({
    super.key,
    required this.workspace,
    required this.exhibits,
    required this.inquiries,
    required this.onUpdateExhibitState,
    required this.onUpdateInquiry,
  });

  int get _publishedCount =>
      exhibits.where((item) => workspace.stateFor(item.id).published).length;

  int get _featuredCount =>
      exhibits.where((item) => workspace.stateFor(item.id).featured).length;

  int get _activeDealCount => inquiries
      .where(
        (item) =>
            item.stage == InquiryStage.qualified ||
            item.stage == InquiryStage.proposal ||
            item.stage == InquiryStage.negotiating,
      )
      .length;

  int get _wonCount =>
      inquiries.where((item) => item.stage == InquiryStage.won).length;

  int get _strategicCount => inquiries
      .where((item) => item.priority == InquiryPriority.strategic)
      .length;

  int get _reminderCount => inquiries
      .where(
        (item) =>
            item.reminderAt != null &&
            item.reminderAt!.isBefore(DateTime.now()) &&
            item.stage != InquiryStage.won &&
            item.stage != InquiryStage.lost,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 188,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            title: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '运营后台',
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C2218), Color(0xFF151515)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '从内容后台升级为商务运营台',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '这里不只管理展品发布，也管理合作线索、方案推进和成交状态，更接近真实产品后台。',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '当前已发布 $_publishedCount 件展品，其中首页精选 $_featuredCount 件；正在管理 ${inquiries.length} 条合作线索，其中战略级 $_strategicCount 条。',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AdminMetricCard(
                        label: '展品已发布',
                        value: '$_publishedCount',
                        hint: '前台可见内容',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AdminMetricCard(
                        label: '商务推进中',
                        value: '$_activeDealCount',
                        hint: '已进入方案或沟通',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AdminMetricCard(
                        label: '已成交',
                        value: '$_wonCount',
                        hint: '可作为案例沉淀',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AdminMetricCard(
                        label: '待跟进提醒',
                        value: '$_reminderCount',
                        hint: '已到提醒时间',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '商务线索漏斗',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '共 ${inquiries.length} 条线索',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 380,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final stage = InquiryStage.values[index];
                final stageItems = inquiries
                    .where((item) => item.stage == stage)
                    .toList();
                return _StageColumn(
                  stage: stage,
                  items: stageItems,
                  onAdvance: (item) => _stepStage(item, forward: true),
                  onRollback: (item) => _stepStage(item, forward: false),
                  onEdit: (item) => _showInquirySheet(context, item),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemCount: InquiryStage.values.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: const Text(
              '内容运营',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
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

  void _stepStage(ServiceInquiry inquiry, {required bool forward}) {
    final stages = InquiryStage.values;
    final currentIndex = stages.indexOf(inquiry.stage);
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = (forward ? currentIndex + 1 : currentIndex - 1).clamp(
      0,
      stages.length - 1,
    );
    if (nextIndex == currentIndex) {
      return;
    }
    onUpdateInquiry(
      inquiry.copyWith(stage: stages[nextIndex], lastUpdatedAt: DateTime.now()),
    );
  }

  void _showInquirySheet(BuildContext context, ServiceInquiry inquiry) {
    final nextActionController = TextEditingController(
      text: inquiry.nextAction,
    );
    final noteController = TextEditingController(text: inquiry.adminNote);
    final ownerController = TextEditingController(text: inquiry.ownerName);
    final proposalController = TextEditingController(
      text: inquiry.proposalTitle,
    );
    final estimatedValueController = TextEditingController(
      text: inquiry.estimatedValue,
    );
    var priority = inquiry.priority;
    var stage = inquiry.stage;
    var reminderAt = inquiry.reminderAt;
    final followUps = List<InquiryFollowUp>.from(inquiry.followUps);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Text(
                        inquiry.organization.isEmpty
                            ? inquiry.packageTitle
                            : inquiry.organization,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${inquiry.packageTitle} · ${inquiry.budget}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<InquiryStage>(
                        initialValue: stage,
                        decoration: const InputDecoration(labelText: '当前阶段'),
                        items: InquiryStage.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setSheetState(() {
                            stage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<InquiryPriority>(
                        initialValue: priority,
                        decoration: const InputDecoration(labelText: '优先级'),
                        items: InquiryPriority.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setSheetState(() {
                            priority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: ownerController,
                        decoration: const InputDecoration(
                          labelText: '负责人',
                          hintText: '例如：商务负责人 / 项目经理',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: proposalController,
                        decoration: const InputDecoration(
                          labelText: '方案标题',
                          hintText: '例如：榄雕研学课程数字方案',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: estimatedValueController,
                        decoration: const InputDecoration(
                          labelText: '预计金额',
                          hintText: '例如：￥38,000',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nextActionController,
                        decoration: const InputDecoration(
                          labelText: '下一步动作',
                          hintText: '例如：明天下午电话确认需求边界',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '内部备注',
                          hintText: '记录需求判断、推进风险或报价建议',
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: reminderAt ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                          );
                          if (picked == null) {
                            return;
                          }
                          setSheetState(() {
                            reminderAt = picked;
                          });
                        },
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(
                          reminderAt == null
                              ? '设置跟进提醒'
                              : '提醒时间：${reminderAt!.year}-${reminderAt!.month.toString().padLeft(2, '0')}-${reminderAt!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        inquiry.message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                      if (followUps.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text(
                          '跟进记录',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...followUps.reversed
                            .take(4)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.channel} · ${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.summary,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final channelController = TextEditingController(
                            text: '电话',
                          );
                          final summaryController = TextEditingController();
                          final nextEntry = await showDialog<InquiryFollowUp>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text('添加跟进记录'),
                                content: SizedBox(
                                  width: 360,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: channelController,
                                        decoration: const InputDecoration(
                                          labelText: '渠道',
                                          hintText: '电话 / 微信 / 面谈 / 邮件',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: summaryController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: '跟进摘要',
                                          hintText: '记录这次沟通的结果和判断',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('取消'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(
                                        InquiryFollowUp(
                                          summary: summaryController.text
                                              .trim(),
                                          channel: channelController.text
                                              .trim(),
                                          createdAt: DateTime.now(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('保存'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (nextEntry == null || nextEntry.summary.isEmpty) {
                            return;
                          }
                          setSheetState(() {
                            followUps.add(nextEntry);
                          });
                        },
                        icon: const Icon(Icons.timeline_outlined),
                        label: const Text('添加跟进记录'),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () {
                          onUpdateInquiry(
                            inquiry.copyWith(
                              stage: stage,
                              priority: priority,
                              ownerName: ownerController.text.trim(),
                              proposalTitle: proposalController.text.trim(),
                              estimatedValue: estimatedValueController.text
                                  .trim(),
                              nextAction: nextActionController.text.trim(),
                              adminNote: noteController.text.trim(),
                              reminderAt: reminderAt,
                              followUps: followUps,
                              lastUpdatedAt: DateTime.now(),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存跟进信息'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StageColumn extends StatelessWidget {
  final InquiryStage stage;
  final List<ServiceInquiry> items;
  final ValueChanged<ServiceInquiry> onAdvance;
  final ValueChanged<ServiceInquiry> onRollback;
  final ValueChanged<ServiceInquiry> onEdit;

  const _StageColumn({
    required this.stage,
    required this.items,
    required this.onAdvance,
    required this.onRollback,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stage.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlphaValue(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      '当前阶段暂无线索',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _InquiryCard(
                        item: item,
                        onAdvance: () => onAdvance(item),
                        onRollback: () => onRollback(item),
                        onEdit: () => onEdit(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final ServiceInquiry item;
  final VoidCallback onAdvance;
  final VoidCallback onRollback;
  final VoidCallback onEdit;

  const _InquiryCard({
    required this.item,
    required this.onAdvance,
    required this.onRollback,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.organization.isEmpty ? '未填写机构' : item.organization,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PriorityChip(priority: item.priority),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.packageTitle,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.contactName.isEmpty ? '未留联系人' : item.contactName} · ${item.budget}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            item.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          if (item.nextAction.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlphaValue(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '下一步：${item.nextAction}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (item.ownerName.isNotEmpty || item.estimatedValue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${item.ownerName.isEmpty ? '未指派负责人' : item.ownerName} · ${item.estimatedValue.isEmpty ? '待评估金额' : item.estimatedValue}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
          if (item.proposalTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '方案：${item.proposalTitle}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '备注：${item.adminNote}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
          if (item.followUps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '最近跟进：${item.followUps.last.summary}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: onRollback,
                icon: const Icon(Icons.arrow_back),
                tooltip: '退回上一阶段',
              ),
              IconButton(
                onPressed: onAdvance,
                icon: const Icon(Icons.arrow_forward),
                tooltip: '推进下一阶段',
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('编辑'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final InquiryPriority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (priority) {
      InquiryPriority.normal => Colors.white70,
      InquiryPriority.high => const Color(0xFFF7B955),
      InquiryPriority.strategic => const Color(0xFFFF7A59),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
