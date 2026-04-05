import 'app_models.dart';
import 'product_models.dart';

class ExperienceInsights {
  final List<Exhibit> publishedExhibits;
  final List<Exhibit> featuredExhibits;
  final List<Exhibit> recentExhibits;
  final double learningProgress;
  final int engagementScore;
  final String stageLabel;
  final String stageSummary;
  final String dominantCategory;
  final FeaturedCollection? recommendedCollection;
  final String recommendationReason;
  final ServiceInquiry? latestInquiry;

  const ExperienceInsights({
    required this.publishedExhibits,
    required this.featuredExhibits,
    required this.recentExhibits,
    required this.learningProgress,
    required this.engagementScore,
    required this.stageLabel,
    required this.stageSummary,
    required this.dominantCategory,
    required this.recommendedCollection,
    required this.recommendationReason,
    required this.latestInquiry,
  });

  factory ExperienceInsights.fromState({
    required AppContent content,
    required AppUserState userState,
    required AdminWorkspace adminWorkspace,
  }) {
    final publishedExhibits = content.exhibits
        .where((item) => adminWorkspace.stateFor(item.id).published)
        .toList();
    final featuredExhibits = publishedExhibits
        .where((item) => adminWorkspace.stateFor(item.id).featured)
        .toList();
    final exhibitById = {
      for (final exhibit in publishedExhibits) exhibit.id: exhibit,
    };
    final recentExhibits = userState.recentExhibitIds
        .map((id) => exhibitById[id])
        .whereType<Exhibit>()
        .toList();
    final learningProgress = content.craftSteps.isEmpty
        ? 0.0
        : userState.learnedStepTitles.length / content.craftSteps.length;
    final dominantCategory = _resolveDominantCategory(
      publishedExhibits: publishedExhibits,
      favoriteIds: userState.favoriteExhibitIds,
      recentIds: userState.recentExhibitIds,
    );
    final recommendedCollection = _recommendCollection(
      collections: content.featuredCollections,
      publishedExhibits: publishedExhibits,
      favoriteIds: userState.favoriteExhibitIds,
      recentIds: userState.recentExhibitIds,
      dominantCategory: dominantCategory,
    );
    final recommendationReason = _buildRecommendationReason(
      collection: recommendedCollection,
      exhibitById: exhibitById,
      favoriteIds: userState.favoriteExhibitIds,
      recentIds: userState.recentExhibitIds,
      dominantCategory: dominantCategory,
    );
    final latestInquiry = userState.serviceInquiries.isEmpty
        ? null
        : userState.serviceInquiries.last;
    final engagementScore = _computeEngagementScore(
      favoriteCount: userState.favoriteExhibitIds.length,
      recentCount: recentExhibits.length,
      learnedCount: userState.learnedStepTitles.length,
      carvingCount: userState.carvingHistory.length,
      inquiryCount: userState.serviceInquiries.length,
    );
    final stage = _resolveStage(
      learningProgress: learningProgress,
      carvingCount: userState.carvingHistory.length,
      inquiryCount: userState.serviceInquiries.length,
      favoriteCount: userState.favoriteExhibitIds.length,
    );

    return ExperienceInsights(
      publishedExhibits: publishedExhibits,
      featuredExhibits: featuredExhibits,
      recentExhibits: recentExhibits,
      learningProgress: learningProgress,
      engagementScore: engagementScore,
      stageLabel: stage.$1,
      stageSummary: stage.$2,
      dominantCategory: dominantCategory,
      recommendedCollection: recommendedCollection,
      recommendationReason: recommendationReason,
      latestInquiry: latestInquiry,
    );
  }

  static String _resolveDominantCategory({
    required List<Exhibit> publishedExhibits,
    required Set<String> favoriteIds,
    required List<String> recentIds,
  }) {
    final exhibitById = {
      for (final exhibit in publishedExhibits) exhibit.id: exhibit,
    };
    final weights = <String, int>{};

    void register(Exhibit? exhibit, int weight) {
      if (exhibit == null) {
        return;
      }
      weights.update(
        exhibit.category,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
    }

    for (final favoriteId in favoriteIds) {
      register(exhibitById[favoriteId], 4);
    }

    for (var i = 0; i < recentIds.length; i++) {
      register(exhibitById[recentIds[i]], recentIds.length - i + 1);
    }

    if (weights.isEmpty) {
      return '未形成偏好';
    }

    return weights.entries.reduce((best, next) {
      if (next.value > best.value) {
        return next;
      }
      return best;
    }).key;
  }

  static FeaturedCollection? _recommendCollection({
    required List<FeaturedCollection> collections,
    required List<Exhibit> publishedExhibits,
    required Set<String> favoriteIds,
    required List<String> recentIds,
    required String dominantCategory,
  }) {
    if (collections.isEmpty) {
      return null;
    }

    final exhibitById = {
      for (final exhibit in publishedExhibits) exhibit.id: exhibit,
    };
    final recentSet = recentIds.toSet();
    FeaturedCollection? bestCollection;
    var bestScore = -1;

    for (final collection in collections) {
      var score = 0;
      for (final exhibitId in collection.exhibitIds) {
        if (favoriteIds.contains(exhibitId)) {
          score += 6;
        }
        if (recentSet.contains(exhibitId)) {
          score += 4;
        }
        final exhibit = exhibitById[exhibitId];
        if (exhibit != null && exhibit.category == dominantCategory) {
          score += 3;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCollection = collection;
      }
    }

    return bestCollection ?? collections.first;
  }

  static String _buildRecommendationReason({
    required FeaturedCollection? collection,
    required Map<String, Exhibit> exhibitById,
    required Set<String> favoriteIds,
    required List<String> recentIds,
    required String dominantCategory,
  }) {
    if (collection == null) {
      return '当前内容正在准备中，稍后会出现策展推荐。';
    }

    final focusExhibits = collection.exhibitIds
        .where((id) => favoriteIds.contains(id) || recentIds.contains(id))
        .map((id) => exhibitById[id])
        .whereType<Exhibit>()
        .toList();
    if (focusExhibits.isNotEmpty) {
      final names = focusExhibits
          .take(2)
          .map((item) => '《${item.title}》')
          .join('、');
      return '这条路线和你最近关注的 $names 关联度更高，适合直接延续观看节奏。';
    }
    if (dominantCategory != '未形成偏好') {
      return '你最近更偏向 $dominantCategory 题材，这条路线能更集中地展示该方向的层次与代表作品。';
    }
    return '这是当前最适合作为首轮导览的策展路线，能快速建立对榄雕题材与工艺的整体感知。';
  }

  static int _computeEngagementScore({
    required int favoriteCount,
    required int recentCount,
    required int learnedCount,
    required int carvingCount,
    required int inquiryCount,
  }) {
    final rawScore =
        favoriteCount * 10 +
        recentCount * 5 +
        learnedCount * 8 +
        carvingCount * 12 +
        inquiryCount * 18;
    if (rawScore <= 0) {
      return 0;
    }
    if (rawScore >= 100) {
      return 100;
    }
    return rawScore;
  }

  static (String, String) _resolveStage({
    required double learningProgress,
    required int carvingCount,
    required int inquiryCount,
    required int favoriteCount,
  }) {
    if (favoriteCount == 0 && learningProgress == 0 && carvingCount == 0) {
      return ('新访客阶段', '建议先从策展路线开始，再逐步建立收藏、学习和互动沉淀。');
    }
    if (learningProgress < 0.45) {
      return ('内容理解阶段', '你已经开始形成观看偏好，继续完成工艺阅读会让整体叙事更完整。');
    }
    if (carvingCount == 0) {
      return ('体验深化阶段', '你已经具备较完整的内容认知，下一步适合进入指尖工坊形成作品沉淀。');
    }
    if (inquiryCount == 0) {
      return ('方案展示阶段', '项目已经具备展示、学习和互动闭环，再补上服务登记就是更完整的商业化演示。');
    }
    return ('业务闭环阶段', '当前版本已经同时具备内容体验与转化入口，足以支撑更正式的提案或演示场景。');
  }
}
