import 'package:flutter/widgets.dart';

enum SweepThemeMode { halo, nocturne }

class SweepColorTokens {
  const SweepColorTokens({
    required this.background,
    required this.backgroundRaised,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dock,
    required this.scrim,
    required this.shadow,
    required this.heroStart,
    required this.heroEnd,
    required this.orbOne,
    required this.orbTwo,
    required this.orbThree,
  });

  final Color background;
  final Color backgroundRaised;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color info;
  final Color success;
  final Color warning;
  final Color danger;
  final Color dock;
  final Color scrim;
  final Color shadow;
  final Color heroStart;
  final Color heroEnd;
  final Color orbOne;
  final Color orbTwo;
  final Color orbThree;
}

class SweepTypographyTokens {
  const SweepTypographyTokens({
    required this.displayFamily,
    required this.bodyFamily,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
  });

  final String displayFamily;
  final String bodyFamily;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;

  TextStyle get hero => TextStyle(
    fontFamily: displayFamily,
    fontSize: 38,
    height: 1.02,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.4,
    color: textPrimary,
  );

  TextStyle get display => TextStyle(
    fontFamily: displayFamily,
    fontSize: 30,
    height: 1.06,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
    color: textPrimary,
  );

  TextStyle get headline => TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    height: 1.08,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    color: textPrimary,
  );

  TextStyle get title => TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    height: 1.14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
  );

  TextStyle get body => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  TextStyle get bodyStrong => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.42,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  TextStyle get label => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.28,
    color: textPrimary,
  );

  TextStyle get detail => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  TextStyle get caption => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: textTertiary,
  );

  TextStyle get button => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    color: textOnAccent,
  );
}

class SweepSpacingTokens {
  const SweepSpacingTokens();

  double get xxs => 4;
  double get xs => 8;
  double get sm => 12;
  double get md => 16;
  double get lg => 20;
  double get xl => 24;
  double get xxl => 32;
  double get gutter => 20;
  double get dockInset => 18;
}

class SweepRadiusTokens {
  const SweepRadiusTokens();

  double get sm => 14;
  double get md => 20;
  double get lg => 28;
  double get xl => 36;
  double get pill => 999;
}

class SweepElevationTokens {
  const SweepElevationTokens({required this.shadow});

  final Color shadow;

  List<BoxShadow> panel([double scale = 1]) {
    return <BoxShadow>[
      BoxShadow(
        color: shadow.withValues(alpha: 0.18 * scale),
        blurRadius: 36 * scale,
        offset: Offset(0, 18 * scale),
      ),
      BoxShadow(
        color: shadow.withValues(alpha: 0.08 * scale),
        blurRadius: 12 * scale,
        offset: Offset(0, 6 * scale),
      ),
    ];
  }

  List<BoxShadow> glow(Color color, [double scale = 1]) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: 0.30 * scale),
        blurRadius: 32 * scale,
        spreadRadius: 0,
      ),
    ];
  }
}

class SweepMotionTokens {
  const SweepMotionTokens({required this.reduceMotion});

  final bool reduceMotion;

  Duration get micro => reduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 120);

  Duration get component => reduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 180);

  Duration get screen => reduceMotion
      ? Duration.zero
      : const Duration(milliseconds: 320);

  Curve get standard => reduceMotion ? Curves.linear : Curves.easeOutCubic;
  Curve get emphasized => reduceMotion ? Curves.linear : Curves.easeOutQuart;
}

class SweepThemeData {
  const SweepThemeData({
    required this.mode,
    required this.brightness,
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.elevation,
    required this.motion,
    required this.blurSigma,
  });

  factory SweepThemeData.resolve({
    required SweepThemeMode mode,
    required bool reduceMotion,
  }) {
    final bool isDark = mode == SweepThemeMode.nocturne;
    final SweepColorTokens colors = isDark
        ? const SweepColorTokens(
            background: Color(0xFF05070C),
            backgroundRaised: Color(0xFF0C1220),
            surface: Color(0xCC11192B),
            surfaceRaised: Color(0xE5192236),
            surfaceMuted: Color(0x99162133),
            border: Color(0x3DE8F1FF),
            borderStrong: Color(0x75E8F1FF),
            textPrimary: Color(0xFFF8FBFF),
            textSecondary: Color(0xCCBECAE0),
            textTertiary: Color(0x88BECAE0),
            textOnAccent: Color(0xFF041117),
            primary: Color(0xFF7CF6D4),
            primarySoft: Color(0x2928B8C7),
            secondary: Color(0xFFFFB85C),
            info: Color(0xFF7EAEFF),
            success: Color(0xFF6CFF9C),
            warning: Color(0xFFFFCB62),
            danger: Color(0xFFFF7B7B),
            dock: Color(0xC9192237),
            scrim: Color(0xB3070B12),
            shadow: Color(0xFF000000),
            heroStart: Color(0xFF7CF6D4),
            heroEnd: Color(0xFF6F7DF6),
            orbOne: Color(0xFF123A62),
            orbTwo: Color(0xFF0D6B59),
            orbThree: Color(0xFF6C3A84),
          )
        : const SweepColorTokens(
            background: Color(0xFFF4F8FF),
            backgroundRaised: Color(0xFFE9F2FF),
            surface: Color(0xD9FFFFFF),
            surfaceRaised: Color(0xF7FFFFFF),
            surfaceMuted: Color(0xCCEEF3FB),
            border: Color(0x2B20314E),
            borderStrong: Color(0x5C20314E),
            textPrimary: Color(0xFF0E1726),
            textSecondary: Color(0xBF334867),
            textTertiary: Color(0x85334867),
            textOnAccent: Color(0xFF05131B),
            primary: Color(0xFF1BC4A6),
            primarySoft: Color(0x1A1BC4A6),
            secondary: Color(0xFFFF9F43),
            info: Color(0xFF4975E9),
            success: Color(0xFF34B368),
            warning: Color(0xFFD08B1D),
            danger: Color(0xFFE45465),
            dock: Color(0xE8FFFFFF),
            scrim: Color(0x80111925),
            shadow: Color(0xFF0C1B31),
            heroStart: Color(0xFF1BC4A6),
            heroEnd: Color(0xFF557AFF),
            orbOne: Color(0xFFCFE6FF),
            orbTwo: Color(0xFFCFF7E6),
            orbThree: Color(0xFFFFE8CF),
          );

    return SweepThemeData(
      mode: mode,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colors: colors,
      typography: SweepTypographyTokens(
        displayFamily: 'SpaceGrotesk',
        bodyFamily: 'Manrope',
        textPrimary: colors.textPrimary,
        textSecondary: colors.textSecondary,
        textTertiary: colors.textTertiary,
        textOnAccent: colors.textOnAccent,
      ),
      spacing: const SweepSpacingTokens(),
      radii: const SweepRadiusTokens(),
      elevation: SweepElevationTokens(shadow: colors.shadow),
      motion: SweepMotionTokens(reduceMotion: reduceMotion),
      blurSigma: isDark ? 20 : 18,
    );
  }

  final SweepThemeMode mode;
  final Brightness brightness;
  final SweepColorTokens colors;
  final SweepTypographyTokens typography;
  final SweepSpacingTokens spacing;
  final SweepRadiusTokens radii;
  final SweepElevationTokens elevation;
  final SweepMotionTokens motion;
  final double blurSigma;

  LinearGradient get appGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      colors.background,
      colors.backgroundRaised,
      Color.lerp(colors.backgroundRaised, colors.heroEnd, 0.10)!,
    ],
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      colors.heroStart,
      Color.lerp(colors.heroStart, colors.heroEnd, 0.6)!,
      colors.heroEnd,
    ],
  );
}

class SweepThemeScope extends InheritedWidget {
  const SweepThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  final SweepThemeData theme;

  static SweepThemeData of(BuildContext context) {
    final SweepThemeScope? scope = context
        .dependOnInheritedWidgetOfExactType<SweepThemeScope>();
    assert(scope != null, 'SweepThemeScope not found in context.');
    return scope!.theme;
  }

  @override
  bool updateShouldNotify(covariant SweepThemeScope oldWidget) {
    return oldWidget.theme.mode != theme.mode ||
        oldWidget.theme.motion.reduceMotion != theme.motion.reduceMotion;
  }
}

class SweepThemeHost extends StatelessWidget {
  const SweepThemeHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final SweepThemeMode mode =
        mediaQuery.platformBrightness == Brightness.dark
        ? SweepThemeMode.nocturne
        : SweepThemeMode.halo;
    final SweepThemeData theme = SweepThemeData.resolve(
      mode: mode,
      reduceMotion: mediaQuery.disableAnimations,
    );

    return SweepThemeScope(
      theme: theme,
      child: IconTheme(
        data: IconThemeData(color: theme.colors.textPrimary, size: 20),
        child: DefaultTextStyle(
          style: theme.typography.body,
          child: child,
        ),
      ),
    );
  }
}

abstract final class SweepTheme {
  static SweepThemeData of(BuildContext context) => SweepThemeScope.of(context);
}
