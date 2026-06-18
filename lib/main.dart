import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'views/main_screen.dart';

// Global theme notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi DatabaseService
  final databaseService = DatabaseService.instance;
  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;
  const MyApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    // Custom modern color scheme
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E), // Premium Teal
      brightness: Brightness.light,
      primary: const Color(0xFF0F766E),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6F4F2),
      onPrimaryContainer: const Color(0xFF115E59),
      secondary: const Color(0xFF4F46E5), // Indigo Accent
      secondaryContainer: const Color(0xFFEEF2FF),
      onSecondaryContainer: const Color(0xFF3730A3),
      surface: const Color(0xFFF8FAFC), // Slate 50
      onSurface: const Color(0xFF0F172A), // Slate 900
      onSurfaceVariant: const Color(0xFF475569), // Slate 600
      outline: const Color(0xFFE2E8F0), // Slate 200
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF14B8A6), // Emerald Teal
      brightness: Brightness.dark,
      primary: const Color(0xFF2DD4BF), // Teal 400
      onPrimary: const Color(0xFF0F172A),
      primaryContainer: const Color(0xFF115E59), // Teal 800
      onPrimaryContainer: const Color(0xFFCCFBF1),
      secondary: const Color(0xFF818CF8), // Indigo 400
      secondaryContainer: const Color(0xFF312E81),
      onSecondaryContainer: const Color(0xFFE0E7FF),
      surface: const Color(0xFF0F172A), // Slate 900
      onSurface: const Color(0xFFF8FAFC), // Slate 50
      onSurfaceVariant: const Color(0xFF94A3B8), // Slate 400
      outline: const Color(0xFF334155), // Slate 700
    );

    final textTheme = const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0),
      bodyLarge: TextStyle(letterSpacing: 0.1),
      bodyMedium: TextStyle(letterSpacing: 0.1),
      labelLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
    );

    final baseLight = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: lightColorScheme.onSurface,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightColorScheme.outline.withAlpha(150), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.error),
        ),
        labelStyle: TextStyle(color: lightColorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: lightColorScheme.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withAlpha(20),
        indicatorColor: lightColorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: lightColorScheme.primary);
          }
          return IconThemeData(color: lightColorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5);
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: lightColorScheme.primary);
          }
          return style.copyWith(color: lightColorScheme.onSurfaceVariant);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: lightColorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: lightColorScheme.primary,
        unselectedLabelColor: lightColorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );

    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: darkColorScheme.onSurface,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: darkColorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: darkColorScheme.outline.withAlpha(100), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.error),
        ),
        labelStyle: TextStyle(color: darkColorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: darkColorScheme.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        elevation: 0,
        indicatorColor: darkColorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: darkColorScheme.primary);
          }
          return IconThemeData(color: darkColorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5);
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: darkColorScheme.primary);
          }
          return style.copyWith(color: darkColorScheme.onSurfaceVariant);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: darkColorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: darkColorScheme.primary,
        unselectedLabelColor: darkColorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          title: 'CommitHike',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: baseLight,
          darkTheme: baseDark,
          home: MainScreen(databaseService: databaseService),
        );
      },
    );
  }
}
