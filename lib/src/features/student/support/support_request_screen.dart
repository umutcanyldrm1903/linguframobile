import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../profile/profile_repository.dart';
import 'support_models.dart';
import 'support_repository.dart';

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

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key, required this.category});

  final SupportCategory category;

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _submitting = false;
  bool _autoValidate = false;
  Map<String, String> _apiErrors = const {};

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    try {
      final profile = await ProfileRepository().fetchProfile();
      if (!mounted || profile == null) return;
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      setState(() {});
    } catch (_) {}
  }

  void _clearError(String field) {
    if (_apiErrors[field] == null) return;
    setState(() {
      _apiErrors = Map<String, String>.from(_apiErrors)..remove(field);
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    setState(() => _apiErrors = const {});
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final subject = 'Support: ${widget.category.title}';
      await SupportRepository().createRequest(
        subject: subject,
        message: _messageController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      await showCelebration(
        context,
        title: AppStrings.t('Message sent successfully'),
        subtitle: AppStrings.t('Describe your issue and we will reply by email.'),
        icon: Icons.mark_email_read_rounded,
        color: AppPalette.success,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? errorText,
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: AppColors.brand),
      filled: true,
      fillColor: AppPalette.cloud,
      labelStyle: const TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppPalette.line, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppPalette.line, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppPalette.danger, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.all(AppRadius.sm),
        borderSide: const BorderSide(color: AppPalette.danger, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = 'Support: ${widget.category.title}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.t('New Support Request')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              AnimatedPageEntrance(
                child: GradientHero(
                  gradient: AppGradients.hero,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: AppRadius.all(AppRadius.md),
                        ),
                        child: Icon(
                          widget.category.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpace.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t(widget.category.title),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.t(
                                'Describe your issue and we will reply by email.',
                              ),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              AnimatedPageEntrance(
                delay: const Duration(milliseconds: 90),
                child: AppCard(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: AppStrings.t('New Support Request'),
                          subtitle: AppStrings.t(
                            'Describe your issue and we will reply by email.',
                          ),
                          icon: Icons.support_agent_rounded,
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: _fieldDecoration(
                            label: AppStrings.t('Name'),
                            errorText: _apiErrors['name'],
                            icon: Icons.person_outline_rounded,
                          ),
                          onChanged: (_) => _clearError('name'),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) {
                              return AppStrings.t('Name is required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _fieldDecoration(
                            label: AppStrings.t('Email'),
                            errorText: _apiErrors['email'],
                            icon: Icons.alternate_email_rounded,
                          ),
                          onChanged: (_) => _clearError('email'),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) {
                              return AppStrings.t('Email is required');
                            }
                            if (!v.contains('@')) {
                              return AppStrings.t('Invalid email');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration(
                            label: AppStrings.t('Phone'),
                            errorText: _apiErrors['phone'],
                            icon: Icons.phone_outlined,
                          ),
                          onChanged: (_) => _clearError('phone'),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          enabled: false,
                          initialValue: subject,
                          decoration: _fieldDecoration(
                            label: AppStrings.t('Subject'),
                            icon: Icons.subject_rounded,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: _fieldDecoration(
                            label: AppStrings.t('Message'),
                            errorText: _apiErrors['message'],
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) => _clearError('message'),
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) {
                              return AppStrings.t('Message is required');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              AnimatedPageEntrance(
                delay: const Duration(milliseconds: 160),
                child: AppButton(
                  label: _submitting
                      ? AppStrings.t('Submitting')
                      : AppStrings.t('Submit'),
                  tone: AppButtonTone.brand,
                  icon: Icons.send_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
