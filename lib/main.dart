import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_models.dart';
import 'app_theme.dart';
import 'auth_screen.dart';
import 'backend_gateway.dart';
import 'content_repository.dart';
import 'admin_screen.dart';
import 'home_screen.dart';
import 'interaction_screen.dart';
import 'product_models.dart';
import 'user_state_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  final backendConfig = await BackendConfigLoader.load();
  if (backendConfig.isConfigured) {
    await Supabase.initialize(
      url: backendConfig.supabaseUrl,
      anonKey: backendConfig.supabaseAnonKey,
    );
  }
  runApp(OliveApp(backendConfig: backendConfig));
}

class OliveApp extends StatelessWidget {
  final BackendConfig backendConfig;

  const OliveApp({super.key, required this.backendConfig});

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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceSoft,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withAlphaValue(0.74),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white10),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withAlphaValue(0.18),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: AppBootstrap(backendConfig: backendConfig),
    );
  }
}

class _BootstrapPayload {
  final AppContent content;
  final AppUserState userState;
  final AppSession? session;
  final AdminWorkspace adminWorkspace;

  const _BootstrapPayload({
    required this.content,
    required this.userState,
    required this.session,
    required this.adminWorkspace,
  });
}

class AppBootstrap extends StatefulWidget {
  final BackendConfig backendConfig;

  const AppBootstrap({super.key, required this.backendConfig});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with SingleTickerProviderStateMixin {
  late final BackendGateway _backendGateway;
  late final Future<_BootstrapPayload> _bootstrapFuture;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _backendGateway = createBackendGateway(widget.backendConfig);
    _bootstrapFuture = _loadBootstrap();
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

  Future<_BootstrapPayload> _loadBootstrap() async {
    final content = await const LocalContentRepository().load();
    final userState = await const UserStateRepository().load();
    final session = await _backendGateway.restoreSession();
    final adminWorkspace = await _backendGateway.loadAdminWorkspace(
      content.exhibits,
    );
    return _BootstrapPayload(
      content: content,
      userState: userState,
      session: session,
      adminWorkspace: adminWorkspace,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapPayload>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _BootstrapErrorView();
        }

        if (!snapshot.hasData || !_showIntro) {
          return SplashScreen(fadeAnimation: _fadeAnimation);
        }

        final payload = snapshot.data!;
        if (payload.session != null) {
          return MainNavigationScreen(
            content: payload.content,
            initialUserState: payload.userState,
            session: payload.session!,
            initialAdminWorkspace: payload.adminWorkspace,
            backendGateway: _backendGateway,
          );
        }

        return IntroScreen(
          content: payload.content,
          initialUserState: payload.userState,
          initialAdminWorkspace: payload.adminWorkspace,
          backendGateway: _backendGateway,
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const SplashScreen({super.key, required this.fadeAnimation});

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
                      border: Border.all(
                        color: AppColors.accent.withAlphaValue(0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withAlphaValue(0.16),
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
                      color: AppColors.textSecondary.withAlphaValue(0.9),
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
  final AppUserState initialUserState;
  final AdminWorkspace initialAdminWorkspace;
  final BackendGateway backendGateway;

  const IntroScreen({
    super.key,
    required this.content,
    required this.initialUserState,
    required this.initialAdminWorkspace,
    required this.backendGateway,
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
                  color: AppColors.accent.withAlphaValue(0.9),
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
                          : AppColors.textSecondary.withAlphaValue(0.35),
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
                        builder: (authContext) => AuthScreen(
                          content: widget.content,
                          initialUserState: widget.initialUserState,
                          backendGateway: widget.backendGateway,
                          onSignedIn: (session) async {
                            Navigator.of(authContext).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => MainNavigationScreen(
                                  content: widget.content,
                                  initialUserState: widget.initialUserState,
                                  session: session,
                                  initialAdminWorkspace:
                                      widget.initialAdminWorkspace,
                                  backendGateway: widget.backendGateway,
                                ),
                              ),
                            );
                          },
                        ),
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
                    '登录并进入产品',
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
  final AppUserState initialUserState;
  final AppSession session;
  final AdminWorkspace initialAdminWorkspace;
  final BackendGateway backendGateway;

  const MainNavigationScreen({
    super.key,
    required this.content,
    required this.initialUserState,
    required this.session,
    required this.initialAdminWorkspace,
    required this.backendGateway,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late AppUserState _userState;
  late AdminWorkspace _adminWorkspace;

  @override
  void initState() {
    super.initState();
    _userState = widget.initialUserState;
    _adminWorkspace = widget.initialAdminWorkspace;
  }

  void _persistUserState() {
    unawaited(const UserStateRepository().save(_userState));
  }

  void _persistAdminWorkspace() {
    unawaited(widget.backendGateway.saveAdminWorkspace(_adminWorkspace));
  }

  void _toggleFavoriteExhibit(String exhibitId) {
    final favorites = Set<String>.from(_userState.favoriteExhibitIds);
    if (!favorites.add(exhibitId)) {
      favorites.remove(exhibitId);
    }
    setState(() {
      _userState = _userState.copyWith(favoriteExhibitIds: favorites);
    });
    _persistUserState();
  }

  void _registerExhibitViewed(String exhibitId) {
    final recent = List<String>.from(_userState.recentExhibitIds);
    recent.remove(exhibitId);
    recent.insert(0, exhibitId);
    if (recent.length > 5) {
      recent.removeRange(5, recent.length);
    }
    setState(() {
      _userState = _userState.copyWith(recentExhibitIds: recent);
    });
    _persistUserState();
  }

  void _markStepLearned(String stepTitle) {
    final learned = Set<String>.from(_userState.learnedStepTitles)
      ..add(stepTitle);
    setState(() {
      _userState = _userState.copyWith(learnedStepTitles: learned);
    });
    _persistUserState();
  }

  void _updateCarvingHistory(List<CarvingRecord> history) {
    setState(() {
      _userState = _userState.copyWith(carvingHistory: history);
    });
    _persistUserState();
  }

  void _updateManagedExhibit(ManagedExhibitState nextState) {
    setState(() {
      _adminWorkspace = _adminWorkspace.update(nextState);
    });
    _persistAdminWorkspace();
  }

  Future<void> _handleLogout() async {
    await widget.backendGateway.signOut();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (authContext) => AuthScreen(
          content: widget.content,
          initialUserState: _userState,
          backendGateway: widget.backendGateway,
          onSignedIn: (session) async {
            Navigator.of(authContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  content: widget.content,
                  initialUserState: _userState,
                  session: session,
                  initialAdminWorkspace: _adminWorkspace,
                  backendGateway: widget.backendGateway,
                ),
              ),
            );
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleExhibits = widget.content.exhibits
        .where((item) => _adminWorkspace.stateFor(item.id).published)
        .toList();
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: '首页',
      ),
      const NavigationDestination(
        icon: Icon(Icons.photo_library_outlined),
        selectedIcon: Icon(Icons.photo_library),
        label: '数字展馆',
      ),
      const NavigationDestination(
        icon: Icon(Icons.layers_outlined),
        selectedIcon: Icon(Icons.layers),
        label: '工艺解构',
      ),
      const NavigationDestination(
        icon: Icon(Icons.gesture_outlined),
        selectedIcon: Icon(Icons.gesture),
        label: '指尖互动',
      ),
    ];
    if (widget.session.role == UserRole.admin) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: '后台',
        ),
      );
    }
    final pages = [
      HomeScreen(
        session: widget.session,
        content: widget.content,
        userState: _userState,
        adminWorkspace: _adminWorkspace,
        onOpenGallery: () => setState(() => _currentIndex = 1),
        onOpenProcess: () => setState(() => _currentIndex = 2),
        onOpenInteraction: () => setState(() => _currentIndex = 3),
        onOpenAdmin: () {
          if (widget.session.role == UserRole.admin) {
            setState(() => _currentIndex = 4);
          }
        },
        onLogout: _handleLogout,
      ),
      GalleryScreen(
        featuredCollections: const <FeaturedCollection>[],
        exhibits: visibleExhibits,
        favoriteExhibitIds: _userState.favoriteExhibitIds,
        recentExhibitIds: _userState.recentExhibitIds,
        adminWorkspace: _adminWorkspace,
        onToggleFavorite: _toggleFavoriteExhibit,
        onExhibitViewed: _registerExhibitViewed,
      ),
      ProcessScreen(
        steps: widget.content.craftSteps,
        learnedStepTitles: _userState.learnedStepTitles,
        onStepLearned: _markStepLearned,
      ),
      InteractionScreen(
        initialHistory: _userState.carvingHistory,
        onHistoryChanged: _updateCarvingHistory,
      ),
      if (widget.session.role == UserRole.admin)
        AdminScreen(
          workspace: _adminWorkspace,
          exhibits: widget.content.exhibits,
          onUpdateExhibitState: _updateManagedExhibit,
        ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.accent.withAlphaValue(0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  final List<FeaturedCollection> featuredCollections;
  final List<Exhibit> exhibits;
  final Set<String> favoriteExhibitIds;
  final List<String> recentExhibitIds;
  final AdminWorkspace adminWorkspace;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onExhibitViewed;

  const GalleryScreen({
    super.key,
    required this.featuredCollections,
    required this.exhibits,
    required this.favoriteExhibitIds,
    required this.recentExhibitIds,
    required this.adminWorkspace,
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
  String? _selectedCollectionId;

  List<String> get _categories => [
    '全部',
    ...widget.exhibits.map((e) => e.category).toSet(),
  ];

  List<Exhibit> get _filteredExhibits {
    final activeCollection = _activeCollection;
    return widget.exhibits.where((item) {
      final matchesCategory =
          _selectedCategory == '全部' || item.category == _selectedCategory;
      final matchesFavorite =
          !_favoritesOnly || widget.favoriteExhibitIds.contains(item.id);
      final matchesCollection =
          activeCollection == null ||
          activeCollection.exhibitIds.contains(item.id);
      final query = _searchQuery.trim().toLowerCase();
      final searchableText =
          '${item.title} ${item.author} ${item.category} ${item.technique} ${item.era}'
              .toLowerCase();
      final matchesSearch = query.isEmpty || searchableText.contains(query);
      return matchesCategory &&
          matchesFavorite &&
          matchesCollection &&
          matchesSearch;
    }).toList();
  }

  FeaturedCollection? get _activeCollection {
    for (final collection in widget.featuredCollections) {
      if (collection.id == _selectedCollectionId) {
        return collection;
      }
    }
    return null;
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
                if (widget.featuredCollections.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '精选策展路线',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_activeCollection != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCollectionId = null;
                            });
                          },
                          child: const Text('清除路线'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 156,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.featuredCollections.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final collection = widget.featuredCollections[index];
                        final isSelected =
                            collection.id == _selectedCollectionId;
                        return _FeaturedCollectionCard(
                          collection: collection,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCollectionId = isSelected
                                  ? null
                                  : collection.id;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (_activeCollection != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlphaValue(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.accent.withAlphaValue(0.26),
                      ),
                    ),
                    child: Text(
                      '当前路线：${_activeCollection!.title}，共锁定 ${_activeCollection!.exhibitIds.length} 件重点展品。',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
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
                      color: AppColors.textSecondary.withAlphaValue(0.85),
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
                          color: isSelected
                              ? Colors.black
                              : AppColors.textSecondary,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
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
                          ? AppColors.accent.withAlphaValue(0.16)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _favoritesOnly
                            ? AppColors.accent
                            : Colors.white10,
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
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
                                  isFavorite: widget.favoriteExhibitIds
                                      .contains(exhibit.id),
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exhibit = _filteredExhibits[index];
                    final aspectRatio = index.isEven ? 0.72 : 0.84;
                    return _GalleryCard(
                      exhibit: exhibit,
                      aspectRatio: aspectRatio,
                      isFeatured: widget.adminWorkspace
                          .stateFor(exhibit.id)
                          .featured,
                      isFavorite: widget.favoriteExhibitIds.contains(
                        exhibit.id,
                      ),
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
                  }, childCount: _filteredExhibits.length),
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

class _FeaturedCollectionCard extends StatelessWidget {
  final FeaturedCollection collection;
  final bool selected;
  final VoidCallback onTap;

  const _FeaturedCollectionCard({
    required this.collection,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [const Color(0xFF4B381F), const Color(0xFF1A1611)]
                    : [const Color(0xFF2A211B), AppColors.surface],
              ),
              border: Border.all(
                color: selected ? AppColors.accent : Colors.white10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        collection.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle : Icons.north_east,
                      color: selected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  collection.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                const Spacer(),
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
                    collection.estimatedTime,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  collection.highlight,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.6,
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
  final bool isFeatured;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _GalleryCard({
    required this.exhibit,
    required this.aspectRatio,
    required this.isFeatured,
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
                        left: 10,
                        child: Visibility(
                          visible: isFeatured,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '首页精选',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
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
                          color: AppColors.accent.withAlphaValue(0.12),
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
                child: AssetArtwork(path: exhibit.image, fit: BoxFit.contain),
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
                  color: Colors.black.withAlphaValue(0.82),
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
                              color: AppColors.accent.withAlphaValue(0.14),
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
                          color: AppColors.surface.withAlphaValue(0.72),
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
                  color: AppColors.accent.withAlphaValue(0.5),
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
                      color: AppColors.textSecondary.withAlphaValue(0.92),
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

class ServiceHubScreen extends StatefulWidget {
  final AppContent content;
  final List<ServiceInquiry> inquiries;
  final int favoriteCount;
  final int archivedWorkCount;
  final int learnedStepCount;
  final ValueChanged<ServiceInquiry> onSubmitInquiry;

  const ServiceHubScreen({
    super.key,
    required this.content,
    required this.inquiries,
    required this.favoriteCount,
    required this.archivedWorkCount,
    required this.learnedStepCount,
    required this.onSubmitInquiry,
  });

  @override
  State<ServiceHubScreen> createState() => _ServiceHubScreenState();
}

class _ServiceHubScreenState extends State<ServiceHubScreen> {
  static const List<String> _budgetOptions = [
    '5,000 元以内',
    '5,000 - 20,000 元',
    '20,000 - 50,000 元',
    '50,000 元以上',
  ];

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedPackageId;
  String _selectedBudget = _budgetOptions.first;

  @override
  void initState() {
    super.initState();
    if (widget.content.servicePackages.isNotEmpty) {
      _selectedPackageId = widget.content.servicePackages.first.id;
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _organizationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPackage = widget.content.servicePackages.where(
      (item) => item.id == _selectedPackageId,
    );
    final activePackage = selectedPackage.isEmpty
        ? null
        : selectedPackage.first;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            title: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '服务中心',
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
                  colors: [Color(0xFF34281E), Color(0xFF111111)],
                ),
              ),
              child: const _DecorativeGrid(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D2218), Color(0xFF181818)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '把非遗内容做成可展示、可教学、可转化的数字方案',
                        style: TextStyle(
                          color: AppColors.accent.withAlphaValue(0.96),
                          fontSize: 12,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '这里不只展示作品，也提供校馆合作、品牌活动与课程研学的落地服务框架。',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ServiceMetricPill(
                            label: '收藏展品',
                            value: '${widget.favoriteCount}',
                          ),
                          _ServiceMetricPill(
                            label: '学习步骤',
                            value: '${widget.learnedStepCount}',
                          ),
                          _ServiceMetricPill(
                            label: '归档作品',
                            value: '${widget.archivedWorkCount}',
                          ),
                          _ServiceMetricPill(
                            label: '服务包',
                            value: '${widget.content.servicePackages.length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '商业化服务包',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.content.servicePackages.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ServicePackageCard(
                      item: item,
                      selected: item.id == _selectedPackageId,
                      onTap: () {
                        setState(() {
                          _selectedPackageId = item.id;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '传承人与团队气质',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 182,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.content.masters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _MasterProfileCard(
                        profile: widget.content.masters[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '品牌叙事时间线',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 172,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.content.timeline.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _TimelineCard(
                        item: widget.content.timeline[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
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
                        '合作需求登记',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activePackage == null
                            ? '选择一个服务包后，可以先把需求记录在本地档案中。'
                            : '当前选择：${activePackage.title}，适合 ${activePackage.audience}。',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPackageId,
                        decoration: const InputDecoration(labelText: '服务类型'),
                        items: widget.content.servicePackages
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.title),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPackageId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBudget,
                        decoration: const InputDecoration(labelText: '预算范围'),
                        items: _budgetOptions
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedBudget = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: '联系人',
                          hintText: '可留姓名或岗位',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _organizationController,
                        decoration: const InputDecoration(
                          labelText: '机构 / 品牌',
                          hintText: '例如：博物馆、学校、文旅项目方',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '需求说明',
                          hintText: '填写目标场景、时间节点、交付预期等',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _saveInquiry(activePackage),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '保存到本地需求档案',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.inquiries.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '已登记需求',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.inquiries.reversed
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.packageTitle,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${item.organization.isEmpty ? '未填写机构' : item.organization} · ${item.budget}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 20),
                const Text(
                  '常见问题',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.content.faqs.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ExpansionTile(
                      collapsedIconColor: AppColors.textSecondary,
                      iconColor: AppColors.accent,
                      title: Text(
                        item.question,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            item.answer,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.7,
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
      ],
    );
  }

  void _saveInquiry(ServicePackage? activePackage) {
    if (activePackage == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择服务包并填写需求说明')));
      return;
    }

    widget.onSubmitInquiry(
      ServiceInquiry(
        packageId: activePackage.id,
        packageTitle: activePackage.title,
        contactName: _contactController.text.trim(),
        organization: _organizationController.text.trim(),
        budget: _selectedBudget,
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
      ),
    );

    _contactController.clear();
    _organizationController.clear();
    _messageController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('需求已保存到本地档案，可继续补充和演示')));
  }
}

class _ServiceMetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _ServiceMetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value  ',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePackageCard extends StatelessWidget {
  final ServicePackage item;
  final bool selected;
  final VoidCallback onTap;

  const _ServicePackageCard({
    required this.item,
    required this.selected,
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.white10,
            ),
          ),
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
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '适合对象：${item.audience}',
                style: const TextStyle(color: AppColors.accent, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                item.summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.deliverables
                    .map(
                      (deliverable) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlphaValue(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          deliverable,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '预算参考：${item.priceBand}  ·  交付周期：${item.turnaround}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterProfileCard extends StatelessWidget {
  final MasterProfile profile;

  const _MasterProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
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
            child: const Icon(Icons.person_outline, color: AppColors.accent),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.title,
            style: const TextStyle(color: AppColors.accent, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            profile.specialty,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            '“${profile.quote}”',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
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
      width: 220,
      padding: const EdgeInsets.all(18),
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

class AssetArtwork extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const AssetArtwork({super.key, required this.path, this.fit = BoxFit.cover});

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

  const _IntroCard({required this.page});

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlphaValue(0.12),
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

  const _DetailMetaRow({required this.label, required this.value});

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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

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
              color: AppColors.surface.withAlphaValue(0.92),
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
                    color: AppColors.accent.withAlphaValue(0.15),
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
                  color: isLearned ? AppColors.accent : AppColors.textSecondary,
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

  const _AnimatedPreview({required this.index});

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
                    color: AppColors.accent.withAlphaValue(0.45),
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
      ..color = AppColors.accent.withAlphaValue(0.06)
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
      ..color = AppColors.accent.withAlphaValue(0.05)
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
