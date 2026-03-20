import 'app_models.dart';

enum UserRole {
  visitor('访客'),
  admin('管理员');

  final String label;

  const UserRole(this.label);
}

class AppSession {
  final String userId;
  final String displayName;
  final String email;
  final UserRole role;

  const AppSession({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
  });

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (item) => item.name == json['role'],
        orElse: () => UserRole.visitor,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'role': role.name,
  };
}

class ManagedExhibitState {
  final String exhibitId;
  final bool featured;
  final bool published;
  final String adminTag;

  const ManagedExhibitState({
    required this.exhibitId,
    required this.featured,
    required this.published,
    required this.adminTag,
  });

  factory ManagedExhibitState.seeded(Exhibit exhibit, int index) {
    return ManagedExhibitState(
      exhibitId: exhibit.id,
      featured: index < 3,
      published: true,
      adminTag: index < 3 ? '首页精选' : '展馆常规',
    );
  }

  factory ManagedExhibitState.fromJson(Map<String, dynamic> json) {
    return ManagedExhibitState(
      exhibitId: (json['exhibit_id'] ?? json['exhibitId']) as String,
      featured: json['featured'] as bool? ?? false,
      published: json['published'] as bool? ?? true,
      adminTag: (json['admin_tag'] ?? json['adminTag']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'exhibit_id': exhibitId,
    'featured': featured,
    'published': published,
    'admin_tag': adminTag,
  };

  ManagedExhibitState copyWith({
    bool? featured,
    bool? published,
    String? adminTag,
  }) {
    return ManagedExhibitState(
      exhibitId: exhibitId,
      featured: featured ?? this.featured,
      published: published ?? this.published,
      adminTag: adminTag ?? this.adminTag,
    );
  }
}

class AdminWorkspace {
  final Map<String, ManagedExhibitState> exhibitStates;

  const AdminWorkspace({required this.exhibitStates});

  factory AdminWorkspace.seeded(List<Exhibit> exhibits) {
    return AdminWorkspace(
      exhibitStates: {
        for (int i = 0; i < exhibits.length; i++)
          exhibits[i].id: ManagedExhibitState.seeded(exhibits[i], i),
      },
    );
  }

  factory AdminWorkspace.fromJson(Map<String, dynamic> json) {
    final rawStates = (json['exhibitStates'] as List<dynamic>? ?? [])
        .map(
          (item) => ManagedExhibitState.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    return AdminWorkspace(
      exhibitStates: {for (final item in rawStates) item.exhibitId: item},
    );
  }

  Map<String, dynamic> toJson() => {
    'exhibitStates': exhibitStates.values.map((item) => item.toJson()).toList(),
  };

  ManagedExhibitState stateFor(String exhibitId) {
    return exhibitStates[exhibitId] ??
        ManagedExhibitState(
          exhibitId: exhibitId,
          featured: false,
          published: true,
          adminTag: '未标记',
        );
  }

  AdminWorkspace update(ManagedExhibitState nextState) {
    return AdminWorkspace(
      exhibitStates: {...exhibitStates, nextState.exhibitId: nextState},
    );
  }
}
