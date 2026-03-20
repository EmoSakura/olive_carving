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

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'note': note,
  };
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

class FeaturedCollection {
  final String id;
  final String title;
  final String subtitle;
  final String highlight;
  final String estimatedTime;
  final List<String> exhibitIds;

  const FeaturedCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.estimatedTime,
    required this.exhibitIds,
  });

  factory FeaturedCollection.fromJson(Map<String, dynamic> json) {
    return FeaturedCollection(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      highlight: json['highlight'] as String,
      estimatedTime: json['estimatedTime'] as String,
      exhibitIds: (json['exhibitIds'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }
}

class TimelineMilestone {
  final String year;
  final String title;
  final String summary;

  const TimelineMilestone({
    required this.year,
    required this.title,
    required this.summary,
  });

  factory TimelineMilestone.fromJson(Map<String, dynamic> json) {
    return TimelineMilestone(
      year: json['year'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
    );
  }
}

class MasterProfile {
  final String name;
  final String title;
  final String specialty;
  final String quote;

  const MasterProfile({
    required this.name,
    required this.title,
    required this.specialty,
    required this.quote,
  });

  factory MasterProfile.fromJson(Map<String, dynamic> json) {
    return MasterProfile(
      name: json['name'] as String,
      title: json['title'] as String,
      specialty: json['specialty'] as String,
      quote: json['quote'] as String,
    );
  }
}

class ServicePackage {
  final String id;
  final String title;
  final String audience;
  final String summary;
  final String priceBand;
  final String turnaround;
  final List<String> deliverables;

  const ServicePackage({
    required this.id,
    required this.title,
    required this.audience,
    required this.summary,
    required this.priceBand,
    required this.turnaround,
    required this.deliverables,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'] as String,
      title: json['title'] as String,
      audience: json['audience'] as String,
      summary: json['summary'] as String,
      priceBand: json['priceBand'] as String,
      turnaround: json['turnaround'] as String,
      deliverables: (json['deliverables'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}

class AppContent {
  final List<IntroPageData> introPages;
  final List<Exhibit> exhibits;
  final List<CraftStep> craftSteps;
  final List<FeaturedCollection> featuredCollections;
  final List<TimelineMilestone> timeline;
  final List<MasterProfile> masters;
  final List<ServicePackage> servicePackages;
  final List<FaqItem> faqs;
  final String featuredQuote;

  const AppContent({
    required this.introPages,
    required this.exhibits,
    required this.craftSteps,
    required this.featuredCollections,
    required this.timeline,
    required this.masters,
    required this.servicePackages,
    required this.faqs,
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
      featuredCollections: (json['featuredCollections'] as List<dynamic>)
          .map(
            (item) => FeaturedCollection.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      timeline: (json['timeline'] as List<dynamic>)
          .map(
            (item) => TimelineMilestone.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      masters: (json['masters'] as List<dynamic>)
          .map((item) => MasterProfile.fromJson(item as Map<String, dynamic>))
          .toList(),
      servicePackages: (json['servicePackages'] as List<dynamic>)
          .map((item) => ServicePackage.fromJson(item as Map<String, dynamic>))
          .toList(),
      faqs: (json['faqs'] as List<dynamic>)
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      featuredQuote: json['featuredQuote'] as String,
    );
  }
}

class CarvingRecord {
  final String title;
  final String note;
  final String modeId;
  final String modeLabel;
  final String difficultyId;
  final String difficultyLabel;
  final DateTime timestamp;
  final int strokeCount;

  const CarvingRecord({
    required this.title,
    required this.note,
    required this.modeId,
    required this.modeLabel,
    required this.difficultyId,
    required this.difficultyLabel,
    required this.timestamp,
    required this.strokeCount,
  });

  factory CarvingRecord.fromJson(Map<String, dynamic> json) {
    return CarvingRecord(
      title: json['title'] as String? ?? '未命名作品',
      note: json['note'] as String? ?? '',
      modeId: json['modeId'] as String,
      modeLabel: json['modeLabel'] as String,
      difficultyId: json['difficultyId'] as String,
      difficultyLabel: json['difficultyLabel'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      strokeCount: json['strokeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'note': note,
    'modeId': modeId,
    'modeLabel': modeLabel,
    'difficultyId': difficultyId,
    'difficultyLabel': difficultyLabel,
    'timestamp': timestamp.toIso8601String(),
    'strokeCount': strokeCount,
  };
}

class ServiceInquiry {
  final String packageId;
  final String packageTitle;
  final String contactName;
  final String organization;
  final String budget;
  final String message;
  final DateTime timestamp;

  const ServiceInquiry({
    required this.packageId,
    required this.packageTitle,
    required this.contactName,
    required this.organization,
    required this.budget,
    required this.message,
    required this.timestamp,
  });

  factory ServiceInquiry.fromJson(Map<String, dynamic> json) {
    return ServiceInquiry(
      packageId: json['packageId'] as String,
      packageTitle: json['packageTitle'] as String,
      contactName: json['contactName'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      budget: json['budget'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'packageTitle': packageTitle,
    'contactName': contactName,
    'organization': organization,
    'budget': budget,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AppUserState {
  final Set<String> favoriteExhibitIds;
  final List<String> recentExhibitIds;
  final Set<String> learnedStepTitles;
  final List<CarvingRecord> carvingHistory;
  final List<ServiceInquiry> serviceInquiries;

  const AppUserState({
    required this.favoriteExhibitIds,
    required this.recentExhibitIds,
    required this.learnedStepTitles,
    required this.carvingHistory,
    required this.serviceInquiries,
  });

  factory AppUserState.empty() {
    return const AppUserState(
      favoriteExhibitIds: <String>{},
      recentExhibitIds: <String>[],
      learnedStepTitles: <String>{},
      carvingHistory: <CarvingRecord>[],
      serviceInquiries: <ServiceInquiry>[],
    );
  }

  factory AppUserState.fromJson(Map<String, dynamic> json) {
    return AppUserState(
      favoriteExhibitIds: ((json['favoriteExhibitIds'] as List<dynamic>?) ?? [])
          .map((item) => item as String)
          .toSet(),
      recentExhibitIds: ((json['recentExhibitIds'] as List<dynamic>?) ?? [])
          .map((item) => item as String)
          .toList(),
      learnedStepTitles: ((json['learnedStepTitles'] as List<dynamic>?) ?? [])
          .map((item) => item as String)
          .toSet(),
      carvingHistory: ((json['carvingHistory'] as List<dynamic>?) ?? [])
          .map((item) => CarvingRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      serviceInquiries: ((json['serviceInquiries'] as List<dynamic>?) ?? [])
          .map((item) => ServiceInquiry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'favoriteExhibitIds': favoriteExhibitIds.toList(),
    'recentExhibitIds': recentExhibitIds,
    'learnedStepTitles': learnedStepTitles.toList(),
    'carvingHistory': carvingHistory.map((item) => item.toJson()).toList(),
    'serviceInquiries': serviceInquiries.map((item) => item.toJson()).toList(),
  };

  AppUserState copyWith({
    Set<String>? favoriteExhibitIds,
    List<String>? recentExhibitIds,
    Set<String>? learnedStepTitles,
    List<CarvingRecord>? carvingHistory,
    List<ServiceInquiry>? serviceInquiries,
  }) {
    return AppUserState(
      favoriteExhibitIds: favoriteExhibitIds ?? this.favoriteExhibitIds,
      recentExhibitIds: recentExhibitIds ?? this.recentExhibitIds,
      learnedStepTitles: learnedStepTitles ?? this.learnedStepTitles,
      carvingHistory: carvingHistory ?? this.carvingHistory,
      serviceInquiries: serviceInquiries ?? this.serviceInquiries,
    );
  }
}
