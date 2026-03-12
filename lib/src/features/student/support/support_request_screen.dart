import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Message sent successfully'))),
      );
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

  @override
  Widget build(BuildContext context) {
    final subject = 'Support: ${widget.category.title}';

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('New Support Request'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.t(widget.category.title),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t('Describe your issue and we will reply by email.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Name'),
                    errorText: _apiErrors['name'],
                  ),
                  onChanged: (_) => _clearError('name'),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return AppStrings.t('Name is required');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Email'),
                    errorText: _apiErrors['email'],
                  ),
                  onChanged: (_) => _clearError('email'),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return AppStrings.t('Email is required');
                    if (!v.contains('@')) return AppStrings.t('Invalid email');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Phone'),
                    errorText: _apiErrors['phone'],
                  ),
                  onChanged: (_) => _clearError('phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: false,
                  initialValue: subject,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Subject'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Message'),
                    errorText: _apiErrors['message'],
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) => _clearError('message'),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return AppStrings.t('Message is required');
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(
                _submitting
                    ? AppStrings.t('Submitting')
                    : AppStrings.t('Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
