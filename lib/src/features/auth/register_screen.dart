import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../public/public_repository.dart';
import 'auth_page_scaffold.dart';
import 'auth_provider.dart';
import 'auth_visuals.dart';
import 'auth_widgets.dart';
import 'social_auth_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _trialBookingIntentKey = 'trial_booking_intent_v1';
  static const _pendingAfterLoginRouteKey = 'pending_after_login_route_v1';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String _role = 'student';

  // Maskot reaktif durumu
  double _lookX = 0;
  double _lookDown = 0;
  double _cover = 0;
  AuthMascotMood _mood = AuthMascotMood.idle;
  bool _passwordObscured = true;
  bool _confirmObscured = true;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_updateMascot);
    _emailFocus.addListener(_updateMascot);
    _passwordFocus.addListener(_updateMascot);
    _confirmFocus.addListener(_updateMascot);
    _emailController.addListener(_updateMascot);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _updateMascot() {
    double lookX = 0;
    double lookDown = 0;
    double cover = 0;
    var mood = AuthMascotMood.idle;

    if (_passwordFocus.hasFocus) {
      cover = _passwordObscured ? 1 : 0.15;
      mood = _passwordObscured ? AuthMascotMood.idle : AuthMascotMood.happy;
    } else if (_confirmFocus.hasFocus) {
      cover = _confirmObscured ? 1 : 0.15;
      mood = _confirmObscured ? AuthMascotMood.idle : AuthMascotMood.happy;
    } else if (_emailFocus.hasFocus) {
      lookDown = 0.7;
      mood = AuthMascotMood.thinking;
      final len = _emailController.text.length.clamp(0, 22);
      lookX = (len / 22) * 1.4 - 0.7;
    } else if (_nameFocus.hasFocus) {
      lookDown = 0.35;
      mood = AuthMascotMood.happy;
    }

    if (mounted) {
      setState(() {
        _lookX = lookX;
        _lookDown = lookDown;
        _cover = cover;
        _mood = mood;
      });
    }
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

      await _completeAuth(role);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(error.message))),
      );
    }
  }

  Future<void> _completeAuth(String role) async {
    if (role == 'instructor') {
      await SecureStorage.deleteValue(_pendingAfterLoginRouteKey);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/instructor');
      return;
    }

    final pending =
        (await SecureStorage.getValue(_pendingAfterLoginRouteKey) ?? '').trim();
    if (!mounted) return;
    if (pending.startsWith('/practice')) {
      await SecureStorage.deleteValue(_pendingAfterLoginRouteKey);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, pending);
      return;
    }

    final trialIntent = await SecureStorage.getValue(_trialBookingIntentKey);
    if (!mounted) return;
    if ((trialIntent ?? '').trim().isNotEmpty) {
      final trialMessage = await _claimTrialLessonAfterAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trialMessage,
          ),
        ),
      );
    }
    Navigator.pushReplacementNamed(context, '/student');
  }

  Future<String> _claimTrialLessonAfterAuth() async {
    try {
      final result = await PublicRepository().requestTrialLesson();
      await SecureStorage.deleteValue(_trialBookingIntentKey);
      return result.message.trim().isNotEmpty
          ? result.message.trim()
          : AppStrings.t('Your öne-time free trial lesson has been created.');
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 409) {
        await SecureStorage.deleteValue(_trialBookingIntentKey);
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          final message = data['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
      return AppStrings.t(
        'Your trial lesson choice was saved. Continue booking from your student panel.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authNotifierProvider);
    final covering = _cover > 0.5;

    return AuthPageScaffold(
      title: AppStrings.t('Register'),
      subtitle: AppStrings.t('Create your free account'),
      bubbleText: covering
          ? AppStrings.t('I won\'t peek 🙈')
          : AppStrings.t('Nice to meet you!'),
      mascot: AuthMascot(
        size: 124,
        lookX: _lookX,
        lookDown: _lookDown,
        cover: _cover,
        mood: _mood,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              controller: _nameController,
              focusNode: _nameFocus,
              label: AppStrings.t('Full Name'),
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppStrings.t('Name is required')
                  : null,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: AppStrings.t('Email'),
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return AppStrings.t('Email is required');
                }
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(email)) {
                  return AppStrings.t('The email must be a valid email address');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _phoneController,
              label: AppStrings.t('Phone (optional)'),
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
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
            AuthPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: AppStrings.t('Password'),
              textInputAction: TextInputAction.next,
              onObscureChanged: (obscure) {
                _passwordObscured = obscure;
                _updateMascot();
              },
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
            AuthPasswordField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              label: AppStrings.t('Confirm Password'),
              textInputAction: TextInputAction.done,
              onObscureChanged: (obscure) {
                _confirmObscured = obscure;
                _updateMascot();
              },
              validator: (value) => value == null || value.isEmpty
                  ? AppStrings.t('Confirm Password')
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.t('Role'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _RolePill(
                    label: AppStrings.t('Student'),
                    icon: Icons.school_rounded,
                    selected: _role == 'student',
                    onTap: () => setState(() => _role = 'student'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RolePill(
                    label: AppStrings.t('Instructor'),
                    icon: Icons.cast_for_education_rounded,
                    selected: _role == 'instructor',
                    onTap: () => setState(() => _role = 'instructor'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: isSubmitting
                  ? AppStrings.t('Submitting')
                  : AppStrings.t('Sign Up'),
              loading: isSubmitting,
              icon: Icons.rocket_launch_rounded,
              onPressed: isSubmitting ? null : _submit,
            ),
            const SizedBox(height: 20),
            AuthDivider(label: AppStrings.t('Or continue with')),
            const SizedBox(height: 16),
            SocialAuthButtons(
              loading: isSubmitting,
              onAuthenticated: (role) => _completeAuth(role),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.t('Already have an account?'),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(
                      AppStrings.t('Login'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Öğrenci / Eğitmen seçim hapı.
class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.brand : const Color(0xFFE2E8FF),
            width: 1.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.muted,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
