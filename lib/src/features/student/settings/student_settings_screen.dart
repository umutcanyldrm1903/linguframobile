import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/profile_repository.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final _repo = ProfileRepository();
  final _picker = ImagePicker();

  UserProfile? _profile;
  bool _loading = true;
  String? _loadError;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  final _jobTitleCtrl = TextEditingController();
  final _shortBioCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _countryCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _facebookCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _deletePasswordCtrl = TextEditingController();

  Uint8List? _pickedImageBytes;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _jobTitleCtrl.dispose();
    _shortBioCtrl.dispose();
    _bioCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _facebookCtrl.dispose();
    _twitterCtrl.dispose();
    _linkedinCtrl.dispose();
    _websiteCtrl.dispose();
    _githubCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _deletePasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _repo.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        if (profile != null) {
          _nameCtrl.text = profile.name;
          _emailCtrl.text = profile.email;
          _phoneCtrl.text = profile.phone;
          _ageCtrl.text = profile.age == 0 ? '' : profile.age.toString();
          _genderCtrl.text = profile.gender;
          _jobTitleCtrl.text = profile.jobTitle;
          _shortBioCtrl.text = profile.shortBio;
          _bioCtrl.text = profile.bio;
          _countryCtrl.text =
              profile.countryId == 0 ? '' : profile.countryId.toString();
          _stateCtrl.text = profile.state;
          _cityCtrl.text = profile.city;
          _addressCtrl.text = profile.address;
          _facebookCtrl.text = profile.facebook;
          _twitterCtrl.text = profile.twitter;
          _linkedinCtrl.text = profile.linkedin;
          _websiteCtrl.text = profile.website;
          _githubCtrl.text = profile.github;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = _errorMessage(error);
      });
    }
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

  Future<void> _submitProfile() async {
    try {
      await _repo.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        gender: _genderCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()),
      );
      _showSnack(AppStrings.t('Updated successfully'));
      await _loadProfile();
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _submitBio() async {
    try {
      await _repo.updateBio(
        jobTitle: _jobTitleCtrl.text.trim(),
        shortBio: _shortBioCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );
      _showSnack(AppStrings.t('Updated successfully'));
      await _loadProfile();
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _submitLocation() async {
    final countryId = int.tryParse(_countryCtrl.text.trim()) ?? 0;
    try {
      await _repo.updateAddress(
        countryId: countryId,
        state: _stateCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      _showSnack(AppStrings.t('Updated successfully'));
      await _loadProfile();
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _submitSocials() async {
    try {
      await _repo.updateSocials(
        facebook: _facebookCtrl.text.trim(),
        twitter: _twitterCtrl.text.trim(),
        linkedin: _linkedinCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        github: _githubCtrl.text.trim(),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadProfile,
                child: Text(AppStrings.t('Try Again')),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('Profile Settings')),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.ink,
            indicatorColor: AppColors.brand,
            tabs: [
              Tab(text: AppStrings.t('Profile')),
              Tab(text: AppStrings.t('Bio')),
              Tab(text: AppStrings.t('Education')),
              Tab(text: AppStrings.t('Location')),
              Tab(text: AppStrings.t('Social')),
              Tab(text: AppStrings.t('Password')),
              Tab(text: AppStrings.t('Account')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(
              profile: _profile,
              pickedImageBytes: _pickedImageBytes,
              nameCtrl: _nameCtrl,
              emailCtrl: _emailCtrl,
              phoneCtrl: _phoneCtrl,
              genderCtrl: _genderCtrl,
              ageCtrl: _ageCtrl,
              onPickImage: _pickProfileImage,
              onSubmit: _submitProfile,
            ),
            _BioTab(
              jobTitleCtrl: _jobTitleCtrl,
              shortBioCtrl: _shortBioCtrl,
              bioCtrl: _bioCtrl,
              onSubmit: _submitBio,
            ),
            const _EducationTab(),
            _LocationTab(
              countryCtrl: _countryCtrl,
              stateCtrl: _stateCtrl,
              cityCtrl: _cityCtrl,
              addressCtrl: _addressCtrl,
              onSubmit: _submitLocation,
            ),
            _SocialTab(
              facebookCtrl: _facebookCtrl,
              twitterCtrl: _twitterCtrl,
              linkedinCtrl: _linkedinCtrl,
              websiteCtrl: _websiteCtrl,
              githubCtrl: _githubCtrl,
              onSubmit: _submitSocials,
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
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.profile,
    required this.pickedImageBytes,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.genderCtrl,
    required this.ageCtrl,
    required this.onPickImage,
    required this.onSubmit,
  });

  final UserProfile? profile;
  final Uint8List? pickedImageBytes;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController genderCtrl;
  final TextEditingController ageCtrl;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile?.image ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _SectionCard(
          child: Column(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(child: Text(AppStrings.t('Edit Cover Photo'))),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.brand.withOpacity(0.2),
                    child: ClipOval(
                      child: (() {
                        if (pickedImageBytes != null) {
                          return Image.memory(
                            pickedImageBytes!,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          );
                        }
                        if (imageUrl.isNotEmpty) {
                          return Image.network(
                            imageUrl,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 68,
                              height: 68,
                              child: Icon(Icons.person, color: AppColors.brand),
                            ),
                          );
                        }
                        return const SizedBox(
                          width: 68,
                          height: 68,
                          child: Icon(Icons.person, color: AppColors.brand),
                        );
                      })(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t('User Name'),
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(AppStrings.t('User Email'),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onPickImage,
                    child: Text(AppStrings.t('New Image')),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InputField(label: AppStrings.t('Full Name'), controller: nameCtrl),
        const SizedBox(height: 12),
        _InputField(
            label: AppStrings.t('Email Address'), controller: emailCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('Phone Number'), controller: phoneCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('Gender'), controller: genderCtrl),
        const SizedBox(height: 12),
        _InputField(
          label: AppStrings.t('Age'),
          controller: ageCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Update Info')),
          ),
        )
      ],
    );
  }
}

class _BioTab extends StatelessWidget {
  const _BioTab({
    required this.jobTitleCtrl,
    required this.shortBioCtrl,
    required this.bioCtrl,
    required this.onSubmit,
  });

  final TextEditingController jobTitleCtrl;
  final TextEditingController shortBioCtrl;
  final TextEditingController bioCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _InputField(
            label: AppStrings.t('Designation'), controller: jobTitleCtrl),
        const SizedBox(height: 12),
        _InputField(
          label: AppStrings.t('Short Bio'),
          controller: shortBioCtrl,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        _InputField(
            label: AppStrings.t('Bio'), controller: bioCtrl, maxLines: 6),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Update Info')),
          ),
        )
      ],
    );
  }
}

class _EducationTab extends StatefulWidget {
  const _EducationTab();

  @override
  State<_EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<_EducationTab> {
  final ProfileRepository _repo = ProfileRepository();
  bool _loading = true;
  List<UserExperience> _experiences = const [];
  List<UserEducation> _educations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final experiences = await _repo.fetchExperiences();
      final educations = await _repo.fetchEducations();
      if (!mounted) return;
      setState(() {
        _experiences = experiences;
        _educations = educations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(_errorMessage(e));
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

  Future<void> _openExperienceForm({UserExperience? item}) async {
    final companyCtrl = TextEditingController(text: item?.company ?? '');
    final positionCtrl = TextEditingController(text: item?.position ?? '');
    final startCtrl = TextEditingController(text: item?.startDate ?? '');
    final endCtrl = TextEditingController(text: item?.endDate ?? '');
    bool current = item?.current ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item == null
                        ? AppStrings.t('Add Experience')
                        : AppStrings.t('Update'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                      label: AppStrings.t('Company'), controller: companyCtrl),
                  const SizedBox(height: 10),
                  _InputField(
                      label: AppStrings.t('Position'),
                      controller: positionCtrl),
                  const SizedBox(height: 10),
                  _InputField(
                      label: AppStrings.t('Start Date'), controller: startCtrl),
                  const SizedBox(height: 10),
                  _InputField(
                      label: AppStrings.t('End Date'), controller: endCtrl),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: current,
                    onChanged: (value) => setModalState(() => current = value),
                    title: Text(AppStrings.t('Current')),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (item == null) {
                            await _repo.createExperience(
                              company: companyCtrl.text.trim(),
                              position: positionCtrl.text.trim(),
                              startDate: startCtrl.text.trim(),
                              endDate: endCtrl.text.trim().isEmpty
                                  ? null
                                  : endCtrl.text.trim(),
                              current: current,
                            );
                          } else {
                            await _repo.updateExperience(
                              id: item.id,
                              company: companyCtrl.text.trim(),
                              position: positionCtrl.text.trim(),
                              startDate: startCtrl.text.trim(),
                              endDate: endCtrl.text.trim().isEmpty
                                  ? null
                                  : endCtrl.text.trim(),
                              current: current,
                            );
                          }
                          if (mounted) Navigator.pop(context);
                          await _load();
                          _showSnack(AppStrings.t('Updated successfully'));
                        } catch (e) {
                          _showSnack(_errorMessage(e));
                        }
                      },
                      child: Text(AppStrings.t('Save')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openEducationForm({UserEducation? item}) async {
    final orgCtrl = TextEditingController(text: item?.organization ?? '');
    final degreeCtrl = TextEditingController(text: item?.degree ?? '');
    final startCtrl = TextEditingController(text: item?.startDate ?? '');
    final endCtrl = TextEditingController(text: item?.endDate ?? '');
    bool current = item?.current ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item == null
                        ? AppStrings.t('Add Education')
                        : AppStrings.t('Update'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                      label: AppStrings.t('Organization'), controller: orgCtrl),
                  const SizedBox(height: 10),
                  _InputField(
                      label: AppStrings.t('Degree'), controller: degreeCtrl),
                  const SizedBox(height: 10),
                  _InputField(
                      label: AppStrings.t('Start Date'), controller: startCtrl),
                  const SizedBox(height: 10),
                  _InputField(
                      label: AppStrings.t('End Date'), controller: endCtrl),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: current,
                    onChanged: (value) => setModalState(() => current = value),
                    title: Text(AppStrings.t('Current')),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (item == null) {
                            await _repo.createEducation(
                              organization: orgCtrl.text.trim(),
                              degree: degreeCtrl.text.trim(),
                              startDate: startCtrl.text.trim(),
                              endDate: endCtrl.text.trim().isEmpty
                                  ? null
                                  : endCtrl.text.trim(),
                              current: current,
                            );
                          } else {
                            await _repo.updateEducation(
                              id: item.id,
                              organization: orgCtrl.text.trim(),
                              degree: degreeCtrl.text.trim(),
                              startDate: startCtrl.text.trim(),
                              endDate: endCtrl.text.trim().isEmpty
                                  ? null
                                  : endCtrl.text.trim(),
                              current: current,
                            );
                          }
                          if (mounted) Navigator.pop(context);
                          await _load();
                          _showSnack(AppStrings.t('Updated successfully'));
                        } catch (e) {
                          _showSnack(_errorMessage(e));
                        }
                      },
                      child: Text(AppStrings.t('Save')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteExperience(UserExperience item) async {
    try {
      await _repo.deleteExperience(item.id);
      await _load();
      _showSnack(AppStrings.t('Deleted successfully'));
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  Future<void> _deleteEducation(UserEducation item) async {
    try {
      await _repo.deleteEducation(item.id);
      await _load();
      _showSnack(AppStrings.t('Deleted successfully'));
    } catch (e) {
      _showSnack(_errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _SectionCard(
          title: AppStrings.t('Experience'),
          child: Column(
            children: _experiences.isEmpty
                ? [
                    Text(AppStrings.t('No Data!'),
                        style: const TextStyle(color: AppColors.muted)),
                  ]
                : _experiences
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListRow(
                            title: item.company,
                            subtitle:
                                '${item.position} · ${item.startDate}${item.current ? '' : ' - ${item.endDate}'}',
                            onEdit: () => _openExperienceForm(item: item),
                            onDelete: () => _deleteExperience(item),
                          ),
                        ))
                    .toList(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openExperienceForm(),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.t('Add Experience')),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.t('Education'),
          child: Column(
            children: _educations.isEmpty
                ? [
                    Text(AppStrings.t('No Data!'),
                        style: const TextStyle(color: AppColors.muted)),
                  ]
                : _educations
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListRow(
                            title: item.degree,
                            subtitle:
                                '${item.organization} · ${item.startDate}${item.current ? '' : ' - ${item.endDate}'}',
                            onEdit: () => _openEducationForm(item: item),
                            onDelete: () => _deleteEducation(item),
                          ),
                        ))
                    .toList(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openEducationForm(),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.t('Add Education')),
          ),
        ),
      ],
    );
  }
}

class _LocationTab extends StatelessWidget {
  const _LocationTab({
    required this.countryCtrl,
    required this.stateCtrl,
    required this.cityCtrl,
    required this.addressCtrl,
    required this.onSubmit,
  });

  final TextEditingController countryCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController addressCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _InputField(
          label: AppStrings.t('Country'),
          controller: countryCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('State'), controller: stateCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('City'), controller: cityCtrl),
        const SizedBox(height: 12),
        _InputField(
          label: AppStrings.t('Address'),
          controller: addressCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Update Location')),
          ),
        )
      ],
    );
  }
}

class _SocialTab extends StatelessWidget {
  const _SocialTab({
    required this.facebookCtrl,
    required this.twitterCtrl,
    required this.linkedinCtrl,
    required this.websiteCtrl,
    required this.githubCtrl,
    required this.onSubmit,
  });

  final TextEditingController facebookCtrl;
  final TextEditingController twitterCtrl;
  final TextEditingController linkedinCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController githubCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _InputField(label: AppStrings.t('Facebook'), controller: facebookCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('Twitter'), controller: twitterCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('Linkedin'), controller: linkedinCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('Website'), controller: websiteCtrl),
        const SizedBox(height: 12),
        _InputField(label: AppStrings.t('Github'), controller: githubCtrl),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Update Social')),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          label: AppStrings.t('Re-Type New Password'),
          controller: confirmCtrl,
          obscure: true,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: Text(AppStrings.t('Update Password')),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            color: Colors.black.withOpacity(0.05),
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
    this.maxLines,
    this.keyboardType,
    this.obscure = false,
  });

  final String label;
  final TextEditingController controller;
  final int? maxLines;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: AppColors.muted),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
