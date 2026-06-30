import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import 'auth_page_scaffold.dart';
import 'auth_provider.dart';
import 'auth_visuals.dart';
import 'auth_widgets.dart';
import 'social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _pendingAfterLoginRouteKey = 'pending_after_login_route_v1';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Maskot reaktif durumu
  double _lookX = 0;
  double _lookDown = 0;
  double _cover = 0;
  AuthMascotMood _mood = AuthMascotMood.idle;
  bool _passwordObscured = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_updateMascot);
    _passwordFocus.addListener(_updateMascot);
    _emailController.addListener(_updateMascot);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _updateMascot() {
    double lookX = 0;
    double lookDown = 0;
    double cover = 0;
    var mood = AuthMascotMood.idle;

    if (_passwordFocus.hasFocus) {
      // Şifre alanı: gizliyse gözleri kapat, görünürse gözetle.
      cover = _passwordObscured ? 1 : 0.15;
      mood = _passwordObscured ? AuthMascotMood.idle : AuthMascotMood.happy;
    } else if (_emailFocus.hasFocus) {
      // E-posta alanına bakar; yazdıkça gözler sağa kayar.
      lookDown = 0.7;
      mood = AuthMascotMood.thinking;
      final len = _emailController.text.length.clamp(0, 22);
      lookX = (len / 22) * 1.4 - 0.7;
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

    try {
      final role = await ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
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

    Navigator.pushReplacementNamed(context, '/student');
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authNotifierProvider);
    final covering = _cover > 0.5;

    return AuthPageScaffold(
      title: AppStrings.t('Login'),
      subtitle: AppStrings.t('Sign in to continue your journey'),
      bubbleText: covering
          ? AppStrings.t('I won\'t peek 🙈')
          : AppStrings.t('Welcome back!'),
      mascot: AuthMascot(
        size: 132,
        lookX: _lookX,
        lookDown: _lookDown,
        cover: _cover,
        mood: _mood,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
            const SizedBox(height: 14),
            AuthPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: AppStrings.t('Password'),
              textInputAction: TextInputAction.done,
              onObscureChanged: (obscure) {
                _passwordObscured = obscure;
                _updateMascot();
              },
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return AppStrings.t('Password is required');
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading
                    ? null
                    : () => Navigator.pushNamed(context, '/forgot-password'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  AppStrings.t('Forgot Password'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(
              label: loading ? AppStrings.t('Submitting') : AppStrings.t('Login'),
              loading: loading,
              icon: Icons.login_rounded,
              onPressed: loading ? null : _submit,
            ),
            const SizedBox(height: 20),
            AuthDivider(label: AppStrings.t('Or continue with')),
            const SizedBox(height: 16),
            SocialAuthButtons(
              loading: loading,
              onAuthenticated: _completeAuth,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.t('Don\'t have an account?'),
                  style: const TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    AppStrings.t('Sign Up'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
