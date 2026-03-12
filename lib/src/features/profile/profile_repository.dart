import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';

class ProfileRepository {
  Future<UserProfile?> fetchProfile() async {
    try {
      final response = await ApiClient.dio.get('/profile');
      final data = _extractMap(response.data);
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? gender,
    int? age,
    String? jobTitle,
    String? shortBio,
    String? bio,
    List<String>? certificates,
    XFile? introVideo,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'gender': gender ?? '',
      'age': age,
    };
    if (jobTitle != null) {
      payload['job_title'] = jobTitle;
    }
    if (shortBio != null) {
      payload['short_bio'] = shortBio;
    }
    if (bio != null) {
      payload['bio'] = bio;
    }
    if (certificates != null) {
      payload['certificates'] = certificates;
    }

    if (introVideo != null) {
      final bytes = await introVideo.readAsBytes();
      final certificatesForMultipart = payload['certificates'];
      if (certificatesForMultipart != null) {
        payload.remove('certificates');
        payload['certificates[]'] = certificatesForMultipart;
      }
      payload['intro_video'] = MultipartFile.fromBytes(
        bytes,
        filename: introVideo.name,
      );
      final formData = FormData.fromMap(payload);
      await ApiClient.dio.put('/update-profile', data: formData);
      return;
    }

    await ApiClient.dio.put('/update-profile', data: payload);
  }

  Future<void> updateBio({
    required String jobTitle,
    required String shortBio,
    required String bio,
  }) async {
    await ApiClient.dio.put('/update-bio', data: {
      'job_title': jobTitle,
      'short_bio': shortBio,
      'bio': bio,
    });
  }

  Future<void> updateAddress({
    required int countryId,
    String? state,
    String? city,
    String? address,
  }) async {
    await ApiClient.dio.put('/update-address', data: {
      'country_id': countryId,
      'state': state ?? '',
      'city': city ?? '',
      'address': address ?? '',
    });
  }

  Future<void> updateSocials({
    String? facebook,
    String? twitter,
    String? linkedin,
    String? website,
    String? github,
  }) async {
    await ApiClient.dio.put('/update-social-links', data: {
      'facebook': facebook ?? '',
      'twitter': twitter ?? '',
      'linkedin': linkedin ?? '',
      'website': website ?? '',
      'github': github ?? '',
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await ApiClient.dio.put('/update-password', data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> deleteAccount({
    required String currentPassword,
  }) async {
    await ApiClient.dio.delete('/delete-account', data: {
      'current_password': currentPassword,
      'confirm': 'DELETE',
    });
  }

  Future<void> updateProfileImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    await ApiClient.dio.post('/update-profile-picture', data: formData);
  }

  Future<List<UserEducation>> fetchEducations() async {
    final response = await ApiClient.dio.get('/educations');
    return _extractList(response.data, UserEducation.fromJson);
  }

  Future<List<UserExperience>> fetchExperiences() async {
    final response = await ApiClient.dio.get('/experiences');
    return _extractList(response.data, UserExperience.fromJson);
  }

  Future<void> createEducation({
    required String organization,
    required String degree,
    required String startDate,
    String? endDate,
    bool current = false,
  }) async {
    await ApiClient.dio.post('/educations', data: {
      'organization': organization,
      'degree': degree,
      'start_date': startDate,
      'end_date': endDate,
      'current': current,
    });
  }

  Future<void> updateEducation({
    required int id,
    required String organization,
    required String degree,
    required String startDate,
    String? endDate,
    bool current = false,
  }) async {
    await ApiClient.dio.put('/educations/$id', data: {
      'organization': organization,
      'degree': degree,
      'start_date': startDate,
      'end_date': endDate,
      'current': current,
    });
  }

  Future<void> deleteEducation(int id) async {
    await ApiClient.dio.delete('/educations/$id');
  }

  Future<void> createExperience({
    required String company,
    required String position,
    required String startDate,
    String? endDate,
    bool current = false,
  }) async {
    await ApiClient.dio.post('/experiences', data: {
      'company': company,
      'position': position,
      'start_date': startDate,
      'end_date': endDate,
      'current': current,
    });
  }

  Future<void> updateExperience({
    required int id,
    required String company,
    required String position,
    required String startDate,
    String? endDate,
    bool current = false,
  }) async {
    await ApiClient.dio.put('/experiences/$id', data: {
      'company': company,
      'position': position,
      'start_date': startDate,
      'end_date': endDate,
      'current': current,
    });
  }

  Future<void> deleteExperience(int id) async {
    await ApiClient.dio.delete('/experiences/$id');
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

  List<T> _extractList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        return inner
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList(growable: false);
      }
      if (data['data'] is Map) {
        return const [];
      }
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    }
    return const [];
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.gender,
    required this.image,
    required this.jobTitle,
    required this.shortBio,
    required this.bio,
    required this.countryId,
    required this.state,
    required this.city,
    required this.address,
    required this.facebook,
    required this.twitter,
    required this.linkedin,
    required this.website,
    required this.github,
    required this.instructorProfile,
    required this.introVideoUrl,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final int age;
  final String gender;
  final String image;
  final String jobTitle;
  final String shortBio;
  final String bio;
  final int countryId;
  final String state;
  final String city;
  final String address;
  final String facebook;
  final String twitter;
  final String linkedin;
  final String website;
  final String github;
  final Map<String, dynamic> instructorProfile;
  final String introVideoUrl;

  List<String> get certificates {
    final raw = instructorProfile['certificates'];
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final instructorProfile = json['instructor_profile'] is Map
        ? Map<String, dynamic>.from(json['instructor_profile'] as Map)
        : <String, dynamic>{};
    return UserProfile(
      id: json['id'] is int ? json['id'] as int : 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      age: json['age'] is int ? json['age'] as int : 0,
      gender: (json['gender'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      jobTitle: (json['job_title'] ?? '').toString(),
      shortBio: (json['short_bio'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      countryId: json['country_id'] is int ? json['country_id'] as int : 0,
      state: (json['state'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      facebook: (json['facebook'] ?? '').toString(),
      twitter: (json['twitter'] ?? '').toString(),
      linkedin: (json['linkedin'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      github: (json['github'] ?? '').toString(),
      instructorProfile: instructorProfile,
      introVideoUrl: (json['intro_video_url'] ?? '').toString(),
    );
  }
}

class UserEducation {
  const UserEducation({
    required this.id,
    required this.organization,
    required this.degree,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  final int id;
  final String organization;
  final String degree;
  final String startDate;
  final String endDate;
  final bool current;

  factory UserEducation.fromJson(Map<String, dynamic> json) {
    return UserEducation(
      id: json['id'] is int ? json['id'] as int : 0,
      organization: (json['organization'] ?? '').toString(),
      degree: (json['degree'] ?? '').toString(),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      current: json['current'] == true,
    );
  }
}

class UserExperience {
  const UserExperience({
    required this.id,
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  final int id;
  final String company;
  final String position;
  final String startDate;
  final String endDate;
  final bool current;

  factory UserExperience.fromJson(Map<String, dynamic> json) {
    return UserExperience(
      id: json['id'] is int ? json['id'] as int : 0,
      company: (json['company'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      current: json['current'] == true,
    );
  }
}
