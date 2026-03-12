import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_strings.dart';
import 'auth_repository.dart';

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

String _normalizeResetToken(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  // Allow pasting the full email link, e.g:
  // https://www.example.com/reset-password-page/{token}
  final uri = Uri.tryParse(value);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    final last = uri.pathSegments.last.trim();
    if (last.isNotEmpty && last.length >= 10) return last;
  }

  // Fallback: take the part after the known path segment.
  const marker = '/reset-password-page/';
  final idx = value.indexOf(marker);
  if (idx != -1) {
    final token = value.substring(idx + marker.length).split('?').first.trim();
    if (token.isNotEmpty) return token;
  }

  return value;
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController =
      TextEditingController(text: widget.initialEmail ?? '');
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pasteToken() async {
    final data = await Clipboard.getData('text/plain');
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) return;
    _tokenController.text = _normalizeResetToken(text);
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = await AuthRepository().resetPassword(
        email: _emailController.text.trim(),
        token: _normalizeResetToken(_tokenController.text),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      final message = (data['message'] ?? '').toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isNotEmpty
                ? message
                : AppStrings.t('Password Reset successfully'),
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Reset Password'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.t('Reset Password'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(
              'Paste the token from your email and set a new password.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: AppStrings.t('Email')),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return AppStrings.t('Email is required');
                    if (!email.contains('@')) return AppStrings.t('Invalid email');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Reset Token'),
                    hintText: AppStrings.t('Paste token or reset link'),
                    suffixIcon: IconButton(
                      tooltip: AppStrings.t('Paste'),
                      onPressed: _pasteToken,
                      icon: const Icon(Icons.paste),
                    ),
                  ),
                  validator: (value) {
                    final token = _normalizeResetToken(value ?? '');
                    if (token.isEmpty) {
                      return AppStrings.t('Forget password token is required');
                    }
                    if (token.length < 10) {
                      return AppStrings.t('Invalid token');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: AppStrings.t('New Password')),
                  validator: (value) {
                    final password = (value ?? '').trim();
                    if (password.isEmpty) return AppStrings.t('Password is required');
                    if (password.length < 4) {
                      return AppStrings.t('Password must be 4 characters');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('Confirm Password'),
                  ),
                  validator: (value) {
                    if ((value ?? '') != _passwordController.text) {
                      return AppStrings.t('Confirm password does not match');
                    }
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
                    : AppStrings.t('Reset Password'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

