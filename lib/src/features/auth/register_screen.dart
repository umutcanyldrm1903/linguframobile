import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import 'auth_page_scaffold.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _trialBookingIntentKey = 'trial_booking_intent_v1';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _role = 'student';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Passwords do not match.'))),
      );
      return;
    }

    try {
      final role = await ref.read(authNotifierProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _role,
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Account created successfully.'))),
      );

      if (role == 'instructor') {
        Navigator.pushReplacementNamed(context, '/instructor');
      } else {
        final trialIntent =
            await SecureStorage.getValue(_trialBookingIntentKey);
        if (!mounted) return;
        if ((trialIntent ?? '').trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(
                  'Your trial lesson choice was saved. Continue booking from your student panel.',
                ),
              ),
            ),
          );
        }
        Navigator.pushReplacementNamed(context, '/student');
      }
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(error.message))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authNotifierProvider);

    return AuthPageScaffold(
      title: AppStrings.t('Register'),
      subtitle: AppStrings.t('Start your Learning Journey Today!'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppStrings.t('Full Name')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppStrings.t('Name is required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: AppStrings.t('Email')),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return AppStrings.t('Email is required');
                }
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(email)) {
                  return AppStrings.t(
                      'The email must be a valid email address');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppStrings.t('Phone (optional)'),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return null;
                final digitCount = phone.replaceAll(RegExp(r'\D'), '').length;
                if (digitCount < 7) {
                  return AppStrings.t('Phone number is too short');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: AppStrings.t('Password')),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return AppStrings.t('Password is required');
                }
                if ((value ?? '').length < 4) {
                  return AppStrings.t(
                    'You have to provide minimum 4 character password',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: AppStrings.t('Confirm Password')),
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Confirm Password')
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('Role'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.t('Student')),
                    selected: _role == 'student',
                    onSelected: (_) => setState(() => _role = 'student'),
                    selectedColor: AppColors.brand.withValues(alpha: 0.18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppStrings.t('Instructor')),
                    selected: _role == 'instructor',
                    onSelected: (_) => setState(() => _role = 'instructor'),
                    selectedColor: AppColors.brand.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: Text(
                  isSubmitting
                      ? AppStrings.t('Submitting')
                      : AppStrings.t('Sign Up'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                '${AppStrings.t('Already have an account?')} ${AppStrings.t('Login')}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
