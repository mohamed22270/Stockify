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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

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
      title: 'Stockify',
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
      home: _showSplash
          ? const StockifySplash()
          : Directionality(
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

class StockifySplash extends StatelessWidget {
  const StockifySplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061B33), Color(0xFF0B2945), Color(0xFF075B68)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF5EEAD4),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/icon/stockify_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.inventory_2_rounded,
                          size: 65,
                          color: Color(0xFF5EEAD4),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'STOCKIFY',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'SMART INVENTORY MANAGEMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Color(0xFF5EEAD4),
                ),
              ),

              const SizedBox(height: 55),

              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF5EEAD4),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Powered by Mohamed Abo alfetoah',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
