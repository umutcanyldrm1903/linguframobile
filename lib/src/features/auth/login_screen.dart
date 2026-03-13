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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<String>? _deepLinkSub;
  bool _socialLoading = false;
  bool _handledAuthDeepLink = false;

  @override
  void initState() {
    super.initState();

    _deepLinkSub = PaymentNativeService.deepLinkStream.listen(_handleDeepLink);

    // Handle a potential deep-link delivered before the screen subscribed.
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
    if (uri == null) return;
    if (uri.scheme != 'lingufranca') return;
    if (uri.host != 'auth') return;

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

    // Fetch profile to ensure role is correct.
    try {
      final profile = await AuthRepository().profile();
      final name = (profile['data']?['name'])?.toString();
      if (name != null && name.trim().isNotEmpty) {
        await SecureStorage.setUserName(name.trim());
      }
      final role = (profile['data']?['role'])?.toString();
      if (role != null && role.isNotEmpty) {
        await SecureStorage.setRole(role);
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider);
    final loading = isLoading || _socialLoading;

    return AuthPageScaffold(
      title: AppStrings.t('Login'),
      subtitle: AppStrings.t('Login with your email and password.'),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: AppStrings.t('Email')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: AppStrings.t('Password')),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      await ref.read(authNotifierProvider.notifier).login(
                            _emailController.text.trim(),
                            _passwordController.text,
                          );
                      final role = await SecureStorage.getRole();
                      if (!context.mounted) return;
                      if (role == 'instructor') {
                        Navigator.pushReplacementNamed(context, '/instructor');
                      } else {
                        Navigator.pushReplacementNamed(context, '/student');
                      }
                    },
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
              '${AppStrings.t('Sign Up')} · ${AppStrings.t('Register')}',
            ),
          ),
        ],
      ),
    );
  }
}
