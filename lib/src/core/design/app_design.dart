import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lingufranca Premium tasarım sistemi — token katmanı.
///
/// Tüm yeni (pratik-dışı) ekranlar bu token'ları kullanır: tutarlı boşluk,
/// yarıçap, gölge, gradyan ve semantik renkler. Mevcut [AppColors] korunur;
/// bu dosya onu tamamlar.

/// Boşluk skalası (8'lik ritim).
class AppSpace {
  const AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
}

/// Köşe yarıçapı skalası.
class AppRadius {
  const AppRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double round = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius hero = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(round));
}

/// Semantik / oyunlaştırma renkleri (markayı tamamlar).
class AppPalette {
  const AppPalette._();
  static const Color success = Color(0xFF22C55E);
  static const Color successDeep = Color(0xFF15803D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Oyunlaştırma vurguları
  static const Color gold = Color(0xFFFFC83D);
  static const Color goldDeep = Color(0xFFE89B0C);
  static const Color streak = Color(0xFFFF8A3D); // alev turuncusu
  static const Color heart = Color(0xFFFF4D6D);
  static const Color xp = Color(0xFFFFB020);
  static const Color violet = Color(0xFF7C5CFF);
  static const Color teal = Color(0xFF02C39A);

  // Yumuşak zeminler
  static const Color cloud = Color(0xFFF6F9FF);
  static const Color line = Color(0xFFE6ECF8);
}

/// Gradyan token'ları.
class AppGradients {
  const AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, AppColors.brandDeep],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandDeep, AppColors.brand, Color(0xFF5B73FF)],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient night = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.brandNight, AppColors.brandDeep],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), AppPalette.successDeep],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD86B), AppPalette.goldDeep],
  );

  static const LinearGradient streak = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB36B), Color(0xFFFF6A3D)],
  );

  static const LinearGradient violet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9F8BFF), Color(0xFF6C4DFF)],
  );

  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF1FF), Color(0xFFF6F9FF)],
  );

  /// İki renkten hızlı gradyan.
  static LinearGradient pair(Color a, Color b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      );
}

/// Gölge / yükseklik katmanları.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get pop => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ];

  /// Renkli "glow" gölge (gradyan butonlar/kartlar için).
  static List<BoxShadow> glow(Color color, {double opacity = 0.40}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Tipografi yardımcıları (mevcut tema TextTheme'i tamamlar).
class AppText {
  const AppText._();
  static const double overline = 11;
  static const double caption = 12.5;
}
