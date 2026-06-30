import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';

String _errorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is Map) {
        return message.values.map((value) => value.toString()).join('\n');
      }
      if (message != null) {
        return message.toString();
      }
    }
  }
  return AppStrings.t('Something went wrong');
}

Map<String, String> _errorFields(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is Map) {
        final out = <String, String>{};
        message.forEach((key, value) {
          final field = key.toString();
          if (field.isEmpty) return;
          if (value is List && value.isNotEmpty) {
            out[field] = value.first.toString();
            return;
          }
          out[field] = value.toString();
        });
        return out;
      }
    }
  }
  return const {};
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  bool _autoValidate = false;
  Map<String, String> _apiErrors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    if (_apiErrors[field] == null) return;
    setState(() {
      _apiErrors = Map<String, String>.from(_apiErrors)..remove(field);
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    setState(() => _apiErrors = {});
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await PublicRepository().submitContact(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      showCelebration(
        context,
        title: AppStrings.t('Mesajın bize ulaştı!'),
        subtitle: AppStrings.t('Message sent successfully'),
        icon: Icons.mark_email_read_rounded,
        color: AppPalette.success,
      );
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      _phoneController.clear();
      setState(() => _autoValidate = false);
    } catch (error) {
      if (!mounted) return;
      final fields = _errorFields(error);
      if (fields.isNotEmpty) {
        setState(() {
          _apiErrors = fields;
          _autoValidate = true;
        });
        _formKey.currentState?.validate();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ContactInfo?>(
        future: PublicRepository().fetchContactInfo(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return PublicPageShell(
            title: AppStrings.t('Contact Us'),
            breadcrumb:
                '${AppStrings.t('Home')}  >  ${AppStrings.t('Contact Us')}',
            description: AppStrings.t(
              'Reach our team, send a message or open directions in one place.',
            ),
            icon: Icons.support_agent_rounded,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactPublicLayout(context) ? 14 : 18,
                ),
                child: StaggeredReveal(
                  children: [
                    _InfoGrid(info: info),
                    const SizedBox(height: 16),
                    _ContactForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      subjectController: _subjectController,
                      messageController: _messageController,
                      phoneController: _phoneController,
                      apiErrors: _apiErrors,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      isSubmitting: _isSubmitting,
                      onSubmit: _submit,
                      onFieldChanged: _clearError,
                    ),
                    const SizedBox(height: 16),
                    _MapPlaceholder(info: info),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.info});

  final ContactInfo? info;

  @override
  Widget build(BuildContext context) {
    final address = info?.address ?? '';
    final phone = [info?.phoneOne, info?.phoneTwo]
        .where((value) => value != null && value.isNotEmpty)
        .join('\n');
    final email = [info?.emailOne, info?.emailTwo]
        .where((value) => value != null && value.isNotEmpty)
        .join('\n');

    final cards = <Widget>[];
    if (address.isNotEmpty) {
      cards.add(_InfoCard(
        icon: Icons.location_on_rounded,
        title: AppStrings.t('Address'),
        subtitle: address,
        gradient: AppGradients.brand,
      ));
    }
    if (phone.isNotEmpty) {
      cards.add(_InfoCard(
        icon: Icons.call_rounded,
        title: AppStrings.t('Phone'),
        subtitle: phone,
        gradient: AppGradients.success,
      ));
    }
    if (email.isNotEmpty) {
      cards.add(_InfoCard(
        icon: Icons.email_rounded,
        title: AppStrings.t('E-mail Address'),
        subtitle: email,
        gradient: AppGradients.violet,
      ));
    }

    if (cards.isEmpty) {
      cards.add(_InfoCard(
        icon: Icons.info_outline_rounded,
        title: AppStrings.t('Information'),
        subtitle: AppStrings.t('Contact Messages'),
        gradient: AppGradients.brand,
      ));
    }

    return Column(
      children: cards
          .map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              ))
          .toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.22),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.subjectController,
    required this.messageController,
    required this.phoneController,
    required this.apiErrors,
    required this.autovalidateMode,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onFieldChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final TextEditingController phoneController;
  final Map<String, String> apiErrors;
  final AutovalidateMode autovalidateMode;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final ValueChanged<String> onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: formKey,
        autovalidateMode: autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: AppStrings.t('Send Us Message'),
                    icon: Icons.mail_outline_rounded,
                  ),
                ),
                AppStatPill(
                  icon: Icons.schedule_rounded,
                  label: AppStrings.t('2 saat içinde yanıt'),
                  color: AppPalette.success,
                  onLight: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            _InputField(
              label: '${AppStrings.t('Comment')} *',
              controller: messageController,
              maxLines: 4,
              icon: Icons.chat_bubble_outline_rounded,
              onChanged: (_) => onFieldChanged('message'),
              validator: (value) {
                final api = apiErrors['message'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('Message is required')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: '${AppStrings.t('Subject')} *',
              controller: subjectController,
              icon: Icons.subject_rounded,
              onChanged: (_) => onFieldChanged('subject'),
              validator: (value) {
                final api = apiErrors['subject'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('Subject is required')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: '${AppStrings.t('Name')} *',
              controller: nameController,
              icon: Icons.person_outline_rounded,
              onChanged: (_) => onFieldChanged('name'),
              validator: (value) {
                final api = apiErrors['name'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('Name is required')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: '${AppStrings.t('E-mail')} *',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.alternate_email_rounded,
              onChanged: (_) => onFieldChanged('email'),
              validator: (value) {
                final api = apiErrors['email'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('Email is required')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: AppStrings.t('Phone'),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              icon: Icons.call_rounded,
              onChanged: (_) => onFieldChanged('phone'),
              validator: (value) {
                final api = apiErrors['phone'];
                if (api != null && api.isNotEmpty) return api;
                return null;
              },
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: isSubmitting
                  ? AppStrings.t('Submitting')
                  : AppStrings.t('Submit Now'),
              onPressed: isSubmitting ? null : onSubmit,
              loading: isSubmitting,
              tone: AppButtonTone.brand,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.icon,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 20, color: AppColors.muted),
        filled: true,
        fillColor: AppPalette.cloud,
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.sm),
          borderSide: const BorderSide(color: AppPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.sm),
          borderSide: const BorderSide(color: AppPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.sm),
          borderSide: const BorderSide(color: AppPalette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.sm),
          borderSide: const BorderSide(color: AppPalette.danger, width: 1.6),
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.info});

  final ContactInfo? info;

  @override
  Widget build(BuildContext context) {
    final mapUrl = info?.mapUrl ?? '';
    return GradientHero(
      gradient: AppGradients.night,
      padding: const EdgeInsets.all(AppSpace.xl),
      glowColor: AppColors.accent,
      child: SizedBox(
        height: 168,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: AppRadius.all(AppRadius.sm),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              AppStrings.t('Map'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            if (mapUrl.isNotEmpty)
              AppButton(
                label: AppStrings.t('View'),
                expand: false,
                tone: AppButtonTone.success,
                icon: Icons.open_in_new_rounded,
                onPressed: () async {
                  final uri = Uri.tryParse(mapUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
