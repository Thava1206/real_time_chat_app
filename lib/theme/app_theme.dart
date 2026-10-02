import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const plum = Color(0xFF6B2D5C);
  static const gold = Color(0xFFE3B505);
  static const forest = Color(0xFF4E6E5D);
  static const ink = Color(0xFF10121C);
  static const terracotta = Color(0xFFD17A5A);
  static const online = Color(0xFF3DD68C);
}

@immutable
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  const AppSurfaceColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.mutedText,
    required this.divider,
    required this.sentBubble,
    required this.receivedBubble,
    required this.glassBorder,
    required this.isGlass,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color mutedText;
  final Color divider;
  final Color sentBubble;
  final Color receivedBubble;
  final Color glassBorder;
  final bool isGlass;

  @override
  AppSurfaceColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? mutedText,
    Color? divider,
    Color? sentBubble,
    Color? receivedBubble,
    Color? glassBorder,
    bool? isGlass,
  }) => AppSurfaceColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    mutedText: mutedText ?? this.mutedText,
    divider: divider ?? this.divider,
    sentBubble: sentBubble ?? this.sentBubble,
    receivedBubble: receivedBubble ?? this.receivedBubble,
    glassBorder: glassBorder ?? this.glassBorder,
    isGlass: isGlass ?? this.isGlass,
  );

  @override
  AppSurfaceColors lerp(covariant AppSurfaceColors? other, double t) {
    if (other == null) return this;
    return AppSurfaceColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      sentBubble: Color.lerp(sentBubble, other.sentBubble, t)!,
      receivedBubble: Color.lerp(receivedBubble, other.receivedBubble, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      isGlass: t < 0.5 ? isGlass : other.isGlass,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSurfaceColors get surfaces =>
      Theme.of(this).extension<AppSurfaceColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? _darkSurfaces
          : _lightSurfaces);
}

const _darkSurfaces = AppSurfaceColors(
  background: AppColors.ink,
  surface: Color(0xFF1B1E2A),
  surfaceHigh: Color(0xFF272B3A),
  mutedText: Color(0xFFA5A8B8),
  divider: Color(0xFF34394C),
  sentBubble: AppColors.plum,
  receivedBubble: Color(0xFF292D3C),
  glassBorder: Colors.transparent,
  isGlass: false,
);

const _lightSurfaces = AppSurfaceColors(
  background: Color(0xFFF5F2F7),
  surface: Colors.white,
  surfaceHigh: Color(0xFFECE7F0),
  mutedText: Color(0xFF666273),
  divider: Color(0xFFD8D2DC),
  sentBubble: Color(0xFF7B3A69),
  receivedBubble: Color(0xFFE8E3EC),
  glassBorder: Colors.transparent,
  isGlass: false,
);

const _glassSurfaces = AppSurfaceColors(
  background: Color(0xFF090E1D),
  surface: Color(0x662C3650),
  surfaceHigh: Color(0x804B5570),
  mutedText: Color(0xFFC3CBE0),
  divider: Color(0x4DFFFFFF),
  sentBubble: Color(0xB37D4BC5),
  receivedBubble: Color(0x704D5A78),
  glassBorder: Color(0x59FFFFFF),
  isGlass: true,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required AppSurfaceColors surfaces,
  required Color seed,
}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
      .copyWith(
        primary: isDark ? AppColors.gold : AppColors.plum,
        onPrimary: isDark ? AppColors.ink : Colors.white,
        secondary: AppColors.terracotta,
        error: AppColors.terracotta,
        surface: surfaces.surface,
        onSurface: isDark ? Colors.white : const Color(0xFF211D26),
      );
  final outline = surfaces.isGlass ? surfaces.glassBorder : scheme.outline;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: surfaces.isGlass
        ? Colors.transparent
        : surfaces.background,
    extensions: [surfaces],
    iconTheme: IconThemeData(
      color: surfaces.isGlass ? AppColors.gold : scheme.onSurface,
      shadows: surfaces.isGlass
          ? const [
              Shadow(color: Color(0xB3E3B505), blurRadius: 10),
              Shadow(color: Color(0x665C8DFF), blurRadius: 18),
            ]
          : null,
    ),
    primaryIconTheme: IconThemeData(
      color: surfaces.isGlass ? AppColors.gold : scheme.onSurface,
      shadows: surfaces.isGlass
          ? const [Shadow(color: Color(0xB3E3B505), blurRadius: 12)]
          : null,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: surfaces.isGlass ? Colors.transparent : surfaces.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: surfaces.surface,
      indicatorColor: scheme.primary.withValues(alpha: 0.24),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: surfaces.isGlass
          ? AppColors.gold.withValues(alpha: 0.82)
          : scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: surfaces.isGlass ? 2 : 6,
      shape: CircleBorder(
        side: BorderSide(
          color: surfaces.isGlass
              ? const Color(0xA6FFF2A8)
              : Colors.transparent,
          width: surfaces.isGlass ? 1.4 : 0,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: surfaces.isGlass
            ? AppColors.gold.withValues(alpha: 0.82)
            : scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: surfaces.isGlass ? 2 : null,
        shadowColor: surfaces.isGlass
            ? AppColors.gold.withValues(alpha: 0.7)
            : null,
        side: surfaces.isGlass
            ? const BorderSide(color: Color(0xA6FFF2A8), width: 1.2)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaces.surface,
      elevation: surfaces.isGlass ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: surfaces.glassBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaces.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: surfaces.glassBorder),
      ),
    ),
    dividerTheme: DividerThemeData(color: surfaces.divider, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaces.isGlass ? Colors.transparent : surfaces.surface,
      modalBackgroundColor: surfaces.isGlass
          ? Colors.transparent
          : surfaces.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(color: surfaces.surfaceHigh),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaces.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: surfaces.mutedText),
      hintStyle: TextStyle(color: surfaces.mutedText),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurface,
      textColor: scheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surfaces.surfaceHigh,
      contentTextStyle: TextStyle(color: scheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

final ThemeData lightAppTheme = _buildTheme(
  brightness: Brightness.light,
  surfaces: _lightSurfaces,
  seed: AppColors.plum,
);
final ThemeData darkAppTheme = _buildTheme(
  brightness: Brightness.dark,
  surfaces: _darkSurfaces,
  seed: AppColors.plum,
);
final ThemeData liquidGlassTheme = _buildTheme(
  brightness: Brightness.dark,
  surfaces: _glassSurfaces,
  seed: const Color(0xFF8A6CFF),
);

final ThemeData appTheme = darkAppTheme;
