import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/profile_repository.dart';
import '../schedule/instructor_schedule_screen.dart';

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({super.key});

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  final _repo = ProfileRepository();
  final _picker = ImagePicker();

  UserProfile? _profile;
  bool _loading = true;
  bool _savingProfile = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _shortBioCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _deletePasswordCtrl = TextEditingController();

  Uint8List? _pickedImageBytes;
  XFile? _pickedIntroVideo;
  Set<String> _selectedCertificates = <String>{};
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _jobTitleCtrl.dispose();
    _shortBioCtrl.dispose();
    _bioCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _deletePasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _repo.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
      if (profile != null) {
        _nameCtrl.text = profile.name;
        _phoneCtrl.text = profile.phone;
        _emailCtrl.text = profile.email;
        _jobTitleCtrl.text = profile.jobTitle;
        _shortBioCtrl.text = profile.shortBio;
        _bioCtrl.text = profile.bio;
        _selectedCertificates = profile.certificates.toSet();
      }
    });
  }

  Future<void> _pickProfileImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
    });
    try {
      await _repo.updateProfileImage(image);
      await _loadProfile();
      _showSnack(AppStrings.t('Updated successfully'));
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _pickIntroVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    setState(() {
      _pickedIntroVideo = video;
    });
  }

  Future<void> _openIntroVideo() async {
    final url = _profile?.introVideoUrl ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _toggleCertificate(String key) {
    setState(() {
      if (_selectedCertificates.contains(key)) {
        _selectedCertificates.remove(key);
      } else {
        _selectedCertificates.add(key);
      }
    });
  }

  Future<void> _submitProfile() async {
    if (_savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      await _repo.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty
            ? (_profile?.email ?? '')
            : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        jobTitle: _jobTitleCtrl.text.trim(),
        shortBio: _shortBioCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        certificates: _selectedCertificates.toList(growable: false),
        introVideo: _pickedIntroVideo,
      );
      _showSnack(AppStrings.t('Updated successfully'));
      _pickedIntroVideo = null;
      await _loadProfile();
    } catch (e) {
      _showSnack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _submitEmail() async {
    try {
      await _repo.updateProfile(
        name: _nameCtrl.text.trim().isEmpty
            ? (_profile?.name ?? '')
            : _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      _showSnack(AppStrings.t('Updated successfully'));
      await _loadProfile();
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _submitPassword() async {
    try {
      await _repo.updatePassword(
        currentPassword: _currentPasswordCtrl.text.trim(),
        password: _newPasswordCtrl.text.trim(),
        passwordConfirmation: _confirmPasswordCtrl.text.trim(),
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showSnack(AppStrings.t('Updated successfully'));
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _submitDeleteAccount() async {
    if (_deletingAccount) return;
    final password = _deletePasswordCtrl.text.trim();
    if (password.isEmpty) {
      _showSnack(AppStrings.t('Please enter your current password.'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('Delete Account')),
        content: Text(AppStrings.t('This action cannot be undone.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t('Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t('Confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingAccount = true);
    try {
      await _repo.deleteAccount(currentPassword: password);
      await SecureStorage.clearAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _showSnack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _deletingAccount = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is Map) {
          return msg.values.map((value) => value.toString()).join('\n');
        }
        return msg.toString();
      }
      if (error.message != null) return error.message!;
    }
    return AppStrings.t('Something went wrong');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('Settings'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TabBar(
                  labelColor: AppColors.ink,
                  indicatorColor: AppColors.brand,
                  tabs: [
                    Tab(text: AppStrings.t('Profile')),
                    Tab(text: AppStrings.t('Schedule')),
                    Tab(text: AppStrings.t('Email')),
                    Tab(text: AppStrings.t('Password')),
                    Tab(text: AppStrings.t('Account')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TabBarView(
              children: [
                _ProfileTab(
                  profile: _profile,
                  pickedImageBytes: _pickedImageBytes,
                  pickedIntroVideoName: _pickedIntroVideo?.name,
                  nameCtrl: _nameCtrl,
                  phoneCtrl: _phoneCtrl,
                  jobTitleCtrl: _jobTitleCtrl,
                  shortBioCtrl: _shortBioCtrl,
                  bioCtrl: _bioCtrl,
                  selectedCertificates: _selectedCertificates,
                  onToggleCertificate: _toggleCertificate,
                  onPickImage: _pickProfileImage,
                  onPickIntroVideo: _pickIntroVideo,
                  onOpenCurrentVideo: _openIntroVideo,
                  onSubmit: _submitProfile,
                  saving: _savingProfile,
                ),
                const InstructorScheduleScreen(),
                _EmailTab(
                  emailCtrl: _emailCtrl,
                  currentPasswordCtrl: _currentPasswordCtrl,
                  onSubmit: _submitEmail,
                ),
                _PasswordTab(
                  currentCtrl: _currentPasswordCtrl,
                  newCtrl: _newPasswordCtrl,
                  confirmCtrl: _confirmPasswordCtrl,
                  onSubmit: _submitPassword,
                ),
                _DeleteAccountTab(
                  passwordCtrl: _deletePasswordCtrl,
                  deleting: _deletingAccount,
                  onSubmit: _submitDeleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.profile,
    required this.pickedImageBytes,
    required this.pickedIntroVideoName,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.jobTitleCtrl,
    required this.shortBioCtrl,
    required this.bioCtrl,
    required this.selectedCertificates,
    required this.onToggleCertificate,
    required this.onPickImage,
    required this.onPickIntroVideo,
    required this.onOpenCurrentVideo,
    required this.onSubmit,
    required this.saving,
  });

  final UserProfile? profile;
  final Uint8List? pickedImageBytes;
  final String? pickedIntroVideoName;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController jobTitleCtrl;
  final TextEditingController shortBioCtrl;
  final TextEditingController bioCtrl;
  final Set<String> selectedCertificates;
  final ValueChanged<String> onToggleCertificate;
  final VoidCallback onPickImage;
  final VoidCallback onPickIntroVideo;
  final VoidCallback onOpenCurrentVideo;
  final VoidCallback onSubmit;
  final bool saving;

  static const List<_OptionItem> _certificateOptions = [
    _OptionItem('none', 'None'),
    _OptionItem('tesol', 'TESOL'),
    _OptionItem('tefl', 'TEFL'),
    _OptionItem('celta', 'CELTA'),
  ];

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile?.image ?? '';
    final introVideoUrl = profile?.introVideoUrl ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _SectionCard(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  height: 90,
                  color: AppColors.brand.withValues(alpha: 0.2),
                  child: (() {
                    if (pickedImageBytes != null) {
                      return Image.memory(pickedImageBytes!, fit: BoxFit.cover);
                    }
                    if (imageUrl.isNotEmpty) {
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.person,
                            size: 46,
                            color: AppColors.brand,
                          ),
                        ),
                      );
                    }
                    return const Center(
                      child: Icon(
                        Icons.person,
                        size: 46,
                        color: AppColors.brand,
                      ),
                    );
                  })(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.t('Profile Photo'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'JPG or PNG, max 5 MB.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: onPickImage,
                      child: Text(AppStrings.t('New Image')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.t('Profile Information'),
          child: Column(
            children: [
              _InputField(
                  label: AppStrings.t('Full Name'), controller: nameCtrl),
              const SizedBox(height: 12),
              _InputField(
                  label: AppStrings.t('Phone Number'), controller: phoneCtrl),
              const SizedBox(height: 12),
              _InputField(
                  label: AppStrings.t('Major'), controller: jobTitleCtrl),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.t('Biography'),
          child: Column(
            children: [
              _InputField(
                label: AppStrings.t('About Me'),
                controller: shortBioCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: AppStrings.t('Teaching Style'),
                controller: bioCtrl,
                maxLines: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.t('Video'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onPickIntroVideo,
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(AppStrings.t('Upload Video')),
                  ),
                  const SizedBox(width: 10),
                  if (introVideoUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: onOpenCurrentVideo,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(AppStrings.t('View')),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pickedIntroVideoName != null
                    ? pickedIntroVideoName!
                    : (introVideoUrl.isNotEmpty
                        ? AppStrings.t('Current')
                        : AppStrings.t('No intro video')),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.t('Certificates'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _certificateOptions.map((option) {
              final selected = selectedCertificates.contains(option.key);
              return FilterChip(
                selected: selected,
                onSelected: (_) => onToggleCertificate(option.key),
                label: Text(AppStrings.t(option.label)),
              );
            }).toList(growable: false),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: saving ? null : onSubmit,
            child: Text(
              saving ? AppStrings.t('Submitting') : AppStrings.t('Update'),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailTab extends StatelessWidget {
  const _EmailTab({
    required this.emailCtrl,
    required this.currentPasswordCtrl,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController currentPasswordCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _InputField(label: AppStrings.t('New Email'), controller: emailCtrl),
        const SizedBox(height: 12),
        _InputField(
          label: AppStrings.t('Current Password'),
          controller: currentPasswordCtrl,
          obscure: true,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Change Email')),
          ),
        )
      ],
    );
  }
}

class _PasswordTab extends StatelessWidget {
  const _PasswordTab({
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
    required this.onSubmit,
  });

  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final TextEditingController confirmCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _InputField(
          label: AppStrings.t('Current Password'),
          controller: currentCtrl,
          obscure: true,
        ),
        const SizedBox(height: 12),
        _InputField(
          label: AppStrings.t('New Password'),
          controller: newCtrl,
          obscure: true,
        ),
        const SizedBox(height: 12),
        _InputField(
          label: AppStrings.t('New Password (again)'),
          controller: confirmCtrl,
          obscure: true,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Change Password')),
          ),
        )
      ],
    );
  }
}

class _DeleteAccountTab extends StatelessWidget {
  const _DeleteAccountTab({
    required this.passwordCtrl,
    required this.deleting,
    required this.onSubmit,
  });

  final TextEditingController passwordCtrl;
  final bool deleting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('Delete Account'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.t('This action cannot be undone.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _InputField(
                label: AppStrings.t('Current Password'),
                controller: passwordCtrl,
                obscure: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: deleting ? null : onSubmit,
                  child: Text(
                    deleting
                        ? AppStrings.t('Submitting')
                        : AppStrings.t('Delete Account'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(title!, style: Theme.of(context).textTheme.titleLarge),
          if (title != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

class _OptionItem {
  const _OptionItem(this.key, this.label);

  final String key;
  final String label;
}
