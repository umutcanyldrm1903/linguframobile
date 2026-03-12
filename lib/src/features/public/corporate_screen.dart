import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'public_header.dart';
import 'public_footer.dart';
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

class CorporateScreen extends StatefulWidget {
  const CorporateScreen({super.key});

  @override
  State<CorporateScreen> createState() => _CorporateScreenState();
}

class _CorporateScreenState extends State<CorporateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _traineesController = TextEditingController();
  bool _isSubmitting = false;
  bool _autoValidate = false;
  Map<String, String> _apiErrors = {};

  @override
  void dispose() {
    _companyController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _traineesController.dispose();
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
      await PublicRepository().submitCorporate(
        company: _companyController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        trainees: _traineesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Message sent successfully'))),
      );
      _formKey.currentState!.reset();
      _companyController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _traineesController.clear();
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PublicHeader(),
          _HeroBanner(
            title: AppStrings.t('Corporate'),
            breadcrumb:
                '${AppStrings.t('Home')}  >  ${AppStrings.t('Corporate')}',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const _CorporateCta(),
                const SizedBox(height: 16),
                _CorporateForm(
                  formKey: _formKey,
                  companyController: _companyController,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  traineesController: _traineesController,
                  apiErrors: _apiErrors,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                  onFieldChanged: _clearError,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PublicFooter(),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.title, required this.breadcrumb});

  final String title;
  final String breadcrumb;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D5B90),
            Color(0xFF0B466F),
            Color(0xFF082C46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.10,
            child: Image.asset('assets/web/banner_bg.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  breadcrumb,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
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

class _CorporateCta extends StatelessWidget {
  const _CorporateCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.t('Let your company cover your lesson fees!'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(
                'Fill in the details for a corporate training quote. Our team will get back to you shortly.'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/web/h4_cta_bg.jpg', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _CorporateForm extends StatelessWidget {
  const _CorporateForm({
    required this.formKey,
    required this.companyController,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.traineesController,
    required this.apiErrors,
    required this.autovalidateMode,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onFieldChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController traineesController;
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
            Text(AppStrings.t('Corporate Form'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _InputField(
              label: '${AppStrings.t('Company name')} *',
              controller: companyController,
              onChanged: (_) => onFieldChanged('company_name'),
              validator: (value) {
                final api = apiErrors['company_name'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('The name field is required.')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: '${AppStrings.t('Contact first name')} *',
              controller: firstNameController,
              onChanged: (_) => onFieldChanged('contact_first_name'),
              validator: (value) {
                final api = apiErrors['contact_first_name'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('The name field is required.')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: '${AppStrings.t('Contact last name')} *',
              controller: lastNameController,
              onChanged: (_) => onFieldChanged('contact_last_name'),
              validator: (value) {
                final api = apiErrors['contact_last_name'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('The name field is required.')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: '${AppStrings.t('Corporate email')} *',
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
              label: '${AppStrings.t('Phone')} *',
              controller: phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => onFieldChanged('phone'),
              validator: (value) {
                final api = apiErrors['phone'];
                if (api != null && api.isNotEmpty) return api;
                return value == null || value.isEmpty
                    ? AppStrings.t('Phone is required')
                    : null;
              },
            ),
            const SizedBox(height: 10),
            _InputField(
              label: AppStrings.t('Number of trainees'),
              controller: traineesController,
              keyboardType: TextInputType.number,
              onChanged: (_) => onFieldChanged('trainees'),
              validator: (value) {
                final api = apiErrors['trainees'];
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
                    : AppStrings.t('Submit your company')),
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
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
