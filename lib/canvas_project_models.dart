class CanvasPointSnapshot {
  final double dx;
  final double dy;
  final double width;
  final double opacity;

  const CanvasPointSnapshot({
    required this.dx,
    required this.dy,
    required this.width,
    required this.opacity,
  });

  factory CanvasPointSnapshot.fromJson(Map<String, dynamic> json) {
    return CanvasPointSnapshot(
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dx': dx,
    'dy': dy,
    'width': width,
    'opacity': opacity,
  };
}

class CanvasStrokeSnapshot {
  final List<CanvasPointSnapshot> points;
  final String modeId;
  final String toolId;
  final int colorValue;
  final String layerId;

  const CanvasStrokeSnapshot({
    required this.points,
    required this.modeId,
    required this.toolId,
    required this.colorValue,
    required this.layerId,
  });

  factory CanvasStrokeSnapshot.fromJson(Map<String, dynamic> json) {
    return CanvasStrokeSnapshot(
      points: ((json['points'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                CanvasPointSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      modeId: json['modeId'] as String,
      toolId: json['toolId'] as String,
      colorValue: json['colorValue'] as int,
      layerId: json['layerId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((item) => item.toJson()).toList(),
    'modeId': modeId,
    'toolId': toolId,
    'colorValue': colorValue,
    'layerId': layerId,
  };
}

class CanvasLayerSnapshot {
  final String id;
  final String name;
  final bool visible;
  final bool locked;
  final double opacity;
  final String blendId;

  const CanvasLayerSnapshot({
    required this.id,
    required this.name,
    required this.visible,
    required this.locked,
    required this.opacity,
    required this.blendId,
  });

  factory CanvasLayerSnapshot.fromJson(Map<String, dynamic> json) {
    return CanvasLayerSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      blendId: json['blendId'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'visible': visible,
    'locked': locked,
    'opacity': opacity,
    'blendId': blendId,
  };
}

class CanvasTextSnapshot {
  final String id;
  final String text;
  final double dx;
  final double dy;
  final double fontSize;
  final int colorValue;
  final String layerId;
  final double rotation;

  const CanvasTextSnapshot({
    required this.id,
    required this.text,
    required this.dx,
    required this.dy,
    required this.fontSize,
    required this.colorValue,
    required this.layerId,
    required this.rotation,
  });

  factory CanvasTextSnapshot.fromJson(Map<String, dynamic> json) {
    return CanvasTextSnapshot(
      id: json['id'] as String,
      text: json['text'] as String,
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      layerId: json['layerId'] as String,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'dx': dx,
    'dy': dy,
    'fontSize': fontSize,
    'colorValue': colorValue,
    'layerId': layerId,
    'rotation': rotation,
  };
}

class CanvasAssetSnapshot {
  final String id;
  final String layerId;
  final String assetPath;
  final String sourceBytesBase64;
  final double dx;
  final double dy;
  final double width;
  final double height;
  final double opacity;
  final double rotation;

  const CanvasAssetSnapshot({
    required this.id,
    required this.layerId,
    required this.assetPath,
    required this.sourceBytesBase64,
    required this.dx,
    required this.dy,
    required this.width,
    required this.height,
    required this.opacity,
    required this.rotation,
  });

  factory CanvasAssetSnapshot.fromJson(Map<String, dynamic> json) {
    return CanvasAssetSnapshot(
      id: json['id'] as String,
      layerId: json['layerId'] as String,
      assetPath: json['assetPath'] as String? ?? '',
      sourceBytesBase64: json['sourceBytesBase64'] as String? ?? '',
      dx: (json['dx'] as num).toDouble(),
      dy: (json['dy'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'layerId': layerId,
    'assetPath': assetPath,
    'sourceBytesBase64': sourceBytesBase64,
    'dx': dx,
    'dy': dy,
    'width': width,
    'height': height,
    'opacity': opacity,
    'rotation': rotation,
  };
}

class CanvasProjectDraft {
  final List<CanvasLayerSnapshot> layers;
  final List<CanvasStrokeSnapshot> strokes;
  final List<CanvasTextSnapshot> textElements;
  final List<CanvasAssetSnapshot> assetElements;
  final String activeLayerId;
  final String selectedModeId;
  final String selectedDifficultyId;
  final String selectedToolId;
  final int selectedColorValue;
  final double brushScale;
  final double brushOpacity;
  final bool showGrid;
  final bool showOliveGuide;
  final bool showParticles;
  final DateTime updatedAt;

  const CanvasProjectDraft({
    required this.layers,
    required this.strokes,
    required this.textElements,
    required this.assetElements,
    required this.activeLayerId,
    required this.selectedModeId,
    required this.selectedDifficultyId,
    required this.selectedToolId,
    required this.selectedColorValue,
    required this.brushScale,
    required this.brushOpacity,
    required this.showGrid,
    required this.showOliveGuide,
    required this.showParticles,
    required this.updatedAt,
  });

  factory CanvasProjectDraft.fromJson(Map<String, dynamic> json) {
    return CanvasProjectDraft(
      layers: ((json['layers'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                CanvasLayerSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      strokes: ((json['strokes'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                CanvasStrokeSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      textElements: ((json['textElements'] as List<dynamic>?) ?? [])
          .map(
            (item) => CanvasTextSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      assetElements: ((json['assetElements'] as List<dynamic>?) ?? [])
          .map(
            (item) =>
                CanvasAssetSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      activeLayerId: json['activeLayerId'] as String? ?? 'layer_base',
      selectedModeId: json['selectedModeId'] as String? ?? 'rough',
      selectedDifficultyId: json['selectedDifficultyId'] as String? ?? 'medium',
      selectedToolId: json['selectedToolId'] as String? ?? 'brush',
      selectedColorValue: json['selectedColorValue'] as int? ?? 0xFF251B14,
      brushScale: (json['brushScale'] as num?)?.toDouble() ?? 1,
      brushOpacity: (json['brushOpacity'] as num?)?.toDouble() ?? 0.88,
      showGrid: json['showGrid'] as bool? ?? true,
      showOliveGuide: json['showOliveGuide'] as bool? ?? true,
      showParticles: json['showParticles'] as bool? ?? true,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'layers': layers.map((item) => item.toJson()).toList(),
    'strokes': strokes.map((item) => item.toJson()).toList(),
    'textElements': textElements.map((item) => item.toJson()).toList(),
    'assetElements': assetElements.map((item) => item.toJson()).toList(),
    'activeLayerId': activeLayerId,
    'selectedModeId': selectedModeId,
    'selectedDifficultyId': selectedDifficultyId,
    'selectedToolId': selectedToolId,
    'selectedColorValue': selectedColorValue,
    'brushScale': brushScale,
    'brushOpacity': brushOpacity,
    'showGrid': showGrid,
    'showOliveGuide': showOliveGuide,
    'showParticles': showParticles,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
