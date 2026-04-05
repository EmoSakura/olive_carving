import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_models.dart';
import 'app_theme.dart';

enum _CraftScene { kernel, composition, blocking, detail, polish }

class _CraftStageProfile {
  final String stageTag;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color support;
  final List<String> tools;
  final List<String> materials;
  final List<String> checkpoints;
  final List<String> mistakes;
  final String output;
  final _CraftScene scene;

  const _CraftStageProfile({
    required this.stageTag,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.support,
    required this.tools,
    required this.materials,
    required this.checkpoints,
    required this.mistakes,
    required this.output,
    required this.scene,
  });
}

class ProcessExperienceScreen extends StatefulWidget {
  final List<CraftStep> steps;
  final Set<String> learnedStepTitles;
  final ValueChanged<String> onStepLearned;

  const ProcessExperienceScreen({
    super.key,
    required this.steps,
    required this.learnedStepTitles,
    required this.onStepLearned,
  });

  @override
  State<ProcessExperienceScreen> createState() =>
      _ProcessExperienceScreenState();
}

class _ProcessExperienceScreenState extends State<ProcessExperienceScreen> {
  static const Map<String, _CraftStageProfile> _profiles = {
    '选核': _CraftStageProfile(
      stageTag: 'MATERIAL SCAN',
      subtitle: '先判断材料能不能承题，再谈刀法和画面。',
      icon: Icons.grain_outlined,
      accent: Color(0xFFD8B26A),
      support: Color(0xFF6B5336),
      tools: ['核形筛选', '纹理观察', '厚薄判断'],
      materials: ['乌榄核', '天然纹路', '油性与密度'],
      checkpoints: ['核形能否站住题材', '纹理是否顺着叙事', '是否存在裂纹和空心风险'],
      mistakes: ['只看大小不看结构', '忽略天然纹理的走向', '为复杂题材选过薄核料'],
      output: '确定可用核料与题材方向，进入构思阶段。',
      scene: _CraftScene.kernel,
    ),
    '构思': _CraftStageProfile(
      stageTag: 'NARRATIVE LAYOUT',
      subtitle: '不是把图塞进榄核，而是让故事顺着核面长出来。',
      icon: Icons.route_outlined,
      accent: Color(0xFFE3C47B),
      support: Color(0xFF5A4430),
      tools: ['构图草图', '题材压缩', '主次规划'],
      materials: ['故事原型', '核面弧度', '前后景关系'],
      checkpoints: ['主视觉是否先被看见', '故事人物是否站得住', '核面转折有没有被顺势利用'],
      mistakes: ['信息堆太满', '只想局部不想整体动线', '忽略弧面造成画面发散'],
      output: '形成适合这枚核料的叙事草图和观看动线。',
      scene: _CraftScene.composition,
    ),
    '粗雕': _CraftStageProfile(
      stageTag: 'STRUCTURE BUILD',
      subtitle: '先立体块与大关系，别让细节抢在结构前面。',
      icon: Icons.architecture_outlined,
      accent: Color(0xFFCC9B58),
      support: Color(0xFF463224),
      tools: ['开坯刀法', '体块切分', '主从分层'],
      materials: ['体块边界', '前后层次', '结构余量'],
      checkpoints: ['大关系是否成立', '关键支撑位有没有保住', '是否给精雕留足余量'],
      mistakes: ['过早削薄关键节点', '细节先行导致结构松散', '一味追求快感忽略层次'],
      output: '完成稳定结构和主从关系，为精雕预留空间。',
      scene: _CraftScene.blocking,
    ),
    '精雕': _CraftStageProfile(
      stageTag: 'DETAIL CARVE',
      subtitle: '人物神态、衣纹和层理都在这一步被真正做活。',
      icon: Icons.auto_fix_high_outlined,
      accent: Color(0xFFF0CB83),
      support: Color(0xFF4A3424),
      tools: ['线条控制', '细节压缩', '焦点强调'],
      materials: ['人物眉眼', '衣纹窗棂', '山石层理'],
      checkpoints: ['焦点是否比其他部分更清晰', '细节密度是否有节奏', '线条转折是否干净'],
      mistakes: ['每个地方一样重', '细节过满导致主次不分', '刀痕发抖破坏精致感'],
      output: '让画面从结构成立，走到神态与细节都能打动人。',
      scene: _CraftScene.detail,
    ),
    '抛光': _CraftStageProfile(
      stageTag: 'FINISH & GLOW',
      subtitle: '把刀痕收束成温润成品，让触感和光感统一。',
      icon: Icons.blur_on_outlined,
      accent: Color(0xFFF3D99F),
      support: Color(0xFF71553A),
      tools: ['细磨抛光', '表面统一', '光感校正'],
      materials: ['边缘触感', '表面反光', '温润度'],
      checkpoints: ['手感是否均匀', '表面反光是否顺', '作品有没有从雕刻物变成成品'],
      mistakes: ['只求亮不求层次', '把边角磨钝', '忽视保养后的最终光感'],
      output: '完成展示级成品状态，可进入收藏、陈列或演示。',
      scene: _CraftScene.polish,
    ),
  };

  int _selectedIndex = 0;

  CraftStep get _activeStep => widget.steps[_selectedIndex];

  _CraftStageProfile get _activeProfile =>
      _profiles[_activeStep.title] ??
      const _CraftStageProfile(
        stageTag: 'CRAFT STAGE',
        subtitle: '用更具结构感的方式理解工艺步骤。',
        icon: Icons.layers_outlined,
        accent: AppColors.accent,
        support: AppColors.ink,
        tools: ['观察', '判断', '执行'],
        materials: ['结构', '层次', '节奏'],
        checkpoints: ['先保证主次，再丰富细节'],
        mistakes: ['不要让所有信息同时发声'],
        output: '完成该步骤对应的工艺目标。',
        scene: _CraftScene.kernel,
      );

  void _selectStep(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _markLearned() {
    widget.onStepLearned(_activeStep.title);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记录《${_activeStep.title}》学习进度'),
        backgroundColor: _activeProfile.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final learnedCount = widget.learnedStepTitles.length;
    final progress = widget.steps.isEmpty
        ? 0.0
        : learnedCount / widget.steps.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1410), Color(0xFF0F0F0F)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _CraftHeroPanel(
                      step: _activeStep,
                      profile: _activeProfile,
                      learnedCount: learnedCount,
                      totalCount: widget.steps.length,
                      progress: progress,
                      onMarkLearned: _markLearned,
                    ),
                  ),
                  Expanded(
                    child: wide
                        ? Row(
                            children: [
                              SizedBox(
                                width: 320,
                                child: _CraftStepRail(
                                  steps: widget.steps,
                                  selectedIndex: _selectedIndex,
                                  learnedStepTitles: widget.learnedStepTitles,
                                  profiles: _profiles,
                                  onSelect: _selectStep,
                                ),
                              ),
                              Expanded(
                                child: _CraftStageBoard(
                                  step: _activeStep,
                                  profile: _activeProfile,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 132,
                                child: _CraftStepRail(
                                  steps: widget.steps,
                                  selectedIndex: _selectedIndex,
                                  learnedStepTitles: widget.learnedStepTitles,
                                  profiles: _profiles,
                                  onSelect: _selectStep,
                                  horizontal: true,
                                ),
                              ),
                              Expanded(
                                child: _CraftStageBoard(
                                  step: _activeStep,
                                  profile: _activeProfile,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CraftHeroPanel extends StatelessWidget {
  final CraftStep step;
  final _CraftStageProfile profile;
  final int learnedCount;
  final int totalCount;
  final double progress;
  final VoidCallback onMarkLearned;

  const _CraftHeroPanel({
    required this.step,
    required this.profile,
    required this.learnedCount,
    required this.totalCount,
    required this.progress,
    required this.onMarkLearned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [profile.support, const Color(0xFF111111)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CraftHeroPill(label: profile.stageTag, accent: profile.accent),
              _CraftHeroPill(
                label: '已完成 $learnedCount / $totalCount',
                accent: profile.accent.withAlphaValue(0.88),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: profile.accent.withAlphaValue(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(profile.icon, color: profile.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onMarkLearned,
                icon: const Icon(Icons.check),
                label: const Text('标记已掌握'),
                style: FilledButton.styleFrom(
                  backgroundColor: profile.accent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white10,
              color: profile.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _CraftHeroPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _CraftHeroPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlphaValue(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CraftStepRail extends StatelessWidget {
  final List<CraftStep> steps;
  final int selectedIndex;
  final Set<String> learnedStepTitles;
  final Map<String, _CraftStageProfile> profiles;
  final ValueChanged<int> onSelect;
  final bool horizontal;

  const _CraftStepRail({
    required this.steps,
    required this.selectedIndex,
    required this.learnedStepTitles,
    required this.profiles,
    required this.onSelect,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = horizontal
        ? ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => _CraftStepTile(
              step: steps[index],
              profile: profiles[steps[index].title]!,
              selected: index == selectedIndex,
              learned: learnedStepTitles.contains(steps[index].title),
              horizontal: true,
              onTap: () => onSelect(index),
            ),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: steps.length,
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemBuilder: (context, index) => _CraftStepTile(
              step: steps[index],
              profile: profiles[steps[index].title]!,
              selected: index == selectedIndex,
              learned: learnedStepTitles.contains(steps[index].title),
              onTap: () => onSelect(index),
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: steps.length,
          );

    return Container(
      margin: horizontal
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: child,
    );
  }
}

class _CraftStepTile extends StatelessWidget {
  final CraftStep step;
  final _CraftStageProfile profile;
  final bool selected;
  final bool learned;
  final bool horizontal;
  final VoidCallback onTap;

  const _CraftStepTile({
    required this.step,
    required this.profile,
    required this.selected,
    required this.learned,
    required this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: horizontal ? 220 : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? profile.accent.withAlphaValue(0.14)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? profile.accent : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: profile.accent.withAlphaValue(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(profile.icon, color: profile.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.stageTag,
                        style: TextStyle(
                          color: profile.accent,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.summary,
                        maxLines: horizontal ? 2 : 3,
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
                Icon(
                  learned ? Icons.check_circle : Icons.chevron_right,
                  color: learned ? profile.accent : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CraftStageBoard extends StatelessWidget {
  final CraftStep step;
  final _CraftStageProfile profile;

  const _CraftStageBoard({required this.step, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: ValueKey(step.title),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.detail,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _CraftAnimatedPreview(spec: profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CraftInfoCard(
                    title: '本步工具',
                    accent: profile.accent,
                    items: profile.tools,
                  ),
                  _CraftInfoCard(
                    title: '材料与结构',
                    accent: profile.accent,
                    items: profile.materials,
                  ),
                  _CraftInfoCard(
                    title: '核心判断点',
                    accent: profile.accent,
                    items: profile.checkpoints,
                  ),
                  _CraftInfoCard(
                    title: '常见误区',
                    accent: const Color(0xFFE29A67),
                    items: profile.mistakes,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '阅读焦点',
                      style: TextStyle(
                        color: profile.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.focus,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '本步产出',
                      style: TextStyle(
                        color: profile.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.output,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CraftAnimatedPreview extends StatefulWidget {
  final _CraftStageProfile spec;

  const _CraftAnimatedPreview({required this.spec});

  @override
  State<_CraftAnimatedPreview> createState() => _CraftAnimatedPreviewState();
}

class _CraftAnimatedPreviewState extends State<_CraftAnimatedPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.spec.support, const Color(0xFF151515)],
            ),
          ),
          child: CustomPaint(
            painter: _CraftPreviewPainter(
              spec: widget.spec,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _CraftPreviewPainter extends CustomPainter {
  final _CraftStageProfile spec;
  final double progress;

  const _CraftPreviewPainter({required this.spec, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final accentPaint = Paint()
      ..color = spec.accent.withAlphaValue(0.85)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = spec.accent.withAlphaValue(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final softLinePaint = Paint()
      ..color = Colors.white.withAlphaValue(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (spec.scene) {
      case _CraftScene.kernel:
        for (int i = 0; i < 3; i++) {
          final center = Offset(
            42.0 + i * 82.0 + progress * 6.0,
            size.height / 2,
          );
          final rect = Rect.fromCenter(center: center, width: 42, height: 64);
          canvas.drawOval(
            rect,
            Paint()..color = spec.accent.withAlphaValue(0.18),
          );
          canvas.drawOval(rect.inflate(i == 1 ? 6 : 0), softLinePaint);
        }
      case _CraftScene.composition:
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
          const Radius.circular(16),
        );
        canvas.drawRRect(frame, softLinePaint);
        canvas.drawLine(
          const Offset(18, 66),
          Offset(size.width - 18, 66),
          softLinePaint,
        );
        canvas.drawLine(
          Offset(size.width * 0.38, 18),
          Offset(size.width * 0.38, size.height - 18),
          softLinePaint,
        );
        final path = Path()
          ..moveTo(36, 94)
          ..lineTo(size.width * 0.36, 56 - progress * 8)
          ..lineTo(size.width * 0.72, 82 + progress * 6)
          ..lineTo(size.width - 34, 42);
        canvas.drawPath(path, linePaint);
      case _CraftScene.blocking:
        for (int i = 0; i < 4; i++) {
          final left = 26.0 + i * 48.0;
          final height = 26.0 + i * 12.0 + progress * 8.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left, size.height - 24.0 - height, 30.0, height),
              const Radius.circular(8),
            ),
            Paint()..color = spec.accent.withAlphaValue(0.18 + i * 0.08),
          );
        }
        canvas.drawLine(
          Offset(34 + progress * 120, 24),
          Offset(58 + progress * 120, size.height - 28),
          linePaint,
        );
      case _CraftScene.detail:
        final ring = Rect.fromCenter(
          center: Offset(size.width * 0.42, size.height * 0.54),
          width: 82,
          height: 82,
        );
        canvas.drawOval(ring, softLinePaint..strokeWidth = 3);
        for (int i = 0; i < 4; i++) {
          final y = 34.0 + i * 18.0;
          canvas.drawLine(
            Offset(32, y),
            Offset(size.width - 36, y + progress * (i.isEven ? 8 : -8)),
            linePaint,
          );
        }
        canvas.drawCircle(
          Offset(size.width * 0.42, size.height * 0.54),
          8 + progress * 4,
          accentPaint,
        );
      case _CraftScene.polish:
        final polishPaint = Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  spec.accent.withAlphaValue(0.12),
                  spec.accent.withAlphaValue(0.42),
                  Colors.white.withAlphaValue(0.08),
                ],
                stops: [0, progress.clamp(0.1, 0.9), 1],
              ).createShader(
                Rect.fromLTWH(20, 18, size.width - 40, size.height - 36),
              );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(20, 18, size.width - 40, size.height - 36),
            const Radius.circular(18),
          ),
          polishPaint,
        );
        canvas.drawLine(
          Offset(26 + progress * 80, 30),
          Offset(size.width - 26 + progress * 20, size.height - 34),
          Paint()
            ..color = Colors.white.withAlphaValue(0.34)
            ..strokeWidth = 4,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CraftPreviewPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.spec != spec;
  }
}

class _CraftInfoCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<String> items;

  const _CraftInfoCard({
    required this.title,
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
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
              title,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
