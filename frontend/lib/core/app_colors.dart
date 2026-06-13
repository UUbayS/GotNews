import 'package:flutter/material.dart';

/// Brand & semantic colors for GotNews.
///
/// Mengubah nilai di sini akan otomatis mengubah tampilan di seluruh app.
/// Semua file layar **sebaiknya** memakai konstanta dari class ini,
/// bukan hardcoded `Color(0xFFxxxxxx)` atau `Colors.x.shadeNNN`.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF2E65F3);
  static const Color primaryDark = Color(0xFF1E4FCF);

  // ---------------------------------------------------------------------------
  // Semantic (untuk status, alert, dan feedback)
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF8B5CF6);

  /// Success — biasanya untuk snackbar hijau.
  static Color get successDark => const Color(0xFF10B981).withValues(alpha: 0.85);

  /// Danger — biasanya untuk snackbar merah.
  static Color get dangerDark => const Color(0xFFEF4444).withValues(alpha: 0.85);

  /// Warning — biasanya untuk snackbar oranye.
  static Color get warningDark => const Color(0xFFF59E0B).withValues(alpha: 0.85);

  // ---------------------------------------------------------------------------
  // Surfaces (background, card, divider)
  // ---------------------------------------------------------------------------
  static const Color lightBg = Colors.white;
  static const Color darkBg = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  // ---------------------------------------------------------------------------
  // Overlay text (untuk teks di atas gambar feed / hero image)
  // ---------------------------------------------------------------------------
  static const Color overlayText = Colors.white;
  static const Color overlayTextMuted = Colors.white70;
  static const Color overlayTextFaint = Colors.white54;
  static const Color overlayIconFaint = Colors.white24;

  /// Warna untuk elemen "Tertandai sudah dibaca" (badge hijau di feed).
  static const Color readBadge = Colors.green;

  // ---------------------------------------------------------------------------
  // Shimmer (skeleton loading) base colors
  // ---------------------------------------------------------------------------
  static const Color shimmerDarkBase = Color(0xFF1E1E1E);
  static const Color shimmerDarkHighlight = Color(0xFF2A2A2A);
  static const Color shimmerLightBase = Color(0xFFE0E0E0);
  static const Color shimmerLightHighlight = Color(0xFFF5F5F5);

  // ---------------------------------------------------------------------------
  // Hint / muted text (untuk placeholder, caption, divider subtle)
  // ---------------------------------------------------------------------------
  static const Color hint = Colors.grey;
}
