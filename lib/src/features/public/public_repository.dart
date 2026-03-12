import '../../core/localization/app_strings.dart';
import '../../core/network/api_client.dart';

class PublicRepository {
  Future<ContactInfo?> fetchContactInfo() async {
    final response = await ApiClient.dio.get('/contact-section');
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return ContactInfo.fromJson(data);
  }

  Future<LegalPage?> fetchLegalPage(String path) async {
    final response = await ApiClient.dio.get('/$path');
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return LegalPage.fromJson(data);
  }

  Future<AboutPayload?> fetchAboutPage() async {
    final response = await ApiClient.dio.get(
      '/about-page',
      queryParameters: {'language': AppStrings.code},
    );
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return AboutPayload.fromJson(data);
  }

  Future<HomePayload?> fetchHomePage() async {
    final response = await ApiClient.dio.get(
      '/home-page',
      queryParameters: {'language': AppStrings.code},
    );
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return HomePayload.fromJson(data);
  }

  Future<PublicSettings?> fetchSettings() async {
    final response = await ApiClient.dio.get('/settings');
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return PublicSettings.fromJson(data);
  }

  Future<List<LanguageOption>> fetchLanguages() async {
    final response = await ApiClient.dio.get('/language-list');
    final rawList = _extractList(response.data);
    if (rawList.isEmpty) {
      return const [];
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(LanguageOption.fromJson)
        .toList(growable: false);
  }

  Future<List<CurrencyOption>> fetchCurrencies() async {
    final response = await ApiClient.dio.get('/currency-list');
    final rawList = _extractList(response.data);
    if (rawList.isEmpty) {
      return const [];
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(CurrencyOption.fromJson)
        .toList(growable: false);
  }

  Future<List<PublicBlogPost>> fetchBlogPosts() async {
    final response = await ApiClient.dio.get('/blog/posts');
    final data = response.data;
    final rawList = _extractList(data);
    if (rawList.isEmpty) {
      return [];
    }
    return rawList.map(PublicBlogPost.fromJson).toList();
  }

  Future<List<SocialLinkItem>> fetchSocialLinks() async {
    final response = await ApiClient.dio.get('/social-links');
    final rawList = _extractList(response.data);
    if (rawList.isEmpty) {
      return [];
    }
    return rawList.map(SocialLinkItem.fromJson).toList();
  }

  Future<PublicBlogDetail?> fetchBlogDetail(String slug) async {
    final response = await ApiClient.dio.get(
      '/blog/posts/$slug',
      queryParameters: {'language': AppStrings.code},
    );
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return PublicBlogDetail.fromJson(data);
  }

  Future<PlanPayload?> fetchStudentPlans() async {
    final response = await ApiClient.dio.get('/student-plans');
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return PlanPayload.fromJson(data);
  }

  Future<List<FaqItem>> fetchFaqs() async {
    final response = await ApiClient.dio.get(
      '/faqs',
      queryParameters: {'language': AppStrings.code},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map && inner['items'] is List) {
        return (inner['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(FaqItem.fromJson)
            .toList(growable: false);
      }
      if (inner is List) {
        return inner
            .whereType<Map<String, dynamic>>()
            .map(FaqItem.fromJson)
            .toList(growable: false);
      }
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(FaqItem.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> submitContact({
    required String name,
    required String email,
    required String subject,
    required String message,
    String? phone,
  }) async {
    await ApiClient.dio.post(
      '/contact-us',
      data: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<void> submitCorporate({
    required String company,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? trainees,
  }) async {
    await ApiClient.dio.post(
      '/corporate/lead',
      data: {
        'company_name': company,
        'contact_first_name': firstName,
        'contact_last_name': lastName,
        'email': email,
        'phone': phone,
        if (trainees != null && trainees.isNotEmpty) 'trainees': trainees,
      },
    );
  }

  Future<void> submitNewsletter({required String email}) async {
    await ApiClient.dio.post('/subscribe-us', data: {'email': email});
  }

  Future<List<PlacementQuestion>> fetchPlacementQuestions({
    String? locale,
  }) async {
    final response = await ApiClient.dio.get(
      '/placement-test/questions',
      queryParameters: {'locale': locale ?? AppStrings.code},
    );

    final map = _extractMap(response.data);
    final list = map?['questions'];
    if (list is! List) {
      return const [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(PlacementQuestion.fromJson)
        .toList(growable: false);
  }

  Future<PlacementResult> submitPlacementTest({
    required Map<String, String> answers,
    String? name,
    String? email,
    String? phone,
    String source = 'mobile',
    String? locale,
  }) async {
    final response = await ApiClient.dio.post(
      '/placement-test/submit',
      data: {
        'answers': answers,
        'source': source,
        'locale': locale ?? AppStrings.code,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );

    final map = _extractMap(response.data) ?? const <String, dynamic>{};
    final resultMap = map['result'];
    final ctaMap = map['cta'];

    if (resultMap is! Map<String, dynamic>) {
      throw Exception('Placement result is missing');
    }

    return PlacementResult.fromJson(
      resultMap,
      ctaMap is Map<String, dynamic> ? ctaMap : const <String, dynamic>{},
    );
  }

  Future<TrialLessonRequestResult> requestTrialLesson() async {
    final response = await ApiClient.dio.post('/trial/request');
    final payload = response.data;

    if (payload is Map<String, dynamic>) {
      final message = (payload['message'] ?? '').toString();
      String whatsappUrl = '';

      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        whatsappUrl = (data['whatsapp_url'] ?? '').toString();
      }

      return TrialLessonRequestResult(
        message: message,
        whatsappUrl: whatsappUrl,
      );
    }

    return const TrialLessonRequestResult(message: '', whatsappUrl: '');
  }

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is Map<String, dynamic>) {
      final list =
          data['data'] ?? data['posts'] ?? data['items'] ?? data['results'];
      return list is List ? list : [];
    }
    if (data is List) {
      return data;
    }
    return [];
  }
}

class PublicSettings {
  const PublicSettings({required this.whatsappLeadPhone});

  final String whatsappLeadPhone;

  factory PublicSettings.fromJson(Map<String, dynamic> json) {
    return PublicSettings(
      whatsappLeadPhone: (json['whatsapp_lead_phone'] ?? '').toString(),
    );
  }
}

class PlacementQuestion {
  const PlacementQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<PlacementOption> options;

  factory PlacementQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return PlacementQuestion(
      id: (json['id'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      options: rawOptions is List
          ? rawOptions
                .whereType<Map<String, dynamic>>()
                .map(PlacementOption.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class PlacementOption {
  const PlacementOption({required this.id, required this.label});

  final String id;
  final String label;

  factory PlacementOption.fromJson(Map<String, dynamic> json) {
    return PlacementOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}

class PlacementResult {
  const PlacementResult({
    required this.level,
    required this.score,
    required this.maxScore,
    required this.recommendedTrack,
    required this.summary,
    required this.nextStep,
    required this.scheduleUrl,
    required this.whatsappUrl,
  });

  final String level;
  final int score;
  final int maxScore;
  final String recommendedTrack;
  final String summary;
  final String nextStep;
  final String scheduleUrl;
  final String whatsappUrl;

  factory PlacementResult.fromJson(
    Map<String, dynamic> resultJson,
    Map<String, dynamic> ctaJson,
  ) {
    return PlacementResult(
      level: (resultJson['level'] ?? '').toString(),
      score: resultJson['score'] is num
          ? (resultJson['score'] as num).toInt()
          : 0,
      maxScore: resultJson['max_score'] is num
          ? (resultJson['max_score'] as num).toInt()
          : 0,
      recommendedTrack: (resultJson['recommended_track'] ?? '').toString(),
      summary: (resultJson['summary'] ?? '').toString(),
      nextStep: (resultJson['next_step'] ?? '').toString(),
      scheduleUrl: (ctaJson['schedule_url'] ?? '').toString(),
      whatsappUrl: (ctaJson['whatsapp_url'] ?? '').toString(),
    );
  }
}

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.direction,
    required this.isDefault,
    required this.isActive,
  });

  final String code;
  final String name;
  final String direction;
  final bool isDefault;
  final bool isActive;

  factory LanguageOption.fromJson(Map<String, dynamic> json) {
    return LanguageOption(
      code: (json['code'] ?? '').toString().toLowerCase(),
      name: (json['name'] ?? '').toString(),
      direction: (json['direction'] ?? '').toString(),
      isDefault: json['is_default'] == true,
      isActive: json['status'] == true,
    );
  }
}

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    required this.rate,
    required this.position,
    required this.isDefault,
    required this.status,
  });

  final String code;
  final String name;
  final double rate;
  final String position;
  final String isDefault;
  final String status;

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    final code = (json['currency_code'] ?? '').toString().toUpperCase();
    return CurrencyOption(
      code: code,
      name: (json['currency_name'] ?? code).toString(),
      rate: json['currency_rate'] is num
          ? (json['currency_rate'] as num).toDouble()
          : 1,
      position: (json['currency_position'] ?? '').toString(),
      isDefault: (json['is_default'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class PublicBlogPost {
  const PublicBlogPost({
    required this.title,
    required this.slug,
    required this.dateLabel,
    required this.imageUrl,
    required this.excerpt,
  });

  final String title;
  final String slug;
  final String dateLabel;
  final String imageUrl;
  final String excerpt;

  factory PublicBlogPost.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const PublicBlogPost(
        title: 'Blog',
        slug: '',
        dateLabel: '',
        imageUrl: '',
        excerpt: '',
      );
    }
    return PublicBlogPost(
      title: (json['title'] ?? json['name'] ?? 'Blog').toString(),
      slug: (json['slug'] ?? '').toString(),
      dateLabel: (json['date'] ?? json['created_at'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['thumbnail'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? json['short_description'] ?? '').toString(),
    );
  }
}

class PublicBlogDetail {
  const PublicBlogDetail({
    required this.title,
    required this.slug,
    required this.imageUrl,
    required this.excerpt,
    required this.description,
    required this.createdAt,
    required this.author,
    required this.category,
  });

  final String title;
  final String slug;
  final String imageUrl;
  final String excerpt;
  final String description;
  final String createdAt;
  final String author;
  final String category;

  factory PublicBlogDetail.fromJson(Map<String, dynamic> json) {
    return PublicBlogDetail(
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
    );
  }
}

class PlanPayload {
  const PlanPayload({
    required this.currency,
    required this.listPricePerLesson,
    required this.plans,
  });

  final String currency;
  final double listPricePerLesson;
  final List<StudentPlan> plans;

  factory PlanPayload.fromJson(Map<String, dynamic> json) {
    return PlanPayload(
      currency: (json['currency'] ?? '').toString(),
      listPricePerLesson: (json['list_price_per_lesson'] is num)
          ? (json['list_price_per_lesson'] as num).toDouble()
          : 0,
      plans: _parseList(json['plans'], StudentPlan.fromJson),
    );
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList(growable: false);
  }
}

class StudentPlan {
  const StudentPlan({
    required this.key,
    required this.title,
    required this.displayTitle,
    required this.label,
    required this.subtitle,
    required this.tagline,
    required this.durationMonths,
    required this.lessonDuration,
    required this.lessonsTotal,
    required this.cancelTotal,
    required this.oldPrice,
    required this.price,
    required this.featured,
  });

  final String key;
  final String title;
  final String displayTitle;
  final String label;
  final String subtitle;
  final String tagline;
  final int durationMonths;
  final int lessonDuration;
  final int lessonsTotal;
  final int cancelTotal;
  final double oldPrice;
  final double price;
  final bool featured;

  factory StudentPlan.fromJson(Map<String, dynamic> json) {
    return StudentPlan(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      displayTitle: (json['display_title'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      durationMonths: json['duration_months'] is int
          ? json['duration_months'] as int
          : 0,
      lessonDuration: json['lesson_duration'] is int
          ? json['lesson_duration'] as int
          : 0,
      lessonsTotal: json['lessons_total'] is int
          ? json['lessons_total'] as int
          : 0,
      cancelTotal: json['cancel_total'] is int
          ? json['cancel_total'] as int
          : 0,
      oldPrice: json['old_price'] is num
          ? (json['old_price'] as num).toDouble()
          : 0,
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0,
      featured: json['featured'] == true,
    );
  }
}

class TrialLessonRequestResult {
  const TrialLessonRequestResult({
    required this.message,
    required this.whatsappUrl,
  });

  final String message;
  final String whatsappUrl;
}

class ContactInfo {
  const ContactInfo({
    required this.address,
    required this.phoneOne,
    required this.phoneTwo,
    required this.emailOne,
    required this.emailTwo,
    required this.mapUrl,
  });

  final String address;
  final String phoneOne;
  final String phoneTwo;
  final String emailOne;
  final String emailTwo;
  final String mapUrl;

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      address: (json['address'] ?? '').toString(),
      phoneOne: (json['phone_one'] ?? '').toString(),
      phoneTwo: (json['phone_two'] ?? '').toString(),
      emailOne: (json['email_one'] ?? '').toString(),
      emailTwo: (json['email_two'] ?? '').toString(),
      mapUrl: (json['map'] ?? '').toString(),
    );
  }
}

class SocialLinkItem {
  const SocialLinkItem({required this.icon, required this.url});

  final String icon;
  final String url;

  factory SocialLinkItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return SocialLinkItem(
        icon: (json['icon'] ?? '').toString(),
        url: (json['link'] ?? json['url'] ?? '').toString(),
      );
    }
    return const SocialLinkItem(icon: '', url: '');
  }
}

class LegalPage {
  const LegalPage({required this.title, required this.content});

  final String title;
  final String content;

  factory LegalPage.fromJson(Map<String, dynamic> json) {
    return LegalPage(
      title: (json['name'] ?? json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

class AboutPayload {
  AboutPayload({
    required this.hero,
    required this.about,
    required this.features,
    required this.newsletter,
    required this.faqSection,
    required this.brands,
    required this.testimonials,
    required this.faqs,
  });

  final SectionData? hero;
  final SectionData? about;
  final SectionData? features;
  final SectionData? newsletter;
  final SectionData? faqSection;
  final List<BrandItem> brands;
  final List<TestimonialItem> testimonials;
  final List<FaqItem> faqs;

  factory AboutPayload.fromJson(Map<String, dynamic> json) {
    return AboutPayload(
      hero: SectionData.fromJson(json['hero']),
      about: SectionData.fromJson(json['about']),
      features: SectionData.fromJson(json['our_features']),
      newsletter: SectionData.fromJson(json['newsletter']),
      faqSection: SectionData.fromJson(json['faq_section']),
      brands: _parseList(json['brands'], BrandItem.fromJson),
      testimonials: _parseList(json['testimonials'], TestimonialItem.fromJson),
      faqs: _parseList(json['faqs'], FaqItem.fromJson),
    );
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList(growable: false);
  }
}

class HomePayload {
  HomePayload({
    required this.hero,
    required this.slider,
    required this.about,
    required this.newsletter,
    required this.counter,
    required this.features,
    required this.banner,
    required this.faqSection,
    required this.trendingCategories,
    required this.brands,
    required this.featuredInstructorSection,
    required this.selectedInstructors,
    required this.testimonials,
    required this.featuredBlogs,
  });

  final SectionData? hero;
  final SectionData? slider;
  final SectionData? about;
  final SectionData? newsletter;
  final SectionData? counter;
  final SectionData? features;
  final SectionData? banner;
  final SectionData? faqSection;
  final List<TrendingCategory> trendingCategories;
  final List<BrandItem> brands;
  final FeaturedInstructorSection? featuredInstructorSection;
  final List<FeaturedInstructor> selectedInstructors;
  final List<TestimonialItem> testimonials;
  final List<FeaturedBlog> featuredBlogs;

  factory HomePayload.fromJson(Map<String, dynamic> json) {
    return HomePayload(
      hero: SectionData.fromJson(json['hero']),
      slider: SectionData.fromJson(json['slider']),
      about: SectionData.fromJson(json['about']),
      newsletter: SectionData.fromJson(json['newsletter']),
      counter: SectionData.fromJson(json['counter']),
      features: SectionData.fromJson(json['our_features']),
      banner: SectionData.fromJson(json['banner']),
      faqSection: SectionData.fromJson(json['faq_section']),
      trendingCategories: _parseList(
        json['trending_categories'],
        TrendingCategory.fromJson,
      ),
      brands: _parseList(json['brands'], BrandItem.fromJson),
      featuredInstructorSection: FeaturedInstructorSection.fromJson(
        json['featured_instructor_section'],
      ),
      selectedInstructors: _parseList(
        json['selected_instructors'],
        FeaturedInstructor.fromJson,
      ),
      testimonials: _parseList(json['testimonials'], TestimonialItem.fromJson),
      featuredBlogs: _parseList(json['featured_blogs'], FeaturedBlog.fromJson),
    );
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList(growable: false);
  }
}

class TrendingCategory {
  const TrendingCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.icon,
    required this.subCategories,
  });

  final int id;
  final String slug;
  final String name;
  final String? icon;
  final List<TrendingSubCategory> subCategories;

  factory TrendingCategory.fromJson(Map<String, dynamic> json) {
    return TrendingCategory(
      id: json['id'] is int ? json['id'] as int : 0,
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: json['icon']?.toString(),
      subCategories: (json['sub_categories'] is List)
          ? (json['sub_categories'] as List)
                .whereType<Map<String, dynamic>>()
                .map(TrendingSubCategory.fromJson)
                .toList()
          : const [],
    );
  }
}

class TrendingSubCategory {
  const TrendingSubCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.courseCount,
  });

  final int id;
  final String slug;
  final String name;
  final int courseCount;

  factory TrendingSubCategory.fromJson(Map<String, dynamic> json) {
    return TrendingSubCategory(
      id: json['id'] is int ? json['id'] as int : 0,
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      courseCount: json['course_count'] is int
          ? json['course_count'] as int
          : 0,
    );
  }
}

class FeaturedInstructorSection {
  const FeaturedInstructorSection({
    required this.title,
    required this.subtitle,
    required this.buttonUrl,
  });

  final String title;
  final String subtitle;
  final String buttonUrl;

  static FeaturedInstructorSection? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return FeaturedInstructorSection(
      title: (raw['title'] ?? raw['name'] ?? '').toString(),
      subtitle: (raw['subtitle'] ?? '').toString(),
      buttonUrl: (raw['button_url'] ?? '').toString(),
    );
  }
}

class FeaturedInstructor {
  const FeaturedInstructor({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.jobTitle,
    required this.shortBio,
    required this.avgRating,
    required this.courseCount,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String jobTitle;
  final String shortBio;
  final double avgRating;
  final int courseCount;

  double get rating => avgRating;

  factory FeaturedInstructor.fromJson(Map<String, dynamic> json) {
    final rating = json['avg_rating'];
    return FeaturedInstructor(
      id: json['id'] is int ? json['id'] as int : 0,
      name: (json['name'] ?? '').toString(),
      imageUrl: json['image']?.toString(),
      jobTitle: (json['job_title'] ?? '').toString(),
      shortBio: (json['short_bio'] ?? '').toString(),
      avgRating: rating is num ? rating.toDouble() : 0,
      courseCount: json['course_count'] is int
          ? json['course_count'] as int
          : 0,
    );
  }
}

class FeaturedBlog {
  const FeaturedBlog({
    required this.id,
    required this.title,
    required this.slug,
    required this.imageUrl,
    required this.excerpt,
    required this.createdAt,
    required this.author,
  });

  final int id;
  final String title;
  final String slug;
  final String? imageUrl;
  final String excerpt;
  final String createdAt;
  final String author;

  factory FeaturedBlog.fromJson(Map<String, dynamic> json) {
    return FeaturedBlog(
      id: json['id'] is int ? json['id'] as int : 0,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: json['image']?.toString(),
      excerpt: (json['excerpt'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
    );
  }
}

class SectionData {
  const SectionData({required this.content, required this.global});

  final Map<String, dynamic> content;
  final Map<String, dynamic> global;

  static SectionData? fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return SectionData(
      content: _toMap(raw['content']),
      global: _toMap(raw['global']),
    );
  }

  static Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }
}

class BrandItem {
  const BrandItem({
    required this.name,
    required this.imageUrl,
    required this.url,
  });

  final String name;
  final String imageUrl;
  final String url;

  factory BrandItem.fromJson(Map<String, dynamic> json) {
    return BrandItem(
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
    );
  }
}

class TestimonialItem {
  const TestimonialItem({
    required this.name,
    required this.designation,
    required this.comment,
    required this.rating,
    required this.imageUrl,
  });

  final String name;
  final String designation;
  final String comment;
  final double rating;
  final String imageUrl;

  factory TestimonialItem.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    return TestimonialItem(
      name: (json['name'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      rating: rating is num ? rating.toDouble() : 0,
      imageUrl: (json['image'] ?? '').toString(),
    );
  }
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
    );
  }
}
