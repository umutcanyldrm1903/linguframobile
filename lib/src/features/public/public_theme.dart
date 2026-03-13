import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Keep the marketing typography on wide screens, but let compact mobile
/// screens inherit the native app theme so the app stops feeling like a webview.
class PublicTheme extends StatelessWidget {
  const PublicTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 900) {
      return child;
    }

    final base = Theme.of(context);
    final manrope = GoogleFonts.manropeTextTheme(base.textTheme);

    TextStyle? fraunces(TextStyle? style) {
      if (style == null) return null;
      return GoogleFonts.fraunces(
        textStyle: style,
        fontWeight: FontWeight.w900,
      );
    }

    final textTheme = manrope.copyWith(
      headlineLarge: fraunces(manrope.headlineLarge),
      headlineMedium: fraunces(manrope.headlineMedium),
      headlineSmall: fraunces(manrope.headlineSmall),
      titleLarge: fraunces(manrope.titleLarge),
      titleMedium: fraunces(manrope.titleMedium),
    );

    return Theme(
      data: base.copyWith(textTheme: textTheme),
      child: child,
    );
  }
}
