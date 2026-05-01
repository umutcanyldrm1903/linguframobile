import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/web_only.dart';

import '../../core/localization/app_strings.dart';

class GoogleWebSignInButton extends StatefulWidget {
  const GoogleWebSignInButton({
    required this.enabled,
    required this.onCredential,
    required this.onError,
    super.key,
  });

  final bool enabled;
  final void Function({required String idToken, String? name}) onCredential;
  final void Function(String message) onError;

  @override
  State<GoogleWebSignInButton> createState() => _GoogleWebSignInButtonState();
}

class _GoogleWebSignInButtonState extends State<GoogleWebSignInButton> {
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '284981345033-ssp855uprkfrpetnn25ni3074m0ud7f3.apps.googleusercontent.com',
  );

  StreamSubscription<GoogleSignInUserData?>? _subscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await GoogleSignInPlatform.instance.initWithParams(
        const SignInInitParameters(clientId: _googleWebClientId),
      );
      _subscription =
          GoogleSignInPlatform.instance.userDataEvents?.listen(_handleUserData);
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (error) {
      widget.onError(error.toString());
    }
  }

  void _handleUserData(GoogleSignInUserData? userData) {
    if (!widget.enabled || userData == null) return;

    final idToken = userData.idToken?.trim() ?? '';
    if (idToken.isEmpty) {
      widget.onError(
        'Google did not return an ID token. Please use the official Google button and check the Web OAuth client ID.',
      );
      return;
    }

    widget.onCredential(
      idToken: idToken,
      name: userData.displayName,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SizedBox(
        height: 52,
        child: Center(
          child: Text(
            AppStrings.t('Preparing Google sign in...'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: AbsorbPointer(
        absorbing: !widget.enabled,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FittedBox(
            fit: BoxFit.contain,
            child: renderButton(
              configuration: GSIButtonConfiguration(
                type: GSIButtonType.standard,
                theme: GSIButtonTheme.outline,
                size: GSIButtonSize.large,
                text: GSIButtonText.continueWith,
                shape: GSIButtonShape.pill,
                logoAlignment: GSIButtonLogoAlignment.left,
                minimumWidth: 360,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
