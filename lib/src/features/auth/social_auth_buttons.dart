import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import 'auth_provider.dart';
import 'google_web_sign_in_button.dart';
import 'social_auth_service.dart';

class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({
    super.key,
    required this.loading,
    required this.onAuthenticated,
  });

  final bool loading;
  final FutureOr<void> Function(String role) onAuthenticated;

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  final _service = SocialAuthService();
  String? _busyProvider;

  bool get _isBusy => widget.loading || _busyProvider != null;

  Future<void> _authenticate(
      Future<SocialAuthResult?> Function() action) async {
    try {
      final result = await action();
      if (result == null) return;
      final role = await ref.read(authNotifierProvider.notifier).socialLogin(
            provider: result.provider,
            idToken: result.idToken,
            name: result.name,
          );
      if (!mounted) return;
      await widget.onAuthenticated(role);
    } on AuthFailure catch (error) {
      _showError(error.message);
    } on SocialAuthException catch (error) {
      _showError(error.message);
    } catch (error) {
      final message = error.toString().trim();
      _showError(message.isNotEmpty ? message : 'Social login failed');
    } finally {
      if (mounted) {
        setState(() => _busyProvider = null);
      }
    }
  }

  Future<void> _authenticateGoogleWeb({
    required String idToken,
    String? name,
  }) async {
    setState(() => _busyProvider = 'google');
    try {
      final role = await ref.read(authNotifierProvider.notifier).socialLogin(
            provider: 'google',
            idToken: idToken,
            name: name,
          );
      if (!mounted) return;
      await widget.onAuthenticated(role);
    } on AuthFailure catch (error) {
      _showError(error.message);
    } catch (error) {
      final message = error.toString().trim();
      _showError(message.isNotEmpty ? message : 'Social login failed');
    } finally {
      if (mounted) {
        setState(() => _busyProvider = null);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t(message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                AppStrings.t('or continue with'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: AppStrings.t('Continue with Apple'),
          icon: Icons.apple_rounded,
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          loading: _busyProvider == 'apple',
          onPressed: _isBusy
              ? null
              : () {
                  setState(() => _busyProvider = 'apple');
                  _authenticate(_service.signInWithApple);
                },
        ),
        const SizedBox(height: 10),
        if (kIsWeb)
          GoogleWebSignInButton(
            enabled: !_isBusy,
            onCredential: ({required idToken, name}) =>
                _authenticateGoogleWeb(idToken: idToken, name: name),
            onError: _showError,
          )
        else
          _SocialButton(
            label: AppStrings.t('Continue with Google'),
            icon: Icons.g_mobiledata_rounded,
            foregroundColor: const Color(0xFF1F2937),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE2E8F0),
            loading: _busyProvider == 'google',
            onPressed: _isBusy
                ? null
                : () {
                    setState(() => _busyProvider = 'google');
                    _authenticate(_service.signInWithGoogle);
                  },
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.loading,
    required this.onPressed,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Icon(icon, color: foregroundColor, size: 24),
        label: Text(
          loading ? AppStrings.t('Submitting') : label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
