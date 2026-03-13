import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../payment/payment_native_service.dart';
import 'auth_page_scaffold.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<String>? _deepLinkSub;
  bool _socialLoading = false;
  bool _handledAuthDeepLink = false;

  @override
  void initState() {
    super.initState();

    _deepLinkSub = PaymentNativeService.deepLinkStream.listen(_handleDeepLink);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final last = PaymentNativeService.consumeLastDeepLink();
      if (last != null) _handleDeepLink(last);
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    if (_socialLoading) return;
    setState(() => _socialLoading = true);
    try {
      final uri = Uri.parse('${AppConfig.webBaseUrl}/auth/google?app=1');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Something went wrong'))),
        );
      }
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  Future<void> _handleDeepLink(String link) async {
    if (_handledAuthDeepLink) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != 'lingufranca' || uri.host != 'auth') {
      return;
    }

    final result = (uri.queryParameters['result'] ?? '').toLowerCase();
    final message = (uri.queryParameters['message'] ?? '').trim();

    if (result != 'success') {
      _handledAuthDeepLink = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message.isNotEmpty ? message : AppStrings.t('Login Failed')),
        ),
      );
      return;
    }

    final token = (uri.queryParameters['token'] ?? '').trim();
    if (token.isEmpty) return;
    _handledAuthDeepLink = true;

    final roleFromLink = (uri.queryParameters['role'] ?? '').trim();
    final userId = (uri.queryParameters['user_id'] ?? '').trim();

    await SecureStorage.setToken(token);
    ref.read(authTokenProvider.notifier).state = token;
    if (userId.isNotEmpty) {
      await SecureStorage.setUserId(userId);
    }
    if (roleFromLink.isNotEmpty) {
      await SecureStorage.setRole(roleFromLink);
    }

    try {
      final profile = await AuthRepository().profile();
      final profileData = profile['data'];
      if (profileData is Map<String, dynamic>) {
        final name = profileData['name']?.toString().trim() ?? '';
        final role = profileData['role']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          await SecureStorage.setUserName(name);
        }
        if (role.isNotEmpty) {
          await SecureStorage.setRole(role);
        }
      }
    } catch (_) {}

    final role = await SecureStorage.getRole();
    if (!mounted) return;
    if (role == 'instructor') {
      Navigator.pushReplacementNamed(context, '/instructor');
    } else {
      Navigator.pushReplacementNamed(context, '/student');
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
      if (role == 'instructor') {
        Navigator.pushReplacementNamed(context, '/instructor');
      } else {
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
    final isLoading = ref.watch(authNotifierProvider);
    final loading = isLoading || _socialLoading;

    return AuthPageScaffold(
      title: AppStrings.t('Login'),
      subtitle: AppStrings.t('Login with your email and password.'),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
                  return AppStrings.t('The email must be a valid email address');
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: AppStrings.t('Password')),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return AppStrings.t('Password is required');
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: Text(
                  loading ? AppStrings.t('Submitting') : AppStrings.t('Login'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : _continueWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: Text(AppStrings.t('Continue with Google')),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.pushNamed(context, '/forgot-password'),
              child: Text(AppStrings.t('Forgot Password')),
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.pushNamed(context, '/register'),
              child: Text(
                '${AppStrings.t('Sign Up')} | ${AppStrings.t('Register')}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
