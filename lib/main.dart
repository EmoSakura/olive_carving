import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'interaction_screen.dart';

class AppColors {
  static const Color background = Color(0xFF111111);
  static const Color surface = Color(0xFF1C1C1C);
  static const Color surfaceSoft = Color(0xFF26221D);
  static const Color accent = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFF2EEE7);
  static const Color textSecondary = Color(0xFFAEA79B);
  static const Color ink = Color(0xFF3E2F23);
}

class IntroPageData {
  final String title;
  final String subtitle;
  final String note;

  const IntroPageData({
    required this.title,
    required this.subtitle,
    required this.note,
  });

  factory IntroPageData.fromJson(Map<String, dynamic> json) {
    return IntroPageData(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      note: json['note'] as String,
    );
  }
}

class Exhibit {
  final String id;
  final String title;
  final String author;
  final String era;
  final String category;
  final String technique;
  final String description;
  final String story;
  final String image;

  const Exhibit({
    required this.id,
    required this.title,
    required this.author,
    required this.era,
    required this.category,
    required this.technique,
    required this.description,
    required this.story,
    required this.image,
  });

  factory Exhibit.fromJson(Map<String, dynamic> json) {
    return Exhibit(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      era: json['era'] as String,
      category: json['category'] as String,
      technique: json['technique'] as String,
      description: json['description'] as String,
      story: json['story'] as String,
      image: json['image'] as String,
    );
  }
}

class CraftStep {
  final String title;
  final String summary;
  final String detail;
  final String focus;

  const CraftStep({
    required this.title,
    required this.summary,
    required this.detail,
    required this.focus,
  });

  factory CraftStep.fromJson(Map<String, dynamic> json) {
    return CraftStep(
      title: json['title'] as String,
      summary: json['summary'] as String,
      detail: json['detail'] as String,
      focus: json['focus'] as String,
    );
  }
}

class AppContent {
  final List<IntroPageData> introPages;
  final List<Exhibit> exhibits;
  final List<CraftStep> craftSteps;
  final String featuredQuote;

  const AppContent({
    required this.introPages,
    required this.exhibits,
    required this.craftSteps,
    required this.featuredQuote,
  });

  factory AppContent.fromJson(Map<String, dynamic> json) {
    return AppContent(
      introPages: (json['introPages'] as List<dynamic>)
          .map((item) => IntroPageData.fromJson(item as Map<String, dynamic>))
          .toList(),
      exhibits: (json['exhibits'] as List<dynamic>)
          .map((item) => Exhibit.fromJson(item as Map<String, dynamic>))
          .toList(),
      craftSteps: (json['craftSteps'] as List<dynamic>)
          .map((item) => CraftStep.fromJson(item as Map<String, dynamic>))
          .toList(),
      featuredQuote: json['featuredQuote'] as String,
    );
  }
}

class LocalContentRepository {
  const LocalContentRepository();

  Future<AppContent> load() async {
    final rawJson = await rootBundle.loadString('assets/data/content.json');
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return AppContent.fromJson(decoded);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const OliveApp());
}

class OliveApp extends StatelessWidget {
  const OliveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '榄雕云艺·数字传承',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with SingleTickerProviderStateMixin {
  late final Future<AppContent> _contentFuture;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _contentFuture = const LocalContentRepository().load();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _showIntro = true;
        });
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
    return FutureBuilder<AppContent>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _BootstrapErrorView();
        }

        if (!snapshot.hasData || !_showIntro) {
          return SplashScreen(fadeAnimation: _fadeAnimation);
        }

        return IntroScreen(content: snapshot.data!);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const SplashScreen({
    super.key,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SplashBackdrop()),
          Center(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withOpacity(0.7)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.16),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.accent,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '榄雕云艺',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '数字传承 · 指尖沉浸',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.9),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroScreen extends StatefulWidget {
  final AppContent content;

  const IntroScreen({
    super.key,
    required this.content,
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '新中式极简主义',
                style: TextStyle(
                  color: AppColors.accent.withOpacity(0.9),
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '让非遗以更轻盈的方式被看见',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.content.introPages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = widget.content.introPages[index];
                    return _IntroCard(page: page);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: List.generate(
                  widget.content.introPages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: index == _pageIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: index == _pageIndex
                          ? AppColors.accent
                          : AppColors.textSecondary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.content.featuredQuote,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationScreen(content: widget.content),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    '进入榄雕云艺',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final AppContent content;

  const MainNavigationScreen({
    super.key,
    required this.content,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Set<String> _favoriteExhibitIds = <String>{};
  final List<String> _recentExhibitIds = <String>[];
  final Set<String> _learnedStepTitles = <String>{};

  void _toggleFavoriteExhibit(String exhibitId) {
    setState(() {
      if (!_favoriteExhibitIds.add(exhibitId)) {
        _favoriteExhibitIds.remove(exhibitId);
      }
    });
  }

  void _registerExhibitViewed(String exhibitId) {
    setState(() {
      _recentExhibitIds.remove(exhibitId);
      _recentExhibitIds.insert(0, exhibitId);
      if (_recentExhibitIds.length > 5) {
        _recentExhibitIds.removeRange(5, _recentExhibitIds.length);
      }
    });
  }

  void _markStepLearned(String stepTitle) {
    setState(() {
      _learnedStepTitles.add(stepTitle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      GalleryScreen(
        exhibits: widget.content.exhibits,
        favoriteExhibitIds: _favoriteExhibitIds,
        recentExhibitIds: _recentExhibitIds,
        onToggleFavorite: _toggleFavoriteExhibit,
        onExhibitViewed: _registerExhibitViewed,
      ),
      ProcessScreen(
        steps: widget.content.craftSteps,
        learnedStepTitles: _learnedStepTitles,
        onStepLearned: _markStepLearned,
      ),
      const InteractionScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.accent.withOpacity(0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '数字展馆',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: '工艺解构',
          ),
          NavigationDestination(
            icon: Icon(Icons.gesture_outlined),
            selectedIcon: Icon(Icons.gesture),
            label: '指尖互动',
          ),
        ],
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  final List<Exhibit> exhibits;
  final Set<String> favoriteExhibitIds;
  final List<String> recentExhibitIds;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onExhibitViewed;

  const GalleryScreen({
    super.key,
    required this.exhibits,
    required this.favoriteExhibitIds,
    required this.recentExhibitIds,
    required this.onToggleFavorite,
    required this.onExhibitViewed,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _selectedCategory = '全部';
  String _searchQuery = '';
  bool _favoritesOnly = false;

  List<String> get _categories => [
        '全部',
        ...widget.exhibits.map((e) => e.category).toSet(),
      ];

  List<Exhibit> get _filteredExhibits {
    return widget.exhibits.where((item) {
      final matchesCategory =
          _selectedCategory == '全部' || item.category == _selectedCategory;
      final matchesFavorite =
          !_favoritesOnly || widget.favoriteExhibitIds.contains(item.id);
      final query = _searchQuery.trim().toLowerCase();
      final searchableText =
          '${item.title} ${item.author} ${item.category} ${item.technique} ${item.era}'
              .toLowerCase();
      final matchesSearch = query.isEmpty || searchableText.contains(query);
      return matchesCategory && matchesFavorite && matchesSearch;
    }).toList();
  }

  List<Exhibit> get _recentExhibits => widget.recentExhibitIds
      .map(
        (id) => widget.exhibits.cast<Exhibit?>().firstWhere(
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
        SliverAppBar(
          expandedHeight: 176,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            title: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '数字展馆',
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
                  colors: [Color(0xFF231B16), Color(0xFF111111)],
                ),
              ),
              child: const _DecorativeGrid(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '看见榄雕在极小尺度中的结构、人物与空间层次。',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _GalleryMetricCard(
                        label: '展品总数',
                        value: '${widget.exhibits.length}',
                        hint: '已收录作品',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GalleryMetricCard(
                        label: '我的收藏',
                        value: '${widget.favoriteExhibitIds.length}',
                        hint: '重点标记',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GalleryMetricCard(
                        label: '最近浏览',
                        value: '${_recentExhibits.length}',
                        hint: '便于回看',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '搜索作品名称、作者、题材或技法',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.85),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: AppColors.accent,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: _categories.length,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _favoritesOnly = !_favoritesOnly;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _favoritesOnly
                          ? AppColors.accent.withOpacity(0.16)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _favoritesOnly ? AppColors.accent : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _favoritesOnly ? Icons.star : Icons.star_border,
                          color: _favoritesOnly
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _favoritesOnly ? '当前仅看收藏作品' : '点击切换为仅看收藏',
                          style: TextStyle(
                            color: _favoritesOnly
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_recentExhibits.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    '最近浏览',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentExhibits.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final exhibit = _recentExhibits[index];
                        return ActionChip(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: Colors.white10),
                          label: Text(
                            exhibit.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            widget.onExhibitViewed(exhibit.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExhibitDetailScreen(
                                  exhibit: exhibit,
                                  isFavorite: widget.favoriteExhibitIds.contains(
                                    exhibit.id,
                                  ),
                                  onToggleFavorite: () =>
                                      widget.onToggleFavorite(exhibit.id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          sliver: _filteredExhibits.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.travel_explore_outlined,
                          color: AppColors.accent,
                          size: 36,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '当前筛选条件下暂无匹配展品',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '你可以切换题材、关闭收藏筛选，或修改搜索关键词后再试。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exhibit = _filteredExhibits[index];
                      final aspectRatio = index.isEven ? 0.72 : 0.84;
                      return _GalleryCard(
                        exhibit: exhibit,
                        aspectRatio: aspectRatio,
                        isFavorite: widget.favoriteExhibitIds.contains(exhibit.id),
                        onToggleFavorite: () =>
                            widget.onToggleFavorite(exhibit.id),
                        onOpen: () {
                          widget.onExhibitViewed(exhibit.id);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExhibitDetailScreen(
                                exhibit: exhibit,
                                isFavorite: widget.favoriteExhibitIds.contains(
                                  exhibit.id,
                                ),
                                onToggleFavorite: () =>
                                    widget.onToggleFavorite(exhibit.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: _filteredExhibits.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                ),
        ),
      ],
    );
  }
}

class _GalleryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _GalleryMetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 20,
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

class _GalleryCard extends StatelessWidget {
  final Exhibit exhibit;
  final double aspectRatio;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _GalleryCard({
    required this.exhibit,
    required this.aspectRatio,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: (aspectRatio * 100).toInt(),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: exhibit.id,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: AssetArtwork(
                              path: exhibit.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: onToggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isFavorite ? Icons.star : Icons.star_border,
                                color: isFavorite
                                    ? AppColors.accent
                                    : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exhibit.title,
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
                        '${exhibit.era} · ${exhibit.category}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          exhibit.technique,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
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
    );
  }
}

class ExhibitDetailScreen extends StatefulWidget {
  final Exhibit exhibit;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const ExhibitDetailScreen({
    super.key,
    required this.exhibit,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<ExhibitDetailScreen> createState() => _ExhibitDetailScreenState();
}

class _ExhibitDetailScreenState extends State<ExhibitDetailScreen> {
  bool _showInfo = true;

  @override
  Widget build(BuildContext context) {
    final exhibit = widget.exhibit;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Hero(
                tag: exhibit.id,
                child: AssetArtwork(
                  path: exhibit.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _CircleAction(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  _CircleAction(
                    icon: _showInfo ? Icons.visibility_off : Icons.visibility,
                    onTap: () {
                      setState(() {
                        _showInfo = !_showInfo;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _CircleAction(
                    icon: widget.isFavorite ? Icons.star : Icons.star_border,
                    onTap: widget.onToggleFavorite,
                  ),
                ],
              ),
            ),
          ),
          if (_showInfo)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.82),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exhibit.title,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              exhibit.category,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _DetailMetaRow(label: '作者', value: exhibit.author),
                      const SizedBox(height: 10),
                      _DetailMetaRow(label: '年代', value: exhibit.era),
                      const SizedBox(height: 10),
                      _DetailMetaRow(label: '技法', value: exhibit.technique),
                      const SizedBox(height: 18),
                      Text(
                        exhibit.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          exhibit.story,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProcessScreen extends StatefulWidget {
  final List<CraftStep> steps;
  final Set<String> learnedStepTitles;
  final ValueChanged<String> onStepLearned;

  const ProcessScreen({
    super.key,
    required this.steps,
    required this.learnedStepTitles,
    required this.onStepLearned,
  });

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -_scrollOffset * 0.25,
            left: 0,
            right: 0,
            child: Container(
              height: 360,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF30241B), Color(0xFF111111)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24 - _scrollOffset * 0.08,
            left: -10,
            child: Opacity(
              opacity: 0.16,
              child: Text(
                'CRAFT',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent.withOpacity(0.5),
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.fromLTRB(20, 0, 20, 18),
                  title: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      '工艺解构',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Text(
                    '把选料、构思、粗雕、精雕与抛光拆成可以被感知的阅读节奏，让工艺不再只是大段说明。',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.92),
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '工艺学习进度',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '已完成 ${widget.learnedStepTitles.length}/${widget.steps.length} 个步骤的阅读',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: widget.steps.isEmpty
                                    ? 0
                                    : widget.learnedStepTitles.length /
                                        widget.steps.length,
                                strokeWidth: 7,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.accent,
                                ),
                              ),
                              Text(
                                '${widget.steps.isEmpty ? 0 : ((widget.learnedStepTitles.length / widget.steps.length) * 100).round()}%',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
              SliverList.builder(
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  final step = widget.steps[index];
                  return _ProcessCard(
                    index: index,
                    step: step,
                    isLearned: widget.learnedStepTitles.contains(step.title),
                    onTap: () => _showStepSheet(context, step, index),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ],
      ),
    );
  }

  void _showStepSheet(BuildContext context, CraftStep step, int index) {
    HapticFeedback.lightImpact();
    widget.onStepLearned(step.title);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                Text(
                  '0${index + 1} ${step.title}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  step.summary,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 16),
                _AnimatedPreview(index: index),
                const SizedBox(height: 18),
                Text(
                  step.detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '阅读焦点：${step.focus}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AssetArtwork extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const AssetArtwork({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A211A), AppColors.surface],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.museum_outlined,
              color: AppColors.accent,
              size: 42,
            ),
          ),
        );
      },
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '本地内容加载失败，请检查 assets/data/content.json 与 pubspec.yaml 的资源配置。',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final IntroPageData page;

  const _IntroCard({
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF221A14), Color(0xFF181818)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _DecorativeGrid()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'LESS IS MORE',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                page.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                page.note,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final int index;
  final CraftStep step;
  final bool isLearned;
  final VoidCallback onTap;

  const _ProcessCard({
    required this.index,
    required this.step,
    required this.isLearned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '0${index + 1}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.summary,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLearned ? Icons.check_circle : Icons.north_east,
                  color: isLearned
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPreview extends StatefulWidget {
  final int index;

  const _AnimatedPreview({
    required this.index,
  });

  @override
  State<_AnimatedPreview> createState() => _AnimatedPreviewState();
}

class _AnimatedPreviewState extends State<_AnimatedPreview>
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
    return SizedBox(
      height: 132,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A2D21), Color(0xFF161616)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 18 + (progress * 180),
                  top: 18,
                  bottom: 18,
                  child: Container(
                    width: 2,
                    color: AppColors.accent.withOpacity(0.45),
                  ),
                ),
                Positioned(
                  left: 24 + (progress * 160),
                  top: 24 + (widget.index * 6),
                  child: Transform.rotate(
                    angle: 0.28,
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    color: AppColors.accent,
                    backgroundColor: Colors.white12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BackdropPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF261D16), AppColors.background],
          ),
        ),
      ),
    );
  }
}

class _DecorativeGrid extends StatelessWidget {
  const _DecorativeGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GridPainter());
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.accent.withOpacity(0.06)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 28) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 34.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
