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
      primary: Color(4280293712),
      surfaceTint: Color(4284307345),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4282465395),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4280426547),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4282597461),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4281800488),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4284299082),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      background: Color(4294768895),
      onBackground: Color(4280032032),
      surface: Color(4294768895),
      onSurface: Color(4278190080),
      surfaceVariant: Color(4293255660),
      onSurfaceVariant: Color(4280558379),
      outline: Color(4282597963),
      outlineVariant: Color(4282597963),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281413686),
      inverseOnSurface: Color(4294967295),
      inversePrimary: Color(4293847551),
      primaryFixed: Color(4282465395),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4281017691),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4282597461),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4281150014),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4284299082),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4282655283),
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

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme().toColorScheme());
  }

  static MaterialScheme darkScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(4291215359),
      surfaceTint: Color(4291215359),
      onPrimary: Color(4281280863),
      primaryContainer: Color(4282728567),
      onPrimaryContainer: Color(4293189631),
      secondary: Color(4291347420),
      onSecondary: Color(4281347649),
      secondaryContainer: Color(4282860633),
      onSecondaryContainer: Color(4293189625),
      tertiary: Color(4293703887),
      onTertiary: Color(4282918199),
      tertiaryContainer: Color(4284562254),
      onTertiaryContainer: Color(4294957288),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      background: Color(4279505688),
      onBackground: Color(4293255657),
      surface: Color(4279505688),
      onSurface: Color(4293255657),
      surfaceVariant: Color(4282861135),
      onSurfaceVariant: Color(4291413456),
      outline: Color(4287795097),
      outlineVariant: Color(4282861135),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293255657),
      inverseOnSurface: Color(4281413686),
      inversePrimary: Color(4284307345),
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
      surfaceDim: Color(4279505688),
      surfaceBright: Color(4282005566),
      surfaceContainerLowest: Color(4279111187),
      surfaceContainerLow: Color(4280032032),
      surfaceContainer: Color(4280295205),
      surfaceContainerHigh: Color(4280953135),
      surfaceContainerHighest: Color(4281676858),
    );
  }

  ThemeData dark() {
    return theme(darkScheme().toColorScheme());
  }

  static MaterialScheme darkMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(4291544319),
      surfaceTint: Color(4291215359),
      onPrimary: Color(4279503684),
      primaryContainer: Color(4287662791),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4291610849),
      onSecondary: Color(4279637030),
      secondaryContainer: Color(4287794853),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4293967059),
      onTertiary: Color(4280879900),
      tertiaryContainer: Color(4289889432),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      background: Color(4279505688),
      onBackground: Color(4293255657),
      surface: Color(4279505688),
      onSurface: Color(4294900223),
      surfaceVariant: Color(4282861135),
      onSurfaceVariant: Color(4291676628),
      outline: Color(4289044908),
      outlineVariant: Color(4286874252),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293255657),
      inverseOnSurface: Color(4280953135),
      inversePrimary: Color(4282794361),
      primaryFixed: Color(4293189631),
      onPrimaryFixed: Color(4279108927),
      primaryFixedDim: Color(4291215359),
      onPrimaryFixedVariant: Color(4281610086),
      secondaryFixed: Color(4293189625),
      onSecondaryFixed: Color(4279308065),
      secondaryFixedDim: Color(4291347420),
      onSecondaryFixedVariant: Color(4281742407),
      tertiaryFixed: Color(4294957288),
      onTertiaryFixed: Color(4280485655),
      tertiaryFixedDim: Color(4293703887),
      onTertiaryFixedVariant: Color(4283312957),
      surfaceDim: Color(4279505688),
      surfaceBright: Color(4282005566),
      surfaceContainerLowest: Color(4279111187),
      surfaceContainerLow: Color(4280032032),
      surfaceContainer: Color(4280295205),
      surfaceContainerHigh: Color(4280953135),
      surfaceContainerHighest: Color(4281676858),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme darkHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(4294900223),
      surfaceTint: Color(4291215359),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4291544319),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4294900223),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4291610849),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294965753),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4293967059),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      background: Color(4279505688),
      onBackground: Color(4293255657),
      surface: Color(4279505688),
      onSurface: Color(4294967295),
      surfaceVariant: Color(4282861135),
      onSurfaceVariant: Color(4294900223),
      outline: Color(4291676628),
      outlineVariant: Color(4291676628),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293255657),
      inverseOnSurface: Color(4278190080),
      inversePrimary: Color(4280820313),
      primaryFixed: Color(4293518335),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4291544319),
      onPrimaryFixedVariant: Color(4279503684),
      secondaryFixed: Color(4293518589),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4291610849),
      onSecondaryFixedVariant: Color(4279637030),
      tertiaryFixed: Color(4294958827),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4293967059),
      onTertiaryFixedVariant: Color(4280879900),
      surfaceDim: Color(4279505688),
      surfaceBright: Color(4282005566),
      surfaceContainerLowest: Color(4279111187),
      surfaceContainerLow: Color(4280032032),
      surfaceContainer: Color(4280295205),
      surfaceContainerHigh: Color(4280953135),
      surfaceContainerHighest: Color(4281676858),
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
