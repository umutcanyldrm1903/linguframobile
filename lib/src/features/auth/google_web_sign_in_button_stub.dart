import 'package:flutter/widgets.dart';

class GoogleWebSignInButton extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
