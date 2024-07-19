import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static MaterialScheme lightScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(4284307345),
      surfaceTint: Color(4284307345),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4293189631),
      onPrimaryContainer: Color(4279833161),
      secondary: Color(4284439665),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4293189625),
      onSecondaryContainer: Color(4279965996),
      tertiary: Color(4286272102),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4294957288),
      onTertiaryContainer: Color(4281340194),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      background: Color(4294768895),
      onBackground: Color(4280032032),
      surface: Color(4294768895),
      onSurface: Color(4280032032),
      surfaceVariant: Color(4293255660),
      onSurfaceVariant: Color(4282861135),
      outline: Color(4286084736),
      outlineVariant: Color(4291413456),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281413686),
      inverseOnSurface: Color(4294242295),
      inversePrimary: Color(4291215359),
      primaryFixed: Color(4293189631),
      onPrimaryFixed: Color(4279833161),
      primaryFixedDim: Color(4291215359),
      onPrimaryFixedVariant: Color(4282728567),
      secondaryFixed: Color(4293189625),
      onSecondaryFixed: Color(4279965996),
      secondaryFixedDim: Color(4291347420),
      onSecondaryFixedVariant: Color(4282860633),
      tertiaryFixed: Color(4294957288),
      onTertiaryFixed: Color(4281340194),
      tertiaryFixedDim: Color(4293703887),
      onTertiaryFixedVariant: Color(4284562254),
      surfaceDim: Color(4292729056),
      surfaceBright: Color(4294768895),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294374138),
      surfaceContainer: Color(4294044916),
      surfaceContainerHigh: Color(4293650159),
      surfaceContainerHighest: Color(4293255657),
    );
  }

  ThemeData light() {
    return theme(lightScheme().toColorScheme());
  }

  static MaterialScheme lightMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(4282465395),
      surfaceTint: Color(4284307345),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4285820585),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4282597461),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4285887112),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4284299082),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4287850620),
      onTertiaryContainer: Color(4294967295),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      background: Color(4294768895),
      onBackground: Color(4280032032),
      surface: Color(4294768895),
      onSurface: Color(4280032032),
      surfaceVariant: Color(4293255660),
      onSurfaceVariant: Color(4282597963),
      outline: Color(4284505703),
      outlineVariant: Color(4286347651),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281413686),
      inverseOnSurface: Color(4294242295),
      inversePrimary: Color(4291215359),
      primaryFixed: Color(4285820585),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4284175758),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4285887112),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4284242287),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4287850620),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4286074979),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292729056),
      surfaceBright: Color(4294768895),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294374138),
      surfaceContainer: Color(4294044916),
      surfaceContainerHigh: Color(4293650159),
      surfaceContainerHighest: Color(4293255657),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme lightHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff201950),
      surfaceTint: Color(0xff5d5791),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff413c73),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff222033),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff434055),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff371728),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff5d374a),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4e0002),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffffff),
      background: Color(0xfffcf8ff),
      onBackground: Color(0xff1c1b20),
      surface: Color(0xfffcf8ff),
      onSurface: Color(0xff000000),
      surfaceVariant: Color(0xffe5e1ec),
      onSurfaceVariant: Color(0xff24232b),
      outline: Color(0xff43424b),
      outlineVariant: Color(0xff43424b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313036),
      inverseOnSurface: Color(0xffffffff),
      inversePrimary: Color(0xffeee9ff),
      primaryFixed: Color(0xff413c73),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff2b255b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff434055),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff2d2a3e),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff5d374a),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff442233),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffddd8e0),
      surfaceBright: Color(0xfffcf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f2fa),
      surfaceContainer: Color(0xfff1ecf4),
      surfaceContainerHigh: Color(0xffebe6ef),
      surfaceContainerHighest: Color(0xffe5e1e9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme().toColorScheme());
  }

  static MaterialScheme darkScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc6bfff),
      surfaceTint: Color(0xffc6bfff),
      onPrimary: Color(0xff2f295f),
      primaryContainer: Color(0xff454077),
      onPrimaryContainer: Color(0xffe4dfff),
      secondary: Color(0xffc8c3dc),
      onSecondary: Color(0xff302e41),
      secondaryContainer: Color(0xff474459),
      onSecondaryContainer: Color(0xffe4dff9),
      tertiary: Color(0xffecb8cf),
      onTertiary: Color(0xff482537),
      tertiaryContainer: Color(0xff613b4e),
      onTertiaryContainer: Color(0xffffd8e8),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      background: Color(0xff141318),
      onBackground: Color(0xffe5e1e9),
      surface: Color(0xff141318),
      onSurface: Color(0xffe5e1e9),
      surfaceVariant: Color(0xff47464f),
      onSurfaceVariant: Color(0xffc9c5d0),
      outline: Color(0xff928f99),
      outlineVariant: Color(0xff47464f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e9),
      inverseOnSurface: Color(0xff313036),
      inversePrimary: Color(0xff5d5791),
      primaryFixed: Color(0xffe4dfff),
      onPrimaryFixed: Color(0xff191249),
      primaryFixedDim: Color(0xffc6bfff),
      onPrimaryFixedVariant: Color(0xff454077),
      secondaryFixed: Color(0xffe4dff9),
      onSecondaryFixed: Color(0xff1b192c),
      secondaryFixedDim: Color(0xffc8c3dc),
      onSecondaryFixedVariant: Color(0xff474459),
      tertiaryFixed: Color(0xffffd8e8),
      onTertiaryFixed: Color(0xff301122),
      tertiaryFixedDim: Color(0xffecb8cf),
      onTertiaryFixedVariant: Color(0xff613b4e),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff35343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme().toColorScheme());
  }

  static MaterialScheme darkMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcbc4ff),
      surfaceTint: Color(0xffc6bfff),
      onPrimary: Color(0xff140b44),
      primaryContainer: Color(0xff908ac7),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffccc8e1),
      onSecondary: Color(0xff161426),
      secondaryContainer: Color(0xff928ea5),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfff0bcd3),
      onTertiary: Color(0xff290b1c),
      tertiaryContainer: Color(0xffb28498),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffbab1),
      onError: Color(0xff370001),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      background: Color(0xff141318),
      onBackground: Color(0xffe5e1e9),
      surface: Color(0xff141318),
      onSurface: Color(0xfffef9ff),
      surfaceVariant: Color(0xff47464f),
      onSurfaceVariant: Color(0xffcdc9d4),
      outline: Color(0xffa5a1ac),
      outlineVariant: Color(0xff84828c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e9),
      inverseOnSurface: Color(0xff2a292f),
      inversePrimary: Color(0xff464179),
      primaryFixed: Color(0xffe4dfff),
      onPrimaryFixed: Color(0xff0e053f),
      primaryFixedDim: Color(0xffc6bfff),
      onPrimaryFixedVariant: Color(0xff342f66),
      secondaryFixed: Color(0xffe4dff9),
      onSecondaryFixed: Color(0xff110f21),
      secondaryFixedDim: Color(0xffc8c3dc),
      onSecondaryFixedVariant: Color(0xff363447),
      tertiaryFixed: Color(0xffffd8e8),
      onTertiaryFixed: Color(0xff230717),
      tertiaryFixedDim: Color(0xffecb8cf),
      onTertiaryFixedVariant: Color(0xff4e2b3d),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff35343a),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme darkHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffef9ff),
      surfaceTint: Color(0xffc6bfff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffcbc4ff),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfffef9ff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffccc8e1),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffff9f9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff0bcd3),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffbab1),
      onErrorContainer: Color(0xff000000),
      background: Color(0xff141318),
      onBackground: Color(0xffe5e1e9),
      surface: Color(0xff141318),
      onSurface: Color(0xffffffff),
      surfaceVariant: Color(0xff47464f),
      onSurfaceVariant: Color(0xfffef9ff),
      outline: Color(0xffcdc9d4),
      outlineVariant: Color(0xffcdc9d4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e1e9),
      inverseOnSurface: Color(0xff000000),
      inversePrimary: Color(0xff282259),
      primaryFixed: Color(0xffe9e3ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffcbc4ff),
      onPrimaryFixedVariant: Color(0xff140b44),
      secondaryFixed: Color(0xffe9e4fd),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffccc8e1),
      onSecondaryFixedVariant: Color(0xff161426),
      tertiaryFixed: Color(0xffffdeeb),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff0bcd3),
      onTertiaryFixedVariant: Color(0xff290b1c),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0e0e13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2a292f),
      surfaceContainerHighest: Color(0xff35343a),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme().toColorScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       fontFamily: GoogleFonts.lato().fontFamily,
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class MaterialScheme {
  const MaterialScheme({
    required this.brightness,
    required this.primary, 
    required this.surfaceTint, 
    required this.onPrimary, 
    required this.primaryContainer, 
    required this.onPrimaryContainer, 
    required this.secondary, 
    required this.onSecondary, 
    required this.secondaryContainer, 
    required this.onSecondaryContainer, 
    required this.tertiary, 
    required this.onTertiary, 
    required this.tertiaryContainer, 
    required this.onTertiaryContainer, 
    required this.error, 
    required this.onError, 
    required this.errorContainer, 
    required this.onErrorContainer, 
    required this.background, 
    required this.onBackground, 
    required this.surface, 
    required this.onSurface, 
    required this.surfaceVariant, 
    required this.onSurfaceVariant, 
    required this.outline, 
    required this.outlineVariant, 
    required this.shadow, 
    required this.scrim, 
    required this.inverseSurface, 
    required this.inverseOnSurface, 
    required this.inversePrimary, 
    required this.primaryFixed, 
    required this.onPrimaryFixed, 
    required this.primaryFixedDim, 
    required this.onPrimaryFixedVariant, 
    required this.secondaryFixed, 
    required this.onSecondaryFixed, 
    required this.secondaryFixedDim, 
    required this.onSecondaryFixedVariant, 
    required this.tertiaryFixed, 
    required this.onTertiaryFixed, 
    required this.tertiaryFixedDim, 
    required this.onTertiaryFixedVariant, 
    required this.surfaceDim, 
    required this.surfaceBright, 
    required this.surfaceContainerLowest, 
    required this.surfaceContainerLow, 
    required this.surfaceContainer, 
    required this.surfaceContainerHigh, 
    required this.surfaceContainerHighest, 
  });

  final Brightness brightness;
  final Color primary;
  final Color surfaceTint;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixedVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
}

extension MaterialSchemeUtils on MaterialScheme {
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
  }
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
