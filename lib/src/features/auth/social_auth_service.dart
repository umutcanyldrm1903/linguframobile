import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthResult {
  const SocialAuthResult({
    required this.provider,
    required this.idToken,
    this.name,
  });

  final String provider;
  final String idToken;
  final String? name;
}

class SocialAuthException implements Exception {
  const SocialAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialAuthService {
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '284981345033-ssp855uprkfrpetnn25ni3074m0ud7f3.apps.googleusercontent.com',
  );
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '284981345033-uhh8ltpjg2cldtg6iu7n1segitdho9j2.apps.googleusercontent.com',
  );
  static const _appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'com.lingufranca.app',
  );
  static const _appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://www.lingufranca.com',
  );

  Future<SocialAuthResult?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: kIsWeb
          ? null
          : (_googleWebClientId.isEmpty ? null : _googleWebClientId),
      clientId: kIsWeb
          ? (_googleWebClientId.isEmpty ? null : _googleWebClientId)
          : (_googleIosClientId.isEmpty ? null : _googleIosClientId),
    );

    await googleSignIn.signOut();
    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken?.trim() ?? '';
    if (idToken.isEmpty) {
      throw const SocialAuthException(
        'Google client id is missing or Google did not return an ID token.',
      );
    }

    return SocialAuthResult(
      provider: 'google',
      idToken: idToken,
      name: account.displayName,
    );
  }

  Future<SocialAuthResult?> signInWithApple() async {
    final isRunningAsWebApp = kIsWeb ||
        WidgetsBinding.instance.platformDispatcher.defaultRouteName
            .startsWith('http');

    if (isRunningAsWebApp &&
        Uri.base.host != 'lingufranca.com' &&
        Uri.base.host != 'www.lingufranca.com') {
      throw const SocialAuthException(
        'Apple login works on the published domain after Apple Services ID setup. Test it on lingufranca.com or use Google on localhost.',
      );
    }

    final available = await SignInWithApple.isAvailable();
    if (!available && !kIsWeb) {
      throw const SocialAuthException(
        'Apple sign in is not available on this device.',
      );
    }

    late final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: _appleServiceId,
                redirectUri: Uri.parse(_appleRedirectUri),
              )
            : null,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      throw SocialAuthException(
        'Apple ile giriş tamamlanamadı. Apple Developer hesabında Sign in with Apple capability, Bundle ID ve provisioning profile ayarlarını kontrol edin. Kod: ${error.code.name}',
      );
    } on SignInWithAppleCredentialsException {
      throw SocialAuthException(
        'Apple kimlik bilgisi alınamadı. Apple Services ID, redirect URL ve domain ayarlarını kontrol edin.',
      );
    }

    final idToken = credential.identityToken?.trim() ?? '';
    if (idToken.isEmpty) {
      throw const SocialAuthException(
          'Apple did not return an identity token.');
    }

    final given = credential.givenName?.trim() ?? '';
    final family = credential.familyName?.trim() ?? '';
    final name = [given, family].where((part) => part.isNotEmpty).join(' ');

    return SocialAuthResult(
      provider: 'apple',
      idToken: idToken,
      name: name.isNotEmpty ? name : null,
    );
  }
}
