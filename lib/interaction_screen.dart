import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_models.dart';
import 'app_theme.dart';

enum CarvingMode {
  rough('粗雕', Icons.handyman_outlined, 7.5, 5.2),
  fine('精雕', Icons.edit_outlined, 4.5, 3.2),
  hollow('镂空雕', Icons.blur_on_outlined, 3.6, 2.4);

  final String label;
  final IconData icon;
  final double baseWidth;
  final double spacing;

  const CarvingMode(this.label, this.icon, this.baseWidth, this.spacing);
}

enum Difficulty {
  easy('简单', 0.85),
  medium('中等', 1.0),
  hard('困难', 1.2);

  final String label;
  final double widthFactor;

  const Difficulty(this.label, this.widthFactor);
}

class _AchievementDefinition {
  final String title;
  final String description;
  final IconData icon;
  final bool Function(List<CarvingRecord> history) isUnlocked;

  const _AchievementDefinition({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

class _WorkDraft {
  final String title;
  final String note;

  const _WorkDraft({required this.title, required this.note});
}

class CarvingPoint {
  final Offset position;
  final double width;

  const CarvingPoint({required this.position, required this.width});
}

class CarvingStroke {
  final List<CarvingPoint> points;
  final CarvingMode mode;

  const CarvingStroke({required this.points, required this.mode});
}

class WoodParticle {
  final Offset position;
  final double radius;
  final double opacity;

  const WoodParticle({
    required this.position,
    required this.radius,
    required this.opacity,
  });
}

class InteractionScreen extends StatefulWidget {
  final List<CarvingRecord> initialHistory;
  final ValueChanged<List<CarvingRecord>> onHistoryChanged;

  const InteractionScreen({
    super.key,
    required this.initialHistory,
    required this.onHistoryChanged,
  });

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> {
  CarvingMode _selectedMode = CarvingMode.rough;
  Difficulty _selectedDifficulty = Difficulty.easy;

  final List<CarvingStroke> _strokes = [];
  final List<WoodParticle> _particles = [];
  static const List<_AchievementDefinition> _achievements = [
    _AchievementDefinition(
      title: '初试牛刀',
      description: '完成第一次雕刻体验',
      icon: Icons.star_rounded,
      isUnlocked: _unlockFirstSession,
    ),
    _AchievementDefinition(
      title: '渐入佳境',
      description: '累计完成 3 次雕刻归档',
      icon: Icons.auto_awesome,
      isUnlocked: _unlockThreeSessions,
    ),
    _AchievementDefinition(
      title: '精益求精',
      description: '在精雕模式下完成作品',
      icon: Icons.workspace_premium_outlined,
      isUnlocked: _unlockFineMode,
    ),
    _AchievementDefinition(
      title: '挑战极限',
      description: '在困难模式下完成作品',
      icon: Icons.local_fire_department_outlined,
      isUnlocked: _unlockHardMode,
    ),
    _AchievementDefinition(
      title: '全能雕刻师',
      description: '尝试全部三种雕刻模式',
      icon: Icons.extension_outlined,
      isUnlocked: _unlockAllModes,
    ),
  ];

  late List<CarvingRecord> _history;

  List<CarvingPoint> _currentPoints = [];
  bool _isCurrentWorkSaved = false;
  int _lastHapticTick = 0;

  static bool _unlockFirstSession(List<CarvingRecord> history) =>
      history.isNotEmpty;

  static bool _unlockThreeSessions(List<CarvingRecord> history) =>
      history.length >= 3;

  static bool _unlockFineMode(List<CarvingRecord> history) =>
      history.any((item) => item.modeId == CarvingMode.fine.name);

  static bool _unlockHardMode(List<CarvingRecord> history) =>
      history.any((item) => item.difficultyId == Difficulty.hard.name);

  static bool _unlockAllModes(List<CarvingRecord> history) =>
      history.map((item) => item.modeId).toSet().length ==
      CarvingMode.values.length;

  @override
  void initState() {
    super.initState();
    _history = List<CarvingRecord>.from(widget.initialHistory);
  }

  @override
  void didUpdateWidget(covariant InteractionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHistory != widget.initialHistory) {
      _history = List<CarvingRecord>.from(widget.initialHistory);
    }
  }

  int get _strokeCount => _strokes.length + (_currentPoints.length > 1 ? 1 : 0);

  double get _progress {
    final normalized = _strokeCount / _targetStrokeCount;
    return normalized.clamp(0.0, 1.0);
  }

  int get _targetStrokeCount {
    switch (_selectedDifficulty) {
      case Difficulty.easy:
        return 10;
      case Difficulty.medium:
        return 16;
      case Difficulty.hard:
        return 22;
    }
  }

  String get _craftHint {
    switch (_selectedMode) {
      case CarvingMode.rough:
        return '先立体块与大关系，感受粗雕开坯的节奏。';
      case CarvingMode.fine:
        return '放慢手势速度，让线条更稳定，模拟细节刻画。';
      case CarvingMode.hollow:
        return '尝试留出呼吸感，用疏密变化制造镂空层次。';
    }
  }

  int get _unlockedAchievementCount =>
      _achievements.where((item) => item.isUnlocked(_history)).length;

  CarvingRecord? get _latestRecord => _history.isEmpty ? null : _history.last;

  String get _studioChallenge {
    if (_history.isEmpty) {
      return '完成第一件作品归档，解锁你的数字工坊档案。';
    }
    if (!_history.any((item) => item.modeId == CarvingMode.fine.name)) {
      return '下一步建议：切换到精雕模式，完成一件细节导向的作品。';
    }
    if (!_history.any((item) => item.difficultyId == Difficulty.hard.name)) {
      return '下一步建议：挑战困难模式，训练更细密的刻痕控制。';
    }
    if (_history.map((item) => item.modeId).toSet().length <
        CarvingMode.values.length) {
      return '下一步建议：把三种模式都体验一遍，补齐成就墙。';
    }
    return '你已经完成基础挑战，建议继续积累作品档案用于课程展示或商业演示。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指尖互动'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '作品档案',
            onPressed: _showHistory,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: '成就墙',
            onPressed: _showAchievements,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '指尖试雕',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '通过手势轨迹、作品归档与创作挑战，模拟榄雕从开坯到精修的完整体验闭环。',
                style: TextStyle(
                  color: AppColors.textSecondary.withAlphaValue(0.92),
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              _StatusPanel(
                progress: _progress,
                progressText: '${(_progress * 100).toInt()}%',
                strokeCount: _strokeCount,
                hint: _craftHint,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StudioMetricCard(
                      label: '归档作品',
                      value: '${_history.length}',
                      hint: '可跨会话保存',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StudioMetricCard(
                      label: '解锁成就',
                      value: '$_unlockedAchievementCount',
                      hint: '成长看得见',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StudioMetricCard(
                      label: '最高笔数',
                      value: _history.isEmpty
                          ? '--'
                          : '${_history.map((item) => item.strokeCount).reduce(math.max)}',
                      hint: '当前档案峰值',
                    ),
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
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.flag_outlined,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今日工坊建议',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _studioChallenge,
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
              const SizedBox(height: 18),
              _SectionTitle(title: '雕刻模式'),
              const SizedBox(height: 10),
              Row(
                children: CarvingMode.values.map((mode) {
                  final isSelected = _selectedMode == mode;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: mode == CarvingMode.values.last ? 0 : 10,
                      ),
                      child: _ChoiceChipCard(
                        icon: mode.icon,
                        label: mode.label,
                        selected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedMode = mode;
                            _isCurrentWorkSaved = false;
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: '难度选择'),
              const SizedBox(height: 10),
              Row(
                children: Difficulty.values.map((difficulty) {
                  final isSelected = _selectedDifficulty == difficulty;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: difficulty == Difficulty.values.last ? 0 : 10,
                      ),
                      child: _ChoiceChipCard(
                        label: difficulty.label,
                        selected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedDifficulty = difficulty;
                            _isCurrentWorkSaved = false;
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 0.68,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return GestureDetector(
                              onPanStart: (details) =>
                                  _beginStroke(details.localPosition, size),
                              onPanUpdate: (details) =>
                                  _appendPoint(details.localPosition, size),
                              onPanEnd: (_) => _endStroke(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF211811),
                                        Color(0xFF0F0F0F),
                                      ],
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: _CarvingBoardPainter(
                                      strokes: _strokes,
                                      currentStroke: _currentPoints,
                                      particles: _particles,
                                      progress: _progress,
                                    ),
                                    child: Center(
                                      child: IgnorePointer(
                                        child: AnimatedOpacity(
                                          opacity: _strokeCount > 0 ? 0.0 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withAlphaValue(0.36),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.white10,
                                              ),
                                            ),
                                            child: const Text(
                                              '拖动手指开始雕刻',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetBoard,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重置榄核'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: Colors.white12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _progress >= 1 && !_isCurrentWorkSaved
                                ? _saveWork
                                : null,
                            icon: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.black,
                            ),
                            label: Text(
                              _isCurrentWorkSaved ? '已归档' : '归档作品',
                              style: const TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              disabledBackgroundColor: AppColors.accent
                                  .withAlphaValue(0.35),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_latestRecord != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '最近归档作品',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _latestRecord!.title,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_latestRecord!.modeLabel} · ${_latestRecord!.difficultyLabel} · ${_latestRecord!.strokeCount} 笔',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      if (_latestRecord!.note.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _latestRecord!.note,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '交互说明',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. 在榄核区域内拖动手指或鼠标，生成刻痕。\n2. 不同模式会改变笔触的粗细与节奏感。\n3. 进度达到 100% 后，建议为作品命名并归档，积累可复用的展示素材。',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
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
    );
  }

  void _beginStroke(Offset position, Size size) {
    if (!_isInsideOlive(position, size)) {
      return;
    }
    HapticFeedback.selectionClick();
    final width = _strokeWidth(position);
    setState(() {
      _isCurrentWorkSaved = false;
      _currentPoints = [CarvingPoint(position: position, width: width)];
      _spawnParticles(position);
    });
  }

  void _appendPoint(Offset position, Size size) {
    if (_currentPoints.isEmpty || !_isInsideOlive(position, size)) {
      return;
    }

    final previous = _currentPoints.last.position;
    final distance = (position - previous).distance;
    if (distance < _selectedMode.spacing) {
      return;
    }

    final width = _strokeWidth(position);
    final nextTick = (_strokeCount + _currentPoints.length) ~/ 3;
    if (nextTick > _lastHapticTick) {
      _lastHapticTick = nextTick;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentPoints.add(CarvingPoint(position: position, width: width));
      _spawnParticles(position);
    });
  }

  void _endStroke() {
    if (_currentPoints.length < 2) {
      setState(() {
        _currentPoints = [];
      });
      return;
    }

    setState(() {
      _strokes.add(
        CarvingStroke(
          points: List<CarvingPoint>.from(_currentPoints),
          mode: _selectedMode,
        ),
      );
      _currentPoints = [];
      if (_progress >= 1) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  double _strokeWidth(Offset position) {
    final variance = (math.sin(position.dx * 0.08) + 1) * 0.5;
    return _selectedMode.baseWidth * _selectedDifficulty.widthFactor - variance;
  }

  bool _isInsideOlive(Offset point, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final normalizedX = (point.dx - center.dx) / (size.width * 0.32);
    final normalizedY = (point.dy - center.dy) / (size.height * 0.44);
    return (normalizedX * normalizedX) + (normalizedY * normalizedY) <= 1;
  }

  void _spawnParticles(Offset position) {
    final random = math.Random();
    for (int i = 0; i < 3; i++) {
      _particles.add(
        WoodParticle(
          position:
              position +
              Offset(
                random.nextDouble() * 18 - 9,
                random.nextDouble() * 18 - 9,
              ),
          radius: 1.2 + random.nextDouble() * 1.6,
          opacity: 0.3 + random.nextDouble() * 0.4,
        ),
      );
    }
    if (_particles.length > 160) {
      _particles.removeRange(0, _particles.length - 160);
    }
  }

  void _resetBoard() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentPoints = [];
      _particles.clear();
      _isCurrentWorkSaved = false;
      _lastHapticTick = 0;
    });
  }

  Future<void> _saveWork() async {
    if (_progress < 1 || _isCurrentWorkSaved) {
      return;
    }

    final draft = await _showSaveDraftDialog();
    if (!mounted || draft == null) {
      return;
    }

    final nextHistory = [
      ..._history,
      CarvingRecord(
        title: draft.title,
        note: draft.note,
        modeId: _selectedMode.name,
        modeLabel: _selectedMode.label,
        difficultyId: _selectedDifficulty.name,
        difficultyLabel: _selectedDifficulty.label,
        timestamp: DateTime.now(),
        strokeCount: _strokeCount,
      ),
    ];

    setState(() {
      _history = nextHistory;
      _isCurrentWorkSaved = true;
    });

    widget.onHistoryChanged(nextHistory);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('《${draft.title}》已归档到本地作品档案'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Future<_WorkDraft?> _showSaveDraftDialog() {
    final titleController = TextEditingController(
      text: '${_selectedMode.label}·第${_history.length + 1}件',
    );
    final noteController = TextEditingController();

    return showDialog<_WorkDraft>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('归档作品'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '作品名称',
                    hintText: '例如：松风入核',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '创作备注',
                    hintText: '记录本次练习重点、灵感或展示用途',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _WorkDraft(
                    title: titleController.text.trim().isEmpty
                        ? '未命名作品'
                        : titleController.text.trim(),
                    note: noteController.text.trim(),
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
  }

  void _showHistory() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('作品档案'),
          content: SizedBox(
            width: double.maxFinite,
            child: _history.isEmpty
                ? const Text('还没有归档作品，可以先完成一次雕刻体验。')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[_history.length - index - 1];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _modeFromId(item.modeId).icon,
                          color: AppColors.accent,
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.modeLabel} · ${item.difficultyLabel} · ${_formatTimestamp(item.timestamp)}',
                        ),
                        trailing: Text(
                          '${item.strokeCount} 笔',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showAchievements() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('成就墙'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final item = _achievements[index];
                final unlocked = item.isUnlocked(_history);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.icon,
                    color: unlocked ? AppColors.accent : Colors.white24,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: unlocked ? AppColors.textPrimary : Colors.white38,
                    ),
                  ),
                  subtitle: Text(item.description),
                  trailing: Icon(
                    unlocked ? Icons.check_circle : Icons.lock_outline,
                    color: unlocked ? AppColors.accent : Colors.white24,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  CarvingMode _modeFromId(String id) {
    return CarvingMode.values.firstWhere(
      (item) => item.name == id,
      orElse: () => CarvingMode.rough,
    );
  }

  String _formatTimestamp(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}

class _StatusPanel extends StatelessWidget {
  final double progress;
  final String progressText;
  final int strokeCount;
  final String hint;

  const _StatusPanel({
    required this.progress,
    required this.progressText,
    required this.strokeCount,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '雕刻进度',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                progressText,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '当前累计刻痕：$strokeCount 笔',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _StudioMetricCard({
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
        borderRadius: BorderRadius.circular(18),
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChipCard({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.white10,
            ),
          ),
          child: Column(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Icon(
                    icon,
                    color: selected ? Colors.black : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarvingBoardPainter extends CustomPainter {
  final List<CarvingStroke> strokes;
  final List<CarvingPoint> currentStroke;
  final List<WoodParticle> particles;
  final double progress;

  const _CarvingBoardPainter({
    required this.strokes,
    required this.currentStroke,
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final oliveRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.66,
      height: size.height * 0.88,
    );

    final backdropPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF574233), Color(0xFF251A13)],
      ).createShader(oliveRect);
    canvas.drawOval(oliveRect, backdropPaint);

    final texturePaint = Paint()
      ..color = const Color(0xFF8B6542).withAlphaValue(0.08)
      ..strokeWidth = 1;
    for (double y = oliveRect.top + 18; y < oliveRect.bottom - 18; y += 18) {
      final inset = (y - oliveRect.center.dy).abs() * 0.18;
      canvas.drawLine(
        Offset(oliveRect.left + 28 + inset, y),
        Offset(oliveRect.right - 28 - inset, y + 6),
        texturePaint,
      );
    }

    final carvingPaint = Paint()
      ..color = const Color(0xFFDCC6A5)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, carvingPaint);
    }
    if (currentStroke.length > 1) {
      _drawStroke(canvas, currentStroke, carvingPaint);
    }

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (final particle in particles) {
      particlePaint.color = const Color(
        0xFFC79B68,
      ).withAlphaValue(particle.opacity);
      canvas.drawCircle(particle.position, particle.radius, particlePaint);
    }

    final glowPaint = Paint()
      ..color = AppColors.accent.withAlphaValue(0.08 + progress * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawOval(oliveRect.inflate(8), glowPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withAlphaValue(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(oliveRect, borderPaint);
  }

  void _drawStroke(Canvas canvas, List<CarvingPoint> points, Paint basePaint) {
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      basePaint.strokeWidth = (current.width + next.width) / 2;
      canvas.drawLine(current.position, next.position, basePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CarvingBoardPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.particles != particles ||
        oldDelegate.progress != progress;
  }
}
