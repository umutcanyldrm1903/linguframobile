import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography + small theme tweaks to match the website's "language" frontend.
///
/// Web spec uses Manrope for body and Fraunces for display headings.
class PublicTheme extends StatelessWidget {
  const PublicTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
