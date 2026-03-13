import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Message sent successfully'))),
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
                child: Column(
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
        icon: Icons.location_on,
        title: AppStrings.t('Address'),
        subtitle: address,
      ));
    }
    if (phone.isNotEmpty) {
      cards.add(_InfoCard(
        icon: Icons.call,
        title: AppStrings.t('Phone'),
        subtitle: phone,
      ));
    }
    if (email.isNotEmpty) {
      cards.add(_InfoCard(
        icon: Icons.email,
        title: AppStrings.t('E-mail Address'),
        subtitle: email,
      ));
    }

    if (cards.isEmpty) {
      cards.add(_InfoCard(
        icon: Icons.info_outline,
        title: AppStrings.t('Information'),
        subtitle: AppStrings.t('Contact Messages'),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brand.withValues(alpha: 0.15),
            child: Icon(icon, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: formKey,
        autovalidateMode: autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('Send Us Message'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _InputField(
              label: '${AppStrings.t('Comment')} *',
              controller: messageController,
              maxLines: 4,
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
              onChanged: (_) => onFieldChanged('phone'),
              validator: (value) {
                final api = apiErrors['phone'];
                if (api != null && api.isNotEmpty) return api;
                return null;
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: Text(isSubmitting
                    ? AppStrings.t('Submitting')
                    : AppStrings.t('Submit Now')),
              ),
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
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.info});

  final ContactInfo? info;

  @override
  Widget build(BuildContext context) {
    final mapUrl = info?.mapUrl ?? '';
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: mapUrl.isEmpty
            ? Text(AppStrings.t('Map'))
            : ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(mapUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map),
                label: Text(AppStrings.t('View')),
              ),
      ),
    );
  }
}
