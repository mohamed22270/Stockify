import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/stockflow_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StockFlowApp()));
}

class StockFlowApp extends StatefulWidget {
  const StockFlowApp({super.key});

  @override
  State<StockFlowApp> createState() => _StockFlowAppState();
}

class _StockFlowAppState extends State<StockFlowApp> {
  bool _darkMode = false;
  bool _arabic = false;

  @override
  Widget build(BuildContext context) {
    final colors =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: _darkMode ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: _darkMode
              ? const Color(0xFF5EEAD4)
              : const Color(0xFF0F766E),
          secondary: const Color(0xFF38BDF8),
          surface: _darkMode ? const Color(0xFF111C2E) : Colors.white,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StockFlow',
      theme: ThemeData(
        colorScheme: colors,
        useMaterial3: true,
        scaffoldBackgroundColor: _darkMode
            ? const Color(0xFF07111F)
            : const Color(0xFFF3F6F8),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          backgroundColor: _darkMode
              ? const Color(0xFF07111F)
              : const Color(0xFFF3F6F8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          height: 72,
          backgroundColor: _darkMode ? const Color(0xFF111C2E) : Colors.white,
          indicatorColor: colors.primaryContainer,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: _darkMode ? const Color(0xFF111C2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: .55),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: StockFlowShell(
          arabic: _arabic,
          darkMode: _darkMode,
          onLanguageChanged: () => setState(() => _arabic = !_arabic),
          onThemeChanged: () => setState(() => _darkMode = !_darkMode),
        ),
      ),
    );
  }
}
