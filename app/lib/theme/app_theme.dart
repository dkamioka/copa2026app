import 'package:flutter/cupertino.dart';

/// Central design tokens for the light, high-contrast "liquid glass"
/// look the user landed on after iterating in Claude Design.
abstract final class AppColors {
  static const ink = Color(0xFF16162E);
  static const inkFaint = Color(0x8016162E); // ink @ 50%
  static const inkFainter = Color(0x6616162E); // ink @ 40%
  static const inkHint = Color(0x4D16162E); // ink @ 30%

  static const accent = Color(0xFFE11D6B);
  static const win = Color(0xFF16A34A);
  static const draw = Color(0xFFD97706);
  static const loss = Color(0xFFDC2626);

  static const qualifiedBg = Color(0x1F22C55E);
  static const qualifiedText = Color(0xFF16A34A);

  // "Claro" background palette: soft gradient base + four blurred
  // accent blobs that slowly drift behind the content.
  static const bgBase = [Color(0xFFEEF1F7), Color(0xFFDCE1EE)];
  static const blob1 = Color(0xFFC7D2FE);
  static const blob2 = Color(0xFFBBF7D0);
  static const blob3 = Color(0xFFFDE2C4);
  static const blob4 = Color(0xFFBFDBFE);
}

abstract final class AppRadii {
  static const card = 14.0;
  static const cardLarge = 18.0;
  static const pill = 999.0;
  static const sheet = 32.0;
}

abstract final class AppTextStyles {
  static const _family = '.SF Pro Text';
  static const _familyDisplay = '.SF Pro Display';

  static const eyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.3,
    color: AppColors.inkFainter,
  );

  static const title = TextStyle(
    fontFamily: _familyDisplay,
    fontSize: 23,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  static const sectionHeader = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    color: AppColors.ink,
  );

  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 10.5,
    color: AppColors.inkFainter,
    fontWeight: FontWeight.w500,
  );
}
