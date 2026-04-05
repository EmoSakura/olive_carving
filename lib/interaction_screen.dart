import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'canvas_project_models.dart';
import 'export_support.dart';

enum CarvingMode {
  rough('木纹笔', '更有颗粒感，适合铺出体块和氛围', Icons.brush_outlined, 8.4, 5.4, 0.78),
  fine('细墨笔', '线条更稳，适合勾边和精修细节', Icons.edit_outlined, 4.6, 3.0, 0.94),
  hollow(
    '留白笔',
    '更轻更透，适合提亮和制造呼吸感',
    Icons.auto_fix_high_outlined,
    6.2,
    4.2,
    0.58,
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final double baseWidth;
  final double spacing;
  final double opacityFactor;

  const CarvingMode(
    this.label,
    this.subtitle,
    this.icon,
    this.baseWidth,
    this.spacing,
    this.opacityFactor,
  );
}

enum Difficulty {
  easy('自由画布', '干净纸面，适合灵感起稿', 1.0, 12, Color(0xFFF3E8D7), Color(0xFFE5D4BE)),
  medium(
    '榄核导板',
    '保留榄核参考轮廓，更贴近主题',
    0.94,
    18,
    Color(0xFFE9D7BD),
    Color(0xFFD3B28E),
  ),
  hard('展陈海报', '更强版面感，适合做展示成图', 0.88, 24, Color(0xFFF0E4CF), Color(0xFFD8BF9D));

  final String label;
  final String subtitle;
  final double widthFactor;
  final int targetStrokeCount;
  final Color paperStart;
  final Color paperEnd;

  const Difficulty(
    this.label,
    this.subtitle,
    this.widthFactor,
    this.targetStrokeCount,
    this.paperStart,
    this.paperEnd,
  );
}

enum CanvasTool {
  brush('画笔', Icons.draw_outlined),
  eraser('橡皮', Icons.auto_fix_off_outlined);

  final String label;
  final IconData icon;

  const CanvasTool(this.label, this.icon);
}

enum _StudioSheetTab {
  tools('工具', Icons.tune),
  colors('颜色', Icons.palette_outlined),
  text('文字', Icons.text_fields),
  assets('素材', Icons.photo_library_outlined),
  layers('图层', Icons.layers_outlined),
  export('导出', Icons.ios_share_outlined);

  final String label;
  final IconData icon;

  const _StudioSheetTab(this.label, this.icon);
}

enum CanvasLayerBlend {
  normal('正常', BlendMode.srcOver),
  multiply('正片叠底', BlendMode.multiply),
  screen('滤色', BlendMode.screen),
  overlay('叠加', BlendMode.overlay);

  final String label;
  final BlendMode blendMode;

  const CanvasLayerBlend(this.label, this.blendMode);
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
  final double opacity;

  const CarvingPoint({
    required this.position,
    required this.width,
    required this.opacity,
  });
}

class CarvingStroke {
  final List<CarvingPoint> points;
  final CarvingMode mode;
  final CanvasTool tool;
  final Color color;
  final String layerId;

  const CarvingStroke({
    required this.points,
    required this.mode,
    required this.tool,
    required this.color,
    required this.layerId,
  });
}

class CanvasTextElement {
  final String id;
  final String text;
  final Offset position;
  final double fontSize;
  final Color color;
  final String layerId;
  final double rotation;

  const CanvasTextElement({
    required this.id,
    required this.text,
    required this.position,
    required this.fontSize,
    required this.color,
    required this.layerId,
    this.rotation = 0,
  });

  CanvasTextElement copyWith({
    Offset? position,
    double? fontSize,
    Color? color,
    String? text,
    String? layerId,
    double? rotation,
  }) {
    return CanvasTextElement(
      id: id,
      text: text ?? this.text,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      layerId: layerId ?? this.layerId,
      rotation: rotation ?? this.rotation,
    );
  }
}

class CanvasAssetElement {
  final String id;
  final String layerId;
  final String assetPath;
  final String sourceBytesBase64;
  final ui.Image image;
  final Offset position;
  final double width;
  final double height;
  final double opacity;
  final double rotation;

  const CanvasAssetElement({
    required this.id,
    required this.layerId,
    required this.assetPath,
    required this.sourceBytesBase64,
    required this.image,
    required this.position,
    required this.width,
    required this.height,
    required this.opacity,
    this.rotation = 0,
  });

  CanvasAssetElement copyWith({
    Offset? position,
    double? width,
    double? height,
    double? opacity,
    String? layerId,
    double? rotation,
    String? sourceBytesBase64,
  }) {
    return CanvasAssetElement(
      id: id,
      layerId: layerId ?? this.layerId,
      assetPath: assetPath,
      sourceBytesBase64: sourceBytesBase64 ?? this.sourceBytesBase64,
      image: image,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
    );
  }
}

class CanvasLayerData {
  final String id;
  final String name;
  final bool visible;
  final bool locked;
  final double opacity;
  final CanvasLayerBlend blend;

  const CanvasLayerData({
    required this.id,
    required this.name,
    required this.visible,
    required this.locked,
    required this.opacity,
    required this.blend,
  });

  CanvasLayerData copyWith({
    String? name,
    bool? visible,
    bool? locked,
    double? opacity,
    CanvasLayerBlend? blend,
  }) {
    return CanvasLayerData(
      id: id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      blend: blend ?? this.blend,
    );
  }
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
  final List<Exhibit> availableExhibits;
  final CanvasProjectDraft? initialDraft;
  final ValueChanged<List<CarvingRecord>> onHistoryChanged;
  final ValueChanged<CanvasProjectDraft> onDraftChanged;

  const InteractionScreen({
    super.key,
    required this.initialHistory,
    required this.availableExhibits,
    required this.initialDraft,
    required this.onHistoryChanged,
    required this.onDraftChanged,
  });

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> {
  static const List<Color> _palette = [
    Color(0xFF251B14),
    Color(0xFF6A472D),
    Color(0xFFD4AF37),
    Color(0xFF7A2026),
    Color(0xFF2F6159),
    Color(0xFF5E6A7D),
  ];

  CarvingMode _selectedMode = CarvingMode.rough;
  Difficulty _selectedDifficulty = Difficulty.medium;
  CanvasTool _selectedTool = CanvasTool.brush;
  Color _selectedColor = _palette.first;
  double _brushScale = 1.0;
  double _brushOpacity = 0.88;
  bool _showGrid = true;
  bool _showOliveGuide = true;
  bool _showParticles = true;

  final List<CarvingStroke> _strokes = [];
  final List<CarvingStroke> _redoStrokes = [];
  final List<WoodParticle> _particles = [];
  final GlobalKey _canvasBoundaryKey = GlobalKey();
  List<CanvasLayerData> _layers = const [
    CanvasLayerData(
      id: 'layer_base',
      name: '主图层',
      visible: true,
      locked: false,
      opacity: 1,
      blend: CanvasLayerBlend.normal,
    ),
  ];
  String _activeLayerId = 'layer_base';
  final List<CanvasTextElement> _textElements = [];
  final List<CanvasAssetElement> _assetElements = [];
  String? _selectedTextId;
  String? _selectedAssetId;
  Timer? _draftSaveDebounce;
  static const List<_AchievementDefinition> _achievements = [
    _AchievementDefinition(
      title: '第一张画布',
      description: '完成第一次作品归档',
      icon: Icons.star_rounded,
      isUnlocked: _unlockFirstSession,
    ),
    _AchievementDefinition(
      title: '稳定输出',
      description: '累计完成 3 次作品归档',
      icon: Icons.auto_awesome,
      isUnlocked: _unlockThreeSessions,
    ),
    _AchievementDefinition(
      title: '细节控',
      description: '用细墨笔完成一件作品',
      icon: Icons.workspace_premium_outlined,
      isUnlocked: _unlockFineMode,
    ),
    _AchievementDefinition(
      title: '展陈意识',
      description: '在展陈海报场景下完成作品',
      icon: Icons.view_quilt_outlined,
      isUnlocked: _unlockHardMode,
    ),
    _AchievementDefinition(
      title: '全能画布师',
      description: '尝试全部三种笔刷预设',
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
    unawaited(_restoreDraft(widget.initialDraft));
  }

  @override
  void didUpdateWidget(covariant InteractionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHistory != widget.initialHistory) {
      _history = List<CarvingRecord>.from(widget.initialHistory);
    }
    if (oldWidget.initialDraft != widget.initialDraft &&
        widget.initialDraft != null) {
      unawaited(_restoreDraft(widget.initialDraft));
    }
  }

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    super.dispose();
  }

  int get _strokeCount => _strokes.length + (_currentPoints.length > 1 ? 1 : 0);

  double get _progress {
    final normalized = _strokeCount / _targetStrokeCount;
    return normalized.clamp(0.0, 1.0);
  }

  int get _targetStrokeCount => _selectedDifficulty.targetStrokeCount;

  CanvasLayerData get _activeLayer => _layers.firstWhere(
    (item) => item.id == _activeLayerId,
    orElse: () => _layers.first,
  );

  CanvasTextElement? get _selectedText {
    for (final item in _textElements) {
      if (item.id == _selectedTextId) {
        return item;
      }
    }
    return null;
  }

  CanvasAssetElement? get _selectedAsset {
    for (final item in _assetElements) {
      if (item.id == _selectedAssetId) {
        return item;
      }
    }
    return null;
  }

  String get _craftHint {
    if (_selectedTool == CanvasTool.eraser) {
      return '橡皮更适合收边、提亮和做负形，像在版面里做减法雕刻。';
    }
    switch (_selectedMode) {
      case CarvingMode.rough:
        return '参考 MisaRin 的起稿感，这支笔更适合先搭大关系，再慢慢压细节。';
      case CarvingMode.fine:
        return '这支笔更偏线稿和细节修整，放慢速度会得到更干净的边缘。';
      case CarvingMode.hollow:
        return '这支笔更适合提亮、留白和制造呼吸感，不必急着把画面铺满。';
    }
  }

  int get _unlockedAchievementCount =>
      _achievements.where((item) => item.isUnlocked(_history)).length;

  CarvingRecord? get _latestRecord => _history.isEmpty ? null : _history.last;

  String get _studioChallenge {
    if (_history.isEmpty) {
      return '先完成第一张作品归档，把“指尖互动”升级成真正的画布成果。';
    }
    if (!_history.any((item) => item.modeId == CarvingMode.fine.name)) {
      return '下一步建议：切换到细墨笔，完成一张更注重边缘控制的作品。';
    }
    if (!_history.any((item) => item.difficultyId == Difficulty.hard.name)) {
      return '下一步建议：挑战“展陈海报”场景，做一张更适合答辩和展示的版式图。';
    }
    if (_history.map((item) => item.modeId).toSet().length <
        CarvingMode.values.length) {
      return '下一步建议：把三种笔刷都体验一遍，补齐你的创作能力标签。';
    }
    return '你已经拥有较完整的画布工作流，下一步可以继续积累作品档案用于课程展示或客户演示。';
  }

  Future<void> _restoreDraft(CanvasProjectDraft? draft) async {
    if (draft == null) {
      return;
    }
    final restoredLayers = draft.layers.isEmpty
        ? const [
            CanvasLayerData(
              id: 'layer_base',
              name: '主图层',
              visible: true,
              locked: false,
              opacity: 1,
              blend: CanvasLayerBlend.normal,
            ),
          ]
        : draft.layers
              .map(
                (item) => CanvasLayerData(
                  id: item.id,
                  name: item.name,
                  visible: item.visible,
                  locked: item.locked,
                  opacity: item.opacity,
                  blend: CanvasLayerBlend.values.firstWhere(
                    (blend) => blend.name == item.blendId,
                    orElse: () => CanvasLayerBlend.normal,
                  ),
                ),
              )
              .toList();

    final restoredAssets = <CanvasAssetElement>[];
    for (final asset in draft.assetElements) {
      ui.Image? image;
      if (asset.sourceBytesBase64.isNotEmpty) {
        image = await _loadUiImageFromBytes(
          base64Decode(asset.sourceBytesBase64),
        );
      } else if (asset.assetPath.isNotEmpty) {
        image = await _loadAssetUiImage(asset.assetPath);
      }
      if (image == null) {
        continue;
      }
      restoredAssets.add(
        CanvasAssetElement(
          id: asset.id,
          layerId: asset.layerId,
          assetPath: asset.assetPath,
          sourceBytesBase64: asset.sourceBytesBase64,
          image: image,
          position: Offset(asset.dx, asset.dy),
          width: asset.width,
          height: asset.height,
          opacity: asset.opacity,
          rotation: asset.rotation,
        ),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _layers = restoredLayers;
      _activeLayerId = draft.activeLayerId;
      _selectedMode = CarvingMode.values.firstWhere(
        (item) => item.name == draft.selectedModeId,
        orElse: () => CarvingMode.rough,
      );
      _selectedDifficulty = Difficulty.values.firstWhere(
        (item) => item.name == draft.selectedDifficultyId,
        orElse: () => Difficulty.medium,
      );
      _selectedTool = CanvasTool.values.firstWhere(
        (item) => item.name == draft.selectedToolId,
        orElse: () => CanvasTool.brush,
      );
      _selectedColor = Color(draft.selectedColorValue);
      _brushScale = draft.brushScale;
      _brushOpacity = draft.brushOpacity;
      _showGrid = draft.showGrid;
      _showOliveGuide = draft.showOliveGuide;
      _showParticles = draft.showParticles;
      _strokes
        ..clear()
        ..addAll(
          draft.strokes.map(
            (item) => CarvingStroke(
              points: item.points
                  .map(
                    (point) => CarvingPoint(
                      position: Offset(point.dx, point.dy),
                      width: point.width,
                      opacity: point.opacity,
                    ),
                  )
                  .toList(),
              mode: CarvingMode.values.firstWhere(
                (mode) => mode.name == item.modeId,
                orElse: () => CarvingMode.rough,
              ),
              tool: CanvasTool.values.firstWhere(
                (tool) => tool.name == item.toolId,
                orElse: () => CanvasTool.brush,
              ),
              color: Color(item.colorValue),
              layerId: item.layerId,
            ),
          ),
        );
      _textElements
        ..clear()
        ..addAll(
          draft.textElements.map(
            (item) => CanvasTextElement(
              id: item.id,
              text: item.text,
              position: Offset(item.dx, item.dy),
              fontSize: item.fontSize,
              color: Color(item.colorValue),
              layerId: item.layerId,
              rotation: item.rotation,
            ),
          ),
        );
      _assetElements
        ..clear()
        ..addAll(restoredAssets);
      _currentPoints = [];
      _redoStrokes.clear();
      _selectedTextId = null;
      _selectedAssetId = null;
    });
  }

  CanvasProjectDraft _buildDraft() {
    return CanvasProjectDraft(
      layers: _layers
          .map(
            (item) => CanvasLayerSnapshot(
              id: item.id,
              name: item.name,
              visible: item.visible,
              locked: item.locked,
              opacity: item.opacity,
              blendId: item.blend.name,
            ),
          )
          .toList(),
      strokes: _strokes
          .map(
            (item) => CanvasStrokeSnapshot(
              points: item.points
                  .map(
                    (point) => CanvasPointSnapshot(
                      dx: point.position.dx,
                      dy: point.position.dy,
                      width: point.width,
                      opacity: point.opacity,
                    ),
                  )
                  .toList(),
              modeId: item.mode.name,
              toolId: item.tool.name,
              colorValue: item.color.toARGB32(),
              layerId: item.layerId,
            ),
          )
          .toList(),
      textElements: _textElements
          .map(
            (item) => CanvasTextSnapshot(
              id: item.id,
              text: item.text,
              dx: item.position.dx,
              dy: item.position.dy,
              fontSize: item.fontSize,
              colorValue: item.color.toARGB32(),
              layerId: item.layerId,
              rotation: item.rotation,
            ),
          )
          .toList(),
      assetElements: _assetElements
          .map(
            (item) => CanvasAssetSnapshot(
              id: item.id,
              layerId: item.layerId,
              assetPath: item.assetPath,
              sourceBytesBase64: item.sourceBytesBase64,
              dx: item.position.dx,
              dy: item.position.dy,
              width: item.width,
              height: item.height,
              opacity: item.opacity,
              rotation: item.rotation,
            ),
          )
          .toList(),
      activeLayerId: _activeLayerId,
      selectedModeId: _selectedMode.name,
      selectedDifficultyId: _selectedDifficulty.name,
      selectedToolId: _selectedTool.name,
      selectedColorValue: _selectedColor.toARGB32(),
      brushScale: _brushScale,
      brushOpacity: _brushOpacity,
      showGrid: _showGrid,
      showOliveGuide: _showOliveGuide,
      showParticles: _showParticles,
      updatedAt: DateTime.now(),
    );
  }

  void _scheduleDraftSave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 450), () {
      widget.onDraftChanged(_buildDraft());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指尖画布'),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: '作品集',
            onPressed: _showPortfolioGallery,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导出项目文件',
            onPressed: _exportProjectFile,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: '文本图层',
            onPressed: _addTextElement,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '底部设置面板',
            onPressed: _showQuickSettingsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: '导出 PNG',
            onPressed: _exportCanvasSnapshot,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            onPressed: _strokes.isEmpty ? null : _undoStroke,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '重做',
            onPressed: _redoStrokes.isEmpty ? null : _redoStroke,
          ),
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
                '指尖画布',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '参考 MisaRin 的工作台思路，把原来的单一刻痕体验升级成真正可创作、可归档、可演示的数字画布。',
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
                      hint: '本地作品沉淀',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StudioMetricCard(
                      label: '解锁成就',
                      value: '$_unlockedAchievementCount',
                      hint: '成长路径可见',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StudioMetricCard(
                      label: '当前工具',
                      value: _selectedTool.label,
                      hint: _selectedDifficulty.label,
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
                    const SizedBox(height: 12),
                    _StudioBottomDock(
                      items: [
                        _StudioBottomDockItem(
                          label: '工具',
                          icon: _StudioSheetTab.tools.icon,
                          onTap: () =>
                              _showQuickSettingsSheet(_StudioSheetTab.tools),
                        ),
                        _StudioBottomDockItem(
                          label: '颜色',
                          icon: _StudioSheetTab.colors.icon,
                          onTap: () =>
                              _showQuickSettingsSheet(_StudioSheetTab.colors),
                        ),
                        _StudioBottomDockItem(
                          label: '文字',
                          icon: _StudioSheetTab.text.icon,
                          onTap: () =>
                              _showQuickSettingsSheet(_StudioSheetTab.text),
                        ),
                        _StudioBottomDockItem(
                          label: '素材',
                          icon: _StudioSheetTab.assets.icon,
                          onTap: () =>
                              _showQuickSettingsSheet(_StudioSheetTab.assets),
                        ),
                        _StudioBottomDockItem(
                          label: '图层',
                          icon: _StudioSheetTab.layers.icon,
                          onTap: () =>
                              _showQuickSettingsSheet(_StudioSheetTab.layers),
                        ),
                        _StudioBottomDockItem(
                          label: '导出',
                          icon: _StudioSheetTab.export.icon,
                          onTap: () =>
                              _showQuickSettingsSheet(_StudioSheetTab.export),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: '工具模式'),
              const SizedBox(height: 10),
              Row(
                children: CanvasTool.values.map((tool) {
                  final isSelected = _selectedTool == tool;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: tool == CanvasTool.values.last ? 0 : 10,
                      ),
                      child: _ChoiceChipCard(
                        icon: tool.icon,
                        label: tool.label,
                        selected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTool = tool;
                            _isCurrentWorkSaved = false;
                          });
                          _scheduleDraftSave();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: '笔刷预设'),
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
                          _scheduleDraftSave();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _PresetInfoCard(
                title: _selectedMode.label,
                subtitle: _selectedMode.subtitle,
                icon: _selectedMode.icon,
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: '画布场景'),
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
                          _scheduleDraftSave();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _PresetInfoCard(
                title: _selectedDifficulty.label,
                subtitle: _selectedDifficulty.subtitle,
                icon: Icons.space_dashboard_outlined,
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: '颜色与笔触'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _palette.map((color) {
                  return _ColorSwatch(
                    color: color,
                    selected: _selectedColor == color,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedColor = color;
                        _selectedTool = CanvasTool.brush;
                        _isCurrentWorkSaved = false;
                      });
                      _scheduleDraftSave();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _StudioSliderTile(
                label: '笔刷尺度',
                value: _brushScale,
                min: 0.7,
                max: 1.8,
                display: '${(_brushScale * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _brushScale = value;
                    _isCurrentWorkSaved = false;
                  });
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 10),
              _StudioSliderTile(
                label: '笔触透明度',
                value: _brushOpacity,
                min: 0.35,
                max: 1.0,
                display: '${(_brushOpacity * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _brushOpacity = value;
                    _isCurrentWorkSaved = false;
                  });
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: '参考叠层'),
              const SizedBox(height: 10),
              _StudioToggleTile(
                title: '显示网格',
                subtitle: '更接近绘画软件的工作区感受',
                value: _showGrid,
                onChanged: (value) {
                  setState(() {
                    _showGrid = value;
                  });
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 8),
              _StudioToggleTile(
                title: '显示榄核导板',
                subtitle: '保留原项目的文化主题锚点',
                value: _showOliveGuide,
                onChanged: (value) {
                  setState(() {
                    _showOliveGuide = value;
                  });
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 8),
              _StudioToggleTile(
                title: '显示颗粒碎屑',
                subtitle: '让自由画布仍保留一点榄雕质感',
                value: _showParticles,
                onChanged: (value) {
                  setState(() {
                    _showParticles = value;
                  });
                  _scheduleDraftSave();
                },
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
                        aspectRatio: 1.02,
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
                              onPanCancel: _cancelStroke,
                              child: RepaintBoundary(
                                key: _canvasBoundaryKey,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          _selectedDifficulty.paperStart,
                                          _selectedDifficulty.paperEnd,
                                        ],
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: _CarvingBoardPainter(
                                        strokes: _strokes,
                                        textElements: _textElements,
                                        assetElements: _assetElements,
                                        currentStroke: _currentPoints,
                                        layers: _layers,
                                        activeLayerId: _activeLayerId,
                                        particles: _particles,
                                        progress: _progress,
                                        currentMode: _selectedMode,
                                        currentTool: _selectedTool,
                                        currentColor: _selectedColor,
                                        scene: _selectedDifficulty,
                                        showGrid: _showGrid,
                                        showOliveGuide: _showOliveGuide,
                                        showParticles: _showParticles,
                                      ),
                                      child: Stack(
                                        children: [
                                          ..._buildCanvasElementOverlays(),
                                          Positioned(
                                            top: 14,
                                            left: 14,
                                            child: _FloatingCanvasRail(
                                              children: [
                                                _FloatingCanvasButton(
                                                  icon: CanvasTool.brush.icon,
                                                  selected:
                                                      _selectedTool ==
                                                      CanvasTool.brush,
                                                  tooltip: '画笔',
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedTool =
                                                          CanvasTool.brush;
                                                    });
                                                  },
                                                ),
                                                _FloatingCanvasButton(
                                                  icon: CanvasTool.eraser.icon,
                                                  selected:
                                                      _selectedTool ==
                                                      CanvasTool.eraser,
                                                  tooltip: '橡皮',
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedTool =
                                                          CanvasTool.eraser;
                                                    });
                                                  },
                                                ),
                                                _FloatingCanvasButton(
                                                  icon: Icons.undo,
                                                  tooltip: '撤销',
                                                  onTap: _strokes.isEmpty
                                                      ? null
                                                      : _undoStroke,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 14,
                                            right: 14,
                                            child: _FloatingCanvasRail(
                                              children: [
                                                _FloatingCanvasButton(
                                                  icon: Icons.tune,
                                                  tooltip: '设置面板',
                                                  onTap:
                                                      _showQuickSettingsSheet,
                                                ),
                                                _FloatingCanvasButton(
                                                  icon: Icons.text_fields,
                                                  tooltip: '文本图层',
                                                  onTap: _addTextElement,
                                                ),
                                                _FloatingCanvasButton(
                                                  icon: Icons.layers_outlined,
                                                  tooltip: '图层面板',
                                                  onTap: _showLayerPanel,
                                                ),
                                                _FloatingColorIndicator(
                                                  color: _selectedColor,
                                                ),
                                                _FloatingCanvasButton(
                                                  icon:
                                                      Icons.ios_share_outlined,
                                                  tooltip: '导出 PNG',
                                                  onTap: _exportCanvasSnapshot,
                                                ),
                                                _FloatingCanvasButton(
                                                  icon: Icons.redo,
                                                  tooltip: '重做',
                                                  onTap: _redoStrokes.isEmpty
                                                      ? null
                                                      : _redoStroke,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Center(
                                            child: IgnorePointer(
                                              child: AnimatedOpacity(
                                                opacity: _strokeCount > 0
                                                    ? 0.0
                                                    : 1.0,
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 18,
                                                        vertical: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withAlphaValue(0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    '拖动手指开始作画',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 16,
                                            right: 16,
                                            bottom: 16,
                                            child: IgnorePointer(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withAlphaValue(
                                                              0.18,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _selectedDifficulty
                                                            .subtitle,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 12,
                                                          height: 1.6,
                                                        ),
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
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _CanvasActionButton(
                          label: '撤销',
                          icon: Icons.undo,
                          onPressed: _strokes.isEmpty ? null : _undoStroke,
                        ),
                        _CanvasActionButton(
                          label: '重做',
                          icon: Icons.redo,
                          onPressed: _redoStrokes.isEmpty ? null : _redoStroke,
                        ),
                        _CanvasActionButton(
                          label: '重置画布',
                          icon: Icons.refresh,
                          onPressed:
                              (_strokes.isEmpty && _currentPoints.isEmpty)
                              ? null
                              : _resetBoard,
                        ),
                        _CanvasActionButton(
                          label: _isCurrentWorkSaved ? '已归档' : '归档作品',
                          icon: Icons.inventory_2_outlined,
                          highlighted: true,
                          onPressed: _progress >= 1 && !_isCurrentWorkSaved
                              ? _saveWork
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '当前图层',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_activeLayer.name} · ${_strokeCountForLayer(_activeLayer.id)} 笔触',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _showLayerPanel,
                            icon: const Icon(Icons.layers_outlined),
                            label: const Text('管理图层'),
                          ),
                        ],
                      ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_latestRecord!.previewImageBase64.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(
                                    _latestRecord!.previewImageBase64,
                                  ),
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_latestRecord!.exportImagePath.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openExportPath(_latestRecord!.exportImagePath),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('打开导出文件'),
                        ),
                      ],
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
                      '工作流说明',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. 先选择画笔、场景和颜色。\n2. 在画布区域拖动即可绘制，支持撤销与重做。\n3. 进度达到 100% 后归档作品，让互动区真正产出可展示内容。',
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
    if (!_isInsideCanvas(position, size)) {
      return;
    }
    if (_activeLayer.locked || !_activeLayer.visible) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前图层已锁定或隐藏，请切换可编辑图层')));
      return;
    }
    HapticFeedback.selectionClick();
    final width = _strokeWidth(position, null);
    setState(() {
      _isCurrentWorkSaved = false;
      _redoStrokes.clear();
      _currentPoints = [
        CarvingPoint(
          position: position,
          width: width,
          opacity: _effectiveOpacity,
        ),
      ];
      if (_showParticles && _selectedTool == CanvasTool.brush) {
        _spawnParticles(position);
      }
    });
    _scheduleDraftSave();
  }

  void _appendPoint(Offset position, Size size) {
    if (_currentPoints.isEmpty || !_isInsideCanvas(position, size)) {
      return;
    }

    final previous = _currentPoints.last.position;
    final distance = (position - previous).distance;
    final minimumSpacing = _selectedTool == CanvasTool.eraser
        ? _selectedMode.spacing * 0.72
        : _selectedMode.spacing;
    if (distance < minimumSpacing) {
      return;
    }

    final width = _strokeWidth(position, previous);
    final nextTick = (_strokeCount + _currentPoints.length) ~/ 3;
    if (nextTick > _lastHapticTick) {
      _lastHapticTick = nextTick;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentPoints.add(
        CarvingPoint(
          position: position,
          width: width,
          opacity: _effectiveOpacity,
        ),
      );
      if (_showParticles && _selectedTool == CanvasTool.brush) {
        _spawnParticles(position);
      }
    });
    _scheduleDraftSave();
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
          tool: _selectedTool,
          color: _selectedColor,
          layerId: _activeLayerId,
        ),
      );
      _currentPoints = [];
      if (_progress >= 1) {
        HapticFeedback.mediumImpact();
      }
    });
    _scheduleDraftSave();
  }

  void _cancelStroke() {
    if (_currentPoints.isEmpty) {
      return;
    }
    setState(() {
      _currentPoints = [];
    });
    _scheduleDraftSave();
  }

  double get _effectiveOpacity {
    if (_selectedTool == CanvasTool.eraser) {
      return 1.0;
    }
    return (_brushOpacity * _selectedMode.opacityFactor).clamp(0.16, 1.0);
  }

  double _strokeWidth(Offset position, Offset? previous) {
    final baseWidth =
        _selectedMode.baseWidth *
        _selectedDifficulty.widthFactor *
        _brushScale *
        (_selectedTool == CanvasTool.eraser ? 1.18 : 1.0);
    if (previous == null) {
      return baseWidth;
    }
    final velocity = ((position - previous).distance / 24).clamp(0.0, 1.0);
    final pressureCurve = 1.16 - velocity * 0.38;
    final variance =
        0.94 + (math.sin((position.dx + position.dy) * 0.04) * 0.08);
    return (baseWidth * pressureCurve * variance).clamp(1.2, 24.0);
  }

  bool _isInsideCanvas(Offset point, Size size) {
    return point.dx >= 6 &&
        point.dy >= 6 &&
        point.dx <= size.width - 6 &&
        point.dy <= size.height - 6;
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
      _redoStrokes.clear();
      _currentPoints = [];
      _particles.clear();
      _isCurrentWorkSaved = false;
      _lastHapticTick = 0;
    });
    _scheduleDraftSave();
  }

  void _undoStroke() {
    if (_strokes.isEmpty) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _redoStrokes.add(_strokes.removeLast());
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _redoStroke() {
    if (_redoStrokes.isEmpty) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.add(_redoStrokes.removeLast());
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  int _strokeCountForLayer(String layerId) {
    return _strokes.where((item) => item.layerId == layerId).length;
  }

  void _addLayer() {
    final nextIndex = _layers.length + 1;
    final nextLayer = CanvasLayerData(
      id: 'layer_$nextIndex',
      name: '图层 $nextIndex',
      visible: true,
      locked: false,
      opacity: 1,
      blend: CanvasLayerBlend.normal,
    );
    HapticFeedback.selectionClick();
    setState(() {
      _layers = [nextLayer, ..._layers];
      _activeLayerId = nextLayer.id;
    });
    _scheduleDraftSave();
  }

  void _selectLayer(String layerId) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeLayerId = layerId;
    });
  }

  void _toggleLayerVisibility(String layerId) {
    final layer = _layers.firstWhere((item) => item.id == layerId);
    if (_layers.length == 1 && layer.visible) {
      return;
    }
    setState(() {
      _layers = _layers
          .map(
            (item) => item.id == layerId
                ? item.copyWith(visible: !item.visible)
                : item,
          )
          .toList();
    });
    _scheduleDraftSave();
  }

  void _toggleLayerLock(String layerId) {
    setState(() {
      _layers = _layers
          .map(
            (item) =>
                item.id == layerId ? item.copyWith(locked: !item.locked) : item,
          )
          .toList();
    });
    _scheduleDraftSave();
  }

  void _moveLayer(String layerId, int offset) {
    final currentIndex = _layers.indexWhere((item) => item.id == layerId);
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = (currentIndex + offset).clamp(0, _layers.length - 1);
    if (nextIndex == currentIndex) {
      return;
    }
    final nextLayers = List<CanvasLayerData>.from(_layers);
    final item = nextLayers.removeAt(currentIndex);
    nextLayers.insert(nextIndex, item);
    setState(() {
      _layers = nextLayers;
    });
    _scheduleDraftSave();
  }

  void _setLayerOpacity(String layerId, double opacity) {
    setState(() {
      _layers = _layers
          .map(
            (item) => item.id == layerId
                ? item.copyWith(opacity: opacity.clamp(0.1, 1.0))
                : item,
          )
          .toList();
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _setLayerBlend(String layerId, CanvasLayerBlend blend) {
    setState(() {
      _layers = _layers
          .map(
            (item) => item.id == layerId ? item.copyWith(blend: blend) : item,
          )
          .toList();
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  Future<void> _renameLayer(String layerId) async {
    final layer = _layers.firstWhere((item) => item.id == layerId);
    final controller = TextEditingController(text: layer.name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('重命名图层'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '图层名称',
              hintText: '例如：高光 / 线稿 / 背景',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
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
    if (!mounted || nextName == null || nextName.isEmpty) {
      return;
    }
    setState(() {
      _layers = _layers
          .map(
            (item) => item.id == layerId ? item.copyWith(name: nextName) : item,
          )
          .toList();
    });
    _scheduleDraftSave();
  }

  Future<void> _addTextElement() async {
    if (_activeLayer.locked || !_activeLayer.visible) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前图层不可编辑，请先切换到可见且未锁定的图层')));
      return;
    }
    final controller = TextEditingController();
    final sizeController = TextEditingController(text: '28');
    final result = await showDialog<(String, double)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('添加文本图层'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '文本内容',
                    hintText: '例如：榄核里的山海',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '字号',
                    hintText: '例如：28',
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
                final fontSize =
                    double.tryParse(sizeController.text.trim()) ?? 28;
                Navigator.of(context).pop((controller.text.trim(), fontSize));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null || result.$1.isEmpty) {
      return;
    }
    setState(() {
      final textElement = CanvasTextElement(
        id: 'text_${DateTime.now().microsecondsSinceEpoch}',
        text: result.$1,
        position: const Offset(120, 120),
        fontSize: result.$2.clamp(14, 72),
        color: _selectedColor,
        layerId: _activeLayerId,
        rotation: 0,
      );
      _textElements.add(textElement);
      _selectedTextId = textElement.id;
      _selectedAssetId = null;
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  Future<void> _editSelectedTextElement() async {
    final selectedText = _selectedText;
    if (selectedText == null) {
      return;
    }
    final controller = TextEditingController(text: selectedText.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('编辑文本'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '文本内容',
              hintText: '请输入新的文字内容',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
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
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    setState(() {
      for (int i = 0; i < _textElements.length; i++) {
        if (_textElements[i].id == selectedText.id) {
          _textElements[i] = _textElements[i].copyWith(text: result);
          break;
        }
      }
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  Future<void> _addAssetElement() async {
    if (_activeLayer.locked || !_activeLayer.visible) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前图层不可编辑，请先切换到可见且未锁定的图层')));
      return;
    }
    final pickedExhibit = await showModalBottomSheet<Exhibit>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white10),
          ),
          child: SafeArea(
            top: false,
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
                const Text(
                  '导入素材',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.availableExhibits.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final exhibit = widget.availableExhibits[index];
                      return SizedBox(
                        width: 180,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).pop(exhibit),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                      child: Image.asset(
                                        exhibit.image,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      exhibit.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || pickedExhibit == null) {
      return;
    }
    final image = await _loadAssetUiImage(pickedExhibit.image);
    if (!mounted || image == null) {
      return;
    }
    final maxSide = math.max(image.width.toDouble(), image.height.toDouble());
    final scale = 140 / maxSide;
    final width = image.width * scale;
    final height = image.height * scale;
    setState(() {
      final asset = CanvasAssetElement(
        id: 'asset_${DateTime.now().microsecondsSinceEpoch}',
        layerId: _activeLayerId,
        assetPath: pickedExhibit.image,
        sourceBytesBase64: '',
        image: image,
        position: const Offset(120, 180),
        width: width,
        height: height,
        opacity: 1,
        rotation: 0,
      );
      _assetElements.add(asset);
      _selectedAssetId = asset.id;
      _selectedTextId = null;
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  Future<void> _importLocalImage() async {
    if (_activeLayer.locked || !_activeLayer.visible) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前图层不可编辑，请先切换到可见且未锁定的图层')));
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前文件暂时无法读取，请换一张图片再试')));
        }
        return;
      }
      final image = await _loadUiImageFromBytes(bytes);
      if (!mounted || image == null) {
        return;
      }
      final maxSide = math.max(image.width.toDouble(), image.height.toDouble());
      final scale = 180 / maxSide;
      final width = image.width * scale;
      final height = image.height * scale;
      setState(() {
        final asset = CanvasAssetElement(
          id: 'asset_${DateTime.now().microsecondsSinceEpoch}',
          layerId: _activeLayerId,
          assetPath: file.name,
          sourceBytesBase64: base64Encode(bytes),
          image: image,
          position: const Offset(140, 180),
          width: width,
          height: height,
          opacity: 1,
          rotation: 0,
        );
        _assetElements.add(asset);
        _selectedAssetId = asset.id;
        _selectedTextId = null;
        _isCurrentWorkSaved = false;
      });
      _scheduleDraftSave();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导入本地图片失败，请稍后重试')));
    }
  }

  Future<ui.Image?> _loadAssetUiImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _loadUiImageFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _selectTextElement(String id) {
    setState(() {
      _selectedTextId = id;
      _selectedAssetId = null;
    });
  }

  void _selectAssetElement(String id) {
    setState(() {
      _selectedAssetId = id;
      _selectedTextId = null;
    });
  }

  void _moveTextElement(String id, Offset delta) {
    setState(() {
      _textElements.replaceRange(
        0,
        _textElements.length,
        _textElements.map(
          (item) => item.id == id
              ? item.copyWith(position: item.position + delta)
              : item,
        ),
      );
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _resizeSelectedText(double fontSize) {
    if (_selectedText == null) {
      return;
    }
    setState(() {
      _textElements.replaceRange(
        0,
        _textElements.length,
        _textElements.map(
          (item) => item.id == _selectedTextId
              ? item.copyWith(fontSize: fontSize.clamp(14, 96))
              : item,
        ),
      );
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _rotateSelectedText(double rotation) {
    if (_selectedText == null) {
      return;
    }
    setState(() {
      _textElements.replaceRange(
        0,
        _textElements.length,
        _textElements.map(
          (item) => item.id == _selectedTextId
              ? item.copyWith(rotation: rotation)
              : item,
        ),
      );
      _isCurrentWorkSaved = false;
    });
  }

  void _moveAssetElement(String id, Offset delta) {
    setState(() {
      _assetElements.replaceRange(
        0,
        _assetElements.length,
        _assetElements.map(
          (item) => item.id == id
              ? item.copyWith(position: item.position + delta)
              : item,
        ),
      );
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _deleteSelectedElement() {
    if (_selectedTextId == null && _selectedAssetId == null) {
      return;
    }
    setState(() {
      if (_selectedTextId != null) {
        _textElements.removeWhere((item) => item.id == _selectedTextId);
        _selectedTextId = null;
      }
      if (_selectedAssetId != null) {
        _assetElements.removeWhere((item) => item.id == _selectedAssetId);
        _selectedAssetId = null;
      }
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _resizeSelectedAsset(double width) {
    final selectedAsset = _selectedAsset;
    if (selectedAsset == null) {
      return;
    }
    final ratio = selectedAsset.height / selectedAsset.width;
    setState(() {
      _assetElements.replaceRange(
        0,
        _assetElements.length,
        _assetElements.map(
          (item) => item.id == _selectedAssetId
              ? item.copyWith(
                  width: width.clamp(72, 260),
                  height: width.clamp(72, 260) * ratio,
                )
              : item,
        ),
      );
      _isCurrentWorkSaved = false;
    });
    _scheduleDraftSave();
  }

  void _rotateSelectedAsset(double rotation) {
    final selectedAsset = _selectedAsset;
    if (selectedAsset == null) {
      return;
    }
    setState(() {
      _assetElements.replaceRange(
        0,
        _assetElements.length,
        _assetElements.map(
          (item) => item.id == _selectedAssetId
              ? item.copyWith(rotation: rotation)
              : item,
        ),
      );
      _isCurrentWorkSaved = false;
    });
  }

  Future<void> _showPortfolioGallery() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PortfolioGalleryScreen(
          records: _history,
          onOpenExport: _openExportPath,
        ),
      ),
    );
  }

  List<Widget> _buildCanvasElementOverlays() {
    final widgets = <Widget>[];
    for (final asset in _assetElements) {
      final layer = _layers.firstWhere(
        (item) => item.id == asset.layerId,
        orElse: () => _activeLayer,
      );
      if (!layer.visible) {
        continue;
      }
      widgets.add(
        Positioned(
          left: asset.position.dx,
          top: asset.position.dy,
          child: GestureDetector(
            onTap: () => _selectAssetElement(asset.id),
            onPanUpdate: (details) =>
                _moveAssetElement(asset.id, details.delta),
            child: Transform.rotate(
              angle: asset.rotation * math.pi / 180,
              child: Container(
                width: asset.width,
                height: asset.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: _selectedAssetId == asset.id
                      ? Border.all(color: AppColors.accent, width: 2)
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final textItem in _textElements) {
      final layer = _layers.firstWhere(
        (item) => item.id == textItem.layerId,
        orElse: () => _activeLayer,
      );
      if (!layer.visible) {
        continue;
      }
      final size = _measureTextElement(textItem);
      widgets.add(
        Positioned(
          left: textItem.position.dx,
          top: textItem.position.dy,
          child: GestureDetector(
            onTap: () => _selectTextElement(textItem.id),
            onPanUpdate: (details) =>
                _moveTextElement(textItem.id, details.delta),
            child: Transform.rotate(
              angle: textItem.rotation * math.pi / 180,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTextId == textItem.id
                      ? Border.all(color: AppColors.accent, width: 1.6)
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Size _measureTextElement(CanvasTextElement item) {
    final painter = TextPainter(
      text: TextSpan(
        text: item.text,
        style: TextStyle(
          color: item.color,
          fontSize: item.fontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: 220);
    return painter.size;
  }

  CarvingRecord _copyRecordWith(
    CarvingRecord source, {
    String? previewImageBase64,
    String? exportImagePath,
  }) {
    return CarvingRecord(
      title: source.title,
      note: source.note,
      modeId: source.modeId,
      modeLabel: source.modeLabel,
      difficultyId: source.difficultyId,
      difficultyLabel: source.difficultyLabel,
      timestamp: source.timestamp,
      strokeCount: source.strokeCount,
      previewImageBase64: previewImageBase64 ?? source.previewImageBase64,
      exportImagePath: exportImagePath ?? source.exportImagePath,
    );
  }

  void _attachExportToLatestRecord({
    required String exportImagePath,
    required Uint8List bytes,
  }) {
    if (!_isCurrentWorkSaved || _history.isEmpty || exportImagePath.isEmpty) {
      return;
    }
    final nextHistory = List<CarvingRecord>.from(_history);
    final latest = nextHistory.removeLast();
    nextHistory.add(
      _copyRecordWith(
        latest,
        previewImageBase64: latest.previewImageBase64.isEmpty
            ? base64Encode(bytes)
            : latest.previewImageBase64,
        exportImagePath: exportImagePath,
      ),
    );
    setState(() {
      _history = nextHistory;
    });
    widget.onHistoryChanged(nextHistory);
  }

  Future<void> _openExportPath(String path) async {
    final opened = await openSavedExport(path);
    if (!mounted) {
      return;
    }
    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前环境无法直接打开导出文件')));
    }
  }

  void _removeActiveLayer() {
    if (_layers.length == 1) {
      return;
    }
    final removingLayerId = _activeLayerId;
    HapticFeedback.lightImpact();
    setState(() {
      _layers = _layers.where((item) => item.id != removingLayerId).toList();
      _activeLayerId = _layers.first.id;
      _strokes.removeWhere((item) => item.layerId == removingLayerId);
      _redoStrokes.removeWhere((item) => item.layerId == removingLayerId);
      _isCurrentWorkSaved = false;
    });
  }

  void _showLayerPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void sync(VoidCallback action) {
              action();
              setSheetState(() {});
            }

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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '图层面板',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => sync(_addLayer),
                          icon: const Icon(Icons.add),
                          tooltip: '新建图层',
                        ),
                        IconButton(
                          onPressed: _layers.length > 1
                              ? () => sync(_removeActiveLayer)
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '删除当前图层',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._layers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final layer = entry.value;
                      final isActive = layer.id == _activeLayerId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LayerTile(
                          layer: layer,
                          isActive: isActive,
                          strokeCount: _strokeCountForLayer(layer.id),
                          strokes: _strokes
                              .where((item) => item.layerId == layer.id)
                              .toList(),
                          canMoveUp: index > 0,
                          canMoveDown: index < _layers.length - 1,
                          onTap: () => sync(() => _selectLayer(layer.id)),
                          onRename: () async {
                            await _renameLayer(layer.id);
                            setSheetState(() {});
                          },
                          onToggleVisibility: () =>
                              sync(() => _toggleLayerVisibility(layer.id)),
                          onToggleLock: () =>
                              sync(() => _toggleLayerLock(layer.id)),
                          onMoveUp: () => sync(() => _moveLayer(layer.id, -1)),
                          onMoveDown: () => sync(() => _moveLayer(layer.id, 1)),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '当前图层透明度',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${(_activeLayer.opacity * 100).round()}%',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _activeLayer.opacity,
                            min: 0.1,
                            max: 1,
                            onChanged: (value) => sync(
                              () => _setLayerOpacity(_activeLayerId, value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '当前图层混合模式',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DropdownButton<CanvasLayerBlend>(
                            value: _activeLayer.blend,
                            underline: const SizedBox.shrink(),
                            dropdownColor: AppColors.surface,
                            items: CanvasLayerBlend.values
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
                              sync(() => _setLayerBlend(_activeLayerId, value));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveWork() async {
    if (_progress < 1 || _isCurrentWorkSaved) {
      return;
    }

    final draft = await _showSaveDraftDialog();
    if (!mounted || draft == null) {
      return;
    }

    final snapshotBytes = await _captureCanvasPngBytes(pixelRatio: 1.8);
    if (!mounted) {
      return;
    }
    final previewImageBase64 = snapshotBytes == null || snapshotBytes.isEmpty
        ? ''
        : base64Encode(snapshotBytes);
    final exportImagePath =
        !kIsWeb && snapshotBytes != null && snapshotBytes.isNotEmpty
        ? (await saveCanvasPng(snapshotBytes, _buildExportFileName()) ?? '')
        : '';
    if (!mounted) {
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
        previewImageBase64: previewImageBase64,
        exportImagePath: exportImagePath,
      ),
    ];

    setState(() {
      _history = nextHistory;
      _isCurrentWorkSaved = true;
    });
    _scheduleDraftSave();

    widget.onHistoryChanged(nextHistory);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('《${draft.title}》已归档到本地作品档案'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Future<Uint8List?> _captureCanvasPngBytes({double pixelRatio = 2.0}) async {
    final boundaryContext = _canvasBoundaryKey.currentContext;
    if (boundaryContext == null) {
      return null;
    }
    final boundary =
        boundaryContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  String _buildExportFileName() {
    final timestamp = DateTime.now();
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final year = timestamp.year.toString();
    return 'olive_canvas_$year$month${day}_$hour$minute';
  }

  String _buildProjectFileName() {
    final timestamp = DateTime.now();
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final year = timestamp.year.toString();
    return 'olive_project_$year$month${day}_$hour$minute.olivejson';
  }

  Future<void> _exportProjectFile() async {
    try {
      final payload = jsonEncode({
        'type': 'olive_canvas_project',
        'version': 1,
        'draft': _buildDraft().toJson(),
      });
      final path = await FilePicker.saveFile(
        dialogTitle: '导出项目文件',
        fileName: _buildProjectFileName(),
        type: FileType.custom,
        allowedExtensions: ['olivejson'],
        bytes: Uint8List.fromList(utf8.encode(payload)),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null || path.isEmpty ? '项目文件已导出' : '项目文件已导出到：$path',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导出项目文件失败，请稍后重试')));
    }
  }

  Future<void> _importProjectFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['olivejson', 'json'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前项目文件无法读取')));
        }
        return;
      }
      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final draftJson = decoded['draft'] as Map<String, dynamic>? ?? decoded;
      final draft = CanvasProjectDraft.fromJson(draftJson);
      await _restoreDraft(draft);
      if (!mounted) {
        return;
      }
      widget.onDraftChanged(draft);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('项目文件已导入，画布状态已恢复')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导入项目文件失败，请确认文件格式正确')));
    }
  }

  Future<void> _exportCanvasSnapshot() async {
    final bytes = await _captureCanvasPngBytes(pixelRatio: 2.4);
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前画布暂时无法导出，请稍后重试')));
      return;
    }

    String? savedPath;
    if (!kIsWeb) {
      savedPath = await saveCanvasPng(bytes, _buildExportFileName());
    }

    if (savedPath != null && savedPath.isNotEmpty) {
      _attachExportToLatestRecord(exportImagePath: savedPath, bytes: bytes);
    }

    if (!mounted) {
      return;
    }
    await _showExportPreview(bytes, savedPath: savedPath);
  }

  Future<void> _showExportPreview(Uint8List bytes, {String? savedPath}) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('导出预览'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 240,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  savedPath == null || savedPath.isEmpty
                      ? '当前环境未写入本地文件，但已经生成了 PNG 预览。'
                      : 'PNG 已导出到：$savedPath',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (savedPath != null && savedPath.isNotEmpty)
              TextButton(
                onPressed: () => _openExportPath(savedPath),
                child: const Text('打开文件'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickSettingsSheet([
    _StudioSheetTab initialTab = _StudioSheetTab.tools,
  ]) {
    var activeTab = initialTab;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void sync(VoidCallback action) {
              setState(action);
              setSheetState(() {});
              _scheduleDraftSave();
            }

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
                      const Text(
                        '快速设置',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _StudioSheetTab.values.map((tab) {
                          return ChoiceChip(
                            label: Text(tab.label),
                            avatar: Icon(tab.icon, size: 16),
                            selected: activeTab == tab,
                            onSelected: (_) {
                              setSheetState(() {
                                activeTab = tab;
                              });
                            },
                            selectedColor: AppColors.accent,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: activeTab == tab
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: AppColors.surfaceSoft,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      _buildQuickSheetContent(activeTab, sync),
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

  Widget _buildQuickSheetContent(
    _StudioSheetTab activeTab,
    void Function(VoidCallback action) sync,
  ) {
    switch (activeTab) {
      case _StudioSheetTab.tools:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '工具'),
            const SizedBox(height: 10),
            Row(
              children: CanvasTool.values.map((tool) {
                final isSelected = _selectedTool == tool;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: tool == CanvasTool.values.last ? 0 : 10,
                    ),
                    child: _ChoiceChipCard(
                      icon: tool.icon,
                      label: tool.label,
                      selected: isSelected,
                      onTap: () => sync(() {
                        _selectedTool = tool;
                        _isCurrentWorkSaved = false;
                      }),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: '笔刷预设'),
            const SizedBox(height: 10),
            ...CarvingMode.values.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PresetInfoCard(
                  title: mode.label,
                  subtitle: mode.subtitle,
                  icon: mode.icon,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionTitle(title: '画布场景'),
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
                      onTap: () => sync(() {
                        _selectedDifficulty = difficulty;
                        _isCurrentWorkSaved = false;
                      }),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      case _StudioSheetTab.colors:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '颜色'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((color) {
                return _ColorSwatch(
                  color: color,
                  selected: _selectedColor == color,
                  onTap: () => sync(() {
                    _selectedColor = color;
                    _selectedTool = CanvasTool.brush;
                    _isCurrentWorkSaved = false;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _StudioSliderTile(
              label: '笔刷尺度',
              value: _brushScale,
              min: 0.7,
              max: 1.8,
              display: '${(_brushScale * 100).round()}%',
              onChanged: (value) => sync(() {
                _brushScale = value;
                _isCurrentWorkSaved = false;
              }),
            ),
            const SizedBox(height: 10),
            _StudioSliderTile(
              label: '笔触透明度',
              value: _brushOpacity,
              min: 0.35,
              max: 1.0,
              display: '${(_brushOpacity * 100).round()}%',
              onChanged: (value) => sync(() {
                _brushOpacity = value;
                _isCurrentWorkSaved = false;
              }),
            ),
            const SizedBox(height: 10),
            _StudioToggleTile(
              title: '显示网格',
              subtitle: '更接近绘画软件的工作区感受',
              value: _showGrid,
              onChanged: (value) => sync(() {
                _showGrid = value;
              }),
            ),
          ],
        );
      case _StudioSheetTab.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '文字图层'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _addTextElement,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('添加文字'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedText != null
                      ? _editSelectedTextElement
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑文字'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedText != null
                      ? _deleteSelectedElement
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除文字'),
                ),
              ],
            ),
            if (_selectedText != null) ...[
              const SizedBox(height: 16),
              Text(
                '当前选中：${_selectedText!.text}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _StudioSliderTile(
                label: '文字大小',
                value: _selectedText!.fontSize,
                min: 14,
                max: 96,
                display: '${_selectedText!.fontSize.round()} px',
                onChanged: _resizeSelectedText,
              ),
              const SizedBox(height: 10),
              _StudioSliderTile(
                label: '文字旋转',
                value: _selectedText!.rotation,
                min: -180,
                max: 180,
                display: '${_selectedText!.rotation.round()}°',
                onChanged: _rotateSelectedText,
              ),
            ],
          ],
        );
      case _StudioSheetTab.assets:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '素材贴图'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _addAssetElement,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('导入馆藏素材'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _importLocalImage,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('导入本地图片'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedAsset != null
                      ? _deleteSelectedElement
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除素材'),
                ),
              ],
            ),
            if (_selectedAsset != null) ...[
              const SizedBox(height: 16),
              Text(
                '当前素材：${_selectedAsset!.assetPath.split('/').last}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _StudioSliderTile(
                label: '素材宽度',
                value: _selectedAsset!.width,
                min: 72,
                max: 260,
                display: '${_selectedAsset!.width.round()} px',
                onChanged: _resizeSelectedAsset,
              ),
              const SizedBox(height: 10),
              _StudioSliderTile(
                label: '素材旋转',
                value: _selectedAsset!.rotation,
                min: -180,
                max: 180,
                display: '${_selectedAsset!.rotation.round()}°',
                onChanged: _rotateSelectedAsset,
              ),
            ],
          ],
        );
      case _StudioSheetTab.layers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _SectionTitle(title: '图层概览')),
                TextButton.icon(
                  onPressed: _showLayerPanel,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('展开完整图层面板'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._layers
                .take(3)
                .map(
                  (layer) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LayerTile(
                      layer: layer,
                      isActive: layer.id == _activeLayerId,
                      strokeCount: _strokeCountForLayer(layer.id),
                      strokes: _strokes
                          .where((item) => item.layerId == layer.id)
                          .toList(),
                      canMoveUp: false,
                      canMoveDown: false,
                      onTap: () => sync(() => _selectLayer(layer.id)),
                      onRename: () async {
                        await _renameLayer(layer.id);
                        sync(() {});
                      },
                      onToggleVisibility: () =>
                          sync(() => _toggleLayerVisibility(layer.id)),
                      onToggleLock: () =>
                          sync(() => _toggleLayerLock(layer.id)),
                      onMoveUp: () {},
                      onMoveDown: () {},
                    ),
                  ),
                ),
          ],
        );
      case _StudioSheetTab.export:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '导出与归档'),
            const SizedBox(height: 10),
            Text(
              _latestRecord?.exportImagePath.isNotEmpty == true
                  ? '最近归档作品已关联导出文件。'
                  : '导出后会生成 PNG，并尽量回写到最近一次归档记录中。',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!mounted) {
                  return;
                }
                await _exportCanvasSnapshot();
              },
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('导出当前画布'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _exportProjectFile,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('导出项目文件'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _importProjectFile,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('导入项目文件'),
            ),
            if (_latestRecord != null &&
                _latestRecord!.exportImagePath.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    _openExportPath(_latestRecord!.exportImagePath),
                icon: const Icon(Icons.folder_open),
                label: const Text('打开最近导出文件'),
              ),
            ],
          ],
        );
    }
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
                        leading: item.previewImageBase64.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(item.previewImageBase64),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                _modeFromId(item.modeId).icon,
                                color: AppColors.accent,
                              ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.modeLabel} · ${item.difficultyLabel} · ${_formatTimestamp(item.timestamp)}',
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.strokeCount} 笔',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (item.exportImagePath.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    _openExportPath(item.exportImagePath),
                                child: const Text('打开'),
                              ),
                          ],
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

class _PresetInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PresetInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? AppColors.accent : Colors.white24,
              width: selected ? 2.5 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withAlphaValue(0.22),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _StudioSliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  const _StudioSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                display,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StudioToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StudioToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CanvasActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback? onPressed;

  const _CanvasActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = highlighted
        ? FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.accent.withAlphaValue(0.35),
            disabledForegroundColor: Colors.black54,
          )
        : FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceSoft,
            foregroundColor: AppColors.textPrimary,
            disabledBackgroundColor: AppColors.surfaceSoft.withAlphaValue(0.68),
            disabledForegroundColor: Colors.white38,
            side: const BorderSide(color: Colors.white10),
          );
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _StudioBottomDockItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StudioBottomDockItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _StudioBottomDock extends StatelessWidget {
  final List<_StudioBottomDockItem> items;

  const _StudioBottomDock({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: item.onTap,
                icon: Icon(item.icon, size: 18),
                label: Text(item.label),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FloatingCanvasRail extends StatelessWidget {
  final List<Widget> children;

  const _FloatingCanvasRail({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlphaValue(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            children
                .expand((item) => [item, const SizedBox(height: 8)])
                .toList()
              ..removeLast(),
      ),
    );
  }
}

class _FloatingCanvasButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback? onTap;

  const _FloatingCanvasButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? AppColors.accent.withAlphaValue(0.92)
            : Colors.white.withAlphaValue(0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: selected ? Colors.black : AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingColorIndicator extends StatelessWidget {
  final Color color;

  const _FloatingColorIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white54),
      ),
    );
  }
}

class _LayerThumbnail extends StatelessWidget {
  final List<CarvingStroke> strokes;
  final double opacity;

  const _LayerThumbnail({required this.strokes, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _LayerThumbnailPainter(strokes: strokes, opacity: opacity),
        ),
      ),
    );
  }
}

class _LayerThumbnailPainter extends CustomPainter {
  final List<CarvingStroke> strokes;
  final double opacity;

  const _LayerThumbnailPainter({required this.strokes, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppColors.surfaceSoft;
    canvas.drawRect(Offset.zero & size, background);
    if (strokes.isEmpty) {
      final placeholder = Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
          const Radius.circular(10),
        ),
        placeholder,
      );
      return;
    }

    final allPoints = strokes.expand((item) => item.points).toList();
    if (allPoints.isEmpty) {
      return;
    }
    var minX = allPoints.first.position.dx;
    var minY = allPoints.first.position.dy;
    var maxX = allPoints.first.position.dx;
    var maxY = allPoints.first.position.dy;
    for (final point in allPoints) {
      minX = math.min(minX, point.position.dx);
      minY = math.min(minY, point.position.dy);
      maxX = math.max(maxX, point.position.dx);
      maxY = math.max(maxY, point.position.dy);
    }
    final width = math.max(maxX - minX, 1);
    final height = math.max(maxY - minY, 1);
    final scale = math.min(
      (size.width - 10) / width,
      (size.height - 10) / height,
    );
    final offset = Offset(
      (size.width - width * scale) / 2,
      (size.height - height * scale) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) {
        continue;
      }
      if (stroke.tool == CanvasTool.eraser) {
        continue;
      }
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final a = stroke.points[i];
        final b = stroke.points[i + 1];
        paint
          ..color = stroke.color.withAlphaValue(opacity * 0.8)
          ..strokeWidth = math.max(
            ((a.width + b.width) / 2) * scale * 0.14,
            1.0,
          );
        canvas.drawLine(
          Offset(
                (a.position.dx - minX) * scale,
                (a.position.dy - minY) * scale,
              ) +
              offset,
          Offset(
                (b.position.dx - minX) * scale,
                (b.position.dy - minY) * scale,
              ) +
              offset,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LayerThumbnailPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.opacity != opacity;
  }
}

class PortfolioGalleryScreen extends StatelessWidget {
  final List<CarvingRecord> records;
  final Future<void> Function(String path) onOpenExport;

  const PortfolioGalleryScreen({
    super.key,
    required this.records,
    required this.onOpenExport,
  });

  @override
  Widget build(BuildContext context) {
    final orderedRecords = records.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('作品集'),
        actions: [
          if (orderedRecords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.slideshow),
              tooltip: '演示模式',
              onPressed: () => _openPortfolioPresentation(
                context,
                orderedRecords,
                onOpenExport,
              ),
            ),
        ],
      ),
      body: orderedRecords.isEmpty
          ? const Center(
              child: Text(
                '还没有归档作品，先在画布里完成一张作品吧。',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: _PortfolioSpotlightCard(
                      count: orderedRecords.length,
                      latest: orderedRecords.first,
                      onPresent: () => _openPortfolioPresentation(
                        context,
                        orderedRecords,
                        onOpenExport,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = orderedRecords[index];
                      return _PortfolioCardReveal(
                        index: index,
                        child: _PortfolioGridCard(
                          item: item,
                          onOpenExport: onOpenExport,
                          onTap: () => _openPortfolioPresentation(
                            context,
                            orderedRecords,
                            onOpenExport,
                            initialIndex: index,
                          ),
                        ),
                      );
                    }, childCount: orderedRecords.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

void _openPortfolioPresentation(
  BuildContext context,
  List<CarvingRecord> records,
  Future<void> Function(String path) onOpenExport, {
  int initialIndex = 0,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 650),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (routeContext, animation, secondaryAnimation) =>
          FadeTransition(
            opacity: animation,
            child: _PortfolioPresentationScreen(
              records: records,
              onOpenExport: onOpenExport,
              initialIndex: initialIndex,
            ),
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

String _portfolioHeroTag(CarvingRecord record) {
  return 'portfolio_${record.timestamp.toIso8601String()}_${record.title}';
}

class _PortfolioSpotlightCard extends StatelessWidget {
  final int count;
  final CarvingRecord latest;
  final VoidCallback onPresent;

  const _PortfolioSpotlightCard({
    required this.count,
    required this.latest,
    required this.onPresent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F241B), Color(0xFF121212)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '作品集已归档 $count 组成果',
            style: TextStyle(
              color: AppColors.accent.withAlphaValue(0.96),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '这里已经不是作品列表，而是一套可以直接进答辩演示的成果编排。',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '最新作品《${latest.title}》可直接进入全屏演示模式，用共享元素转场和自动播放节奏讲完整个创作闭环。',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPresent,
            icon: const Icon(Icons.slideshow),
            label: const Text('进入演示模式'),
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

class _PortfolioCardReveal extends StatelessWidget {
  final int index;
  final Widget child;

  const _PortfolioCardReveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              child: animatedChild,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PortfolioGridCard extends StatelessWidget {
  final CarvingRecord item;
  final Future<void> Function(String path) onOpenExport;
  final VoidCallback onTap;

  const _PortfolioGridCard({
    required this.item,
    required this.onOpenExport,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: _portfolioHeroTag(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item.previewImageBase64.isNotEmpty
                        ? Image.memory(
                            base64Decode(item.previewImageBase64),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surfaceSoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.accent,
                              size: 36,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.modeLabel} · ${item.difficultyLabel}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              if (item.exportImagePath.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => onOpenExport(item.exportImagePath),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('打开导出文件'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioPresentationScreen extends StatefulWidget {
  final List<CarvingRecord> records;
  final Future<void> Function(String path) onOpenExport;
  final int initialIndex;

  const _PortfolioPresentationScreen({
    required this.records,
    required this.onOpenExport,
    required this.initialIndex,
  });

  @override
  State<_PortfolioPresentationScreen> createState() =>
      _PortfolioPresentationScreenState();
}

class _PortfolioPresentationScreenState
    extends State<_PortfolioPresentationScreen> {
  late final PageController _pageController;
  late int _index;
  Timer? _autoPlayTimer;
  bool _autoPlaying = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAutoPlay() {
    if (_autoPlaying) {
      _autoPlayTimer?.cancel();
      setState(() {
        _autoPlaying = false;
      });
      return;
    }
    setState(() {
      _autoPlaying = true;
    });
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final records = widget.records.reversed.toList();
      if (_index >= records.length - 1) {
        timer.cancel();
        setState(() {
          _autoPlaying = false;
        });
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _presentationCue(CarvingRecord record) {
    if (record.difficultyId == Difficulty.hard.name) {
      return '这一张适合答辩展示，版面完整，适合直接讲“从创作到成图”的闭环。';
    }
    if (record.modeId == CarvingMode.fine.name) {
      return '这一张可以重点讲细节控制和边缘处理，体现笔刷系统不是一次性特效。';
    }
    if (record.exportImagePath.isNotEmpty) {
      return '这一张已经可以导出成正式文件，说明系统具备可交付成果能力。';
    }
    return '这一张适合讲画布工作流和图层组织，体现项目已经超出普通交互原型。';
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    final pagePosition = _pageController.hasClients
        ? (_pageController.page ?? _index.toDouble())
        : _index.toDouble();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _toggleAutoPlay,
                    icon: Icon(
                      _autoPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1}/${records.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: records.length,
                onPageChanged: (value) {
                  setState(() {
                    _index = value;
                  });
                },
                itemBuilder: (context, index) {
                  final record = records[index];
                  final distance = (pagePosition - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - (distance * 0.08);
                  final opacity = 1 - (distance * 0.28);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Hero(
                                  tag: _portfolioHeroTag(record),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: record.previewImageBase64.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(
                                              record.previewImageBase64,
                                            ),
                                            fit: BoxFit.contain,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            color: AppColors.surface,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: AppColors.accent,
                                              size: 64,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Container(
                                key: ValueKey(
                                  record.timestamp.toIso8601String(),
                                ),
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlphaValue(0.08),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${record.modeLabel} · ${record.difficultyLabel} · ${record.strokeCount} 笔',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (record.note.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        record.note,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          height: 1.7,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlphaValue(
                                          0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _presentationCue(record),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.7,
                                        ),
                                      ),
                                    ),
                                    if (record.exportImagePath.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      OutlinedButton.icon(
                                        onPressed: () => widget.onOpenExport(
                                          record.exportImagePath,
                                        ),
                                        icon: const Icon(Icons.folder_open),
                                        label: const Text('打开导出文件'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: records.isEmpty ? 0 : (_index + 1) / records.length,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  color: AppColors.accent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index > 0
                          ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            )
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('上一张'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _index < records.length - 1
                          ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            )
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('下一张'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final CanvasLayerData layer;
  final bool isActive;
  final int strokeCount;
  final List<CarvingStroke> strokes;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _LayerTile({
    required this.layer,
    required this.isActive,
    required this.strokeCount,
    required this.strokes,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTap,
    required this.onRename,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onMoveUp,
    required this.onMoveDown,
  });

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
            color: isActive
                ? AppColors.accent.withAlphaValue(0.14)
                : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.white10,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _LayerThumbnail(strokes: strokes, opacity: layer.opacity),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          layer.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$strokeCount 笔触 · ${layer.blend.label} · ${(layer.opacity * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRename,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '重命名',
                  ),
                  IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      layer.visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: '显示 / 隐藏',
                  ),
                  IconButton(
                    onPressed: onToggleLock,
                    icon: Icon(
                      layer.locked
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                    ),
                    tooltip: '锁定 / 解锁',
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: canMoveUp ? onMoveUp : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    label: const Text('上移'),
                  ),
                  TextButton.icon(
                    onPressed: canMoveDown ? onMoveDown : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    label: const Text('下移'),
                  ),
                  if (isActive)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '当前编辑',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
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
  final List<CanvasTextElement> textElements;
  final List<CanvasAssetElement> assetElements;
  final List<CarvingPoint> currentStroke;
  final List<CanvasLayerData> layers;
  final String activeLayerId;
  final List<WoodParticle> particles;
  final double progress;
  final CarvingMode currentMode;
  final CanvasTool currentTool;
  final Color currentColor;
  final Difficulty scene;
  final bool showGrid;
  final bool showOliveGuide;
  final bool showParticles;

  const _CarvingBoardPainter({
    required this.strokes,
    required this.textElements,
    required this.assetElements,
    required this.currentStroke,
    required this.layers,
    required this.activeLayerId,
    required this.particles,
    required this.progress,
    required this.currentMode,
    required this.currentTool,
    required this.currentColor,
    required this.scene,
    required this.showGrid,
    required this.showOliveGuide,
    required this.showParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paperPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scene.paperStart, scene.paperEnd],
      ).createShader(rect);
    canvas.drawRect(rect, paperPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withAlphaValue(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(rect.deflate(10), shadowPaint);

    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF3B3128).withAlphaValue(0.12)
        ..strokeWidth = 1;
      for (double x = 0; x <= size.width; x += 28) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y <= size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    final oliveRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.5,
      height: size.height * 0.68,
    );
    if (showOliveGuide) {
      final guidePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A684A), Color(0xFF4A3525)],
        ).createShader(oliveRect);
      canvas.drawOval(oliveRect, guidePaint);

      final texturePaint = Paint()
        ..color = const Color(0xFFFFF1D8).withAlphaValue(0.12)
        ..strokeWidth = 1;
      for (double y = oliveRect.top + 18; y < oliveRect.bottom - 18; y += 16) {
        final inset = (y - oliveRect.center.dy).abs() * 0.17;
        canvas.drawLine(
          Offset(oliveRect.left + 22 + inset, y),
          Offset(oliveRect.right - 22 - inset, y + 4),
          texturePaint,
        );
      }
    }

    if (scene == Difficulty.hard) {
      final frameRect = rect.deflate(22);
      final framePaint = Paint()
        ..color = AppColors.accent.withAlphaValue(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(18)),
        framePaint,
      );
    }

    canvas.saveLayer(rect, Paint());
    for (final layer in layers.reversed) {
      if (!layer.visible) {
        continue;
      }
      for (final stroke in strokes.where((item) => item.layerId == layer.id)) {
        _drawStroke(canvas, stroke, layer.opacity, layer.blend.blendMode);
      }
      for (final asset in assetElements.where(
        (item) => item.layerId == layer.id,
      )) {
        _drawAsset(canvas, asset, layer.opacity, layer.blend.blendMode);
      }
      for (final textItem in textElements.where(
        (item) => item.layerId == layer.id,
      )) {
        _drawText(canvas, textItem, layer.opacity, layer.blend.blendMode);
      }
    }
    if (currentStroke.length > 1) {
      _drawStroke(
        canvas,
        CarvingStroke(
          points: currentStroke,
          mode: currentMode,
          tool: currentTool,
          color: currentColor,
          layerId: activeLayerId,
        ),
        _activeLayerOpacity,
        _activeLayerBlendMode,
      );
    }
    canvas.restore();

    if (showParticles) {
      final particlePaint = Paint()..style = PaintingStyle.fill;
      for (final particle in particles) {
        particlePaint.color = AppColors.accent.withAlphaValue(particle.opacity);
        canvas.drawCircle(particle.position, particle.radius, particlePaint);
      }
    }

    final glowPaint = Paint()
      ..color = AppColors.accent.withAlphaValue(0.06 + progress * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRect(rect, glowPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withAlphaValue(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(rect.deflate(0.6), borderPaint);
  }

  double get _activeLayerOpacity {
    for (final layer in layers) {
      if (layer.id == activeLayerId) {
        return layer.opacity;
      }
    }
    return 1;
  }

  BlendMode get _activeLayerBlendMode {
    for (final layer in layers) {
      if (layer.id == activeLayerId) {
        return layer.blend.blendMode;
      }
    }
    return BlendMode.srcOver;
  }

  void _drawStroke(
    Canvas canvas,
    CarvingStroke stroke,
    double layerOpacity,
    BlendMode layerBlendMode,
  ) {
    if (stroke.points.length < 2) {
      return;
    }
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final highlightPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final current = stroke.points[i];
      final next = stroke.points[i + 1];
      final width = (current.width + next.width) / 2;
      final opacity = ((current.opacity + next.opacity) / 2).clamp(0.0, 1.0);

      if (stroke.tool == CanvasTool.eraser) {
        paint
          ..blendMode = BlendMode.clear
          ..maskFilter = null
          ..color = Colors.transparent
          ..strokeWidth = width;
        canvas.drawLine(current.position, next.position, paint);
        continue;
      }

      paint
        ..blendMode = layerBlendMode
        ..strokeWidth = width
        ..color = stroke.color.withAlphaValue(opacity * layerOpacity);

      switch (stroke.mode) {
        case CarvingMode.rough:
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
        case CarvingMode.fine:
          paint.maskFilter = null;
        case CarvingMode.hollow:
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
      }

      canvas.drawLine(current.position, next.position, paint);

      if (stroke.mode == CarvingMode.hollow) {
        highlightPaint
          ..color = Colors.white.withAlphaValue(opacity * layerOpacity * 0.22)
          ..strokeWidth = math.max(width * 0.36, 1.0);
        canvas.drawLine(current.position, next.position, highlightPaint);
      }
    }
  }

  void _drawText(
    Canvas canvas,
    CanvasTextElement textItem,
    double layerOpacity,
    BlendMode layerBlendMode,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textItem.text,
        style: TextStyle(
          color: textItem.color.withAlphaValue(layerOpacity),
          fontSize: textItem.fontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: 220);
    canvas.save();
    canvas.translate(textItem.position.dx, textItem.position.dy);
    canvas.rotate(textItem.rotation * math.pi / 180);
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, textPainter.width, textPainter.height),
      Paint()..blendMode = layerBlendMode,
    );
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
    canvas.restore();
  }

  void _drawAsset(
    Canvas canvas,
    CanvasAssetElement asset,
    double layerOpacity,
    BlendMode layerBlendMode,
  ) {
    final paint = Paint()
      ..blendMode = layerBlendMode
      ..color = Colors.white.withAlphaValue(asset.opacity * layerOpacity);
    canvas.save();
    canvas.translate(asset.position.dx, asset.position.dy);
    canvas.rotate(asset.rotation * math.pi / 180);
    canvas.drawImageRect(
      asset.image,
      Rect.fromLTWH(
        0,
        0,
        asset.image.width.toDouble(),
        asset.image.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, asset.width, asset.height),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CarvingBoardPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.textElements != textElements ||
        oldDelegate.assetElements != assetElements ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.layers != layers ||
        oldDelegate.activeLayerId != activeLayerId ||
        oldDelegate.particles != particles ||
        oldDelegate.progress != progress ||
        oldDelegate.currentMode != currentMode ||
        oldDelegate.currentTool != currentTool ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.scene != scene ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showOliveGuide != showOliveGuide ||
        oldDelegate.showParticles != showParticles;
  }
}
