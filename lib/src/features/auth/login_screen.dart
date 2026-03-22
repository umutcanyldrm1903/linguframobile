import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import 'auth_page_scaffold.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    final loading = ref.watch(authNotifierProvider);

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
