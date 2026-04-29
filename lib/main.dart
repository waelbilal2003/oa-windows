/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // إعدادات النافذة لنظام Windows
  await windowManager.ensureInitialized();
  await windowManager
      .setTitleBarStyle(TitleBarStyle.hidden); // إخفاء شريط العنوان والأزرار
  await windowManager.setFullScreen(true); // ملء الشاشة بالكامل
  await windowManager.setResizable(false); // منع تغيير الحجم
  await windowManager.setMinimizable(false); // منع التصغير
  await windowManager.setMaximizable(false); // منع التكبير

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _fontScalePercent = 0.5;
  double _iconScalePercent = 0.5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScalePercent = prefs.getDouble('font_scale_percent') ?? 0.5;
      _iconScalePercent = prefs.getDouble('icon_scale_percent') ?? 0.5;
      _isLoading = false;
    });
  }

  double get _fontScale => 1.0 + _fontScalePercent;
  double get _iconScale => 1.0 + _iconScalePercent;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Al Hal Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 28 * _fontScale),
          displayMedium: TextStyle(fontSize: 24 * _fontScale),
          displaySmall: TextStyle(fontSize: 20 * _fontScale),
          headlineLarge: TextStyle(fontSize: 24 * _fontScale),
          headlineMedium: TextStyle(fontSize: 20 * _fontScale),
          headlineSmall: TextStyle(fontSize: 16 * _fontScale),
          titleLarge: TextStyle(fontSize: 18 * _fontScale),
          titleMedium: TextStyle(fontSize: 16 * _fontScale),
          titleSmall: TextStyle(fontSize: 14 * _fontScale),
          bodyLarge: TextStyle(fontSize: 14 * _fontScale),
          bodyMedium: TextStyle(fontSize: 12 * _fontScale),
          bodySmall: TextStyle(fontSize: 10 * _fontScale),
          labelLarge: TextStyle(fontSize: 14 * _fontScale),
          labelMedium: TextStyle(fontSize: 12 * _fontScale),
          labelSmall: TextStyle(fontSize: 10 * _fontScale),
        ),
        iconTheme: IconThemeData(size: 24 * _iconScale),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(iconSize: 24 * _iconScale),
        ),
        appBarTheme: AppBarTheme(
          toolbarHeight: 112.0,
          titleTextStyle: TextStyle(
            fontSize: 18 * _fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            size: 24 * _iconScale,
            color: Colors.white,
          ),
          toolbarTextStyle: TextStyle(
            fontSize: 14 * _fontScale,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(fontSize: 14 * _fontScale),
          hintStyle: TextStyle(fontSize: 12 * _fontScale),
          errorStyle: TextStyle(fontSize: 10 * _fontScale),
        ),
        listTileTheme: ListTileThemeData(
          titleTextStyle: TextStyle(fontSize: 14 * _fontScale),
          subtitleTextStyle: TextStyle(fontSize: 12 * _fontScale),
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontSize: 12 * _fontScale),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_fontScale),
          ),
          child: child!,
        );
      },
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/login_screen.dart';
import 'security/activation_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/escape_handler.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // إعدادات النافذة
  await windowManager.ensureInitialized();
  await windowManager
      .setTitleBarStyle(TitleBarStyle.hidden); // إخفاء شريط العنوان والأزرار
  await windowManager.setFullScreen(true); // ملء الشاشة بالكامل
  await windowManager.setResizable(false); // منع تغيير الحجم
  await windowManager.setMinimizable(false); // منع التصغير
  await windowManager.setMaximizable(false); // منع التكبير

  final prefs = await SharedPreferences.getInstance();
  final String activationStatus = prefs.getString('activation_status') ?? '';

  bool isActivated = false;
  if (activationStatus.isNotEmpty) {
    try {
      final decodedStatus = utf8.decode(base64.decode(activationStatus));
      if (decodedStatus == 'activated_ok') {
        isActivated = true;
      }
    } catch (e) {
      isActivated = false;
    }
  }

  runApp(MyApp(isActivated: isActivated));
}

class MyApp extends StatefulWidget {
  final bool isActivated;

  const MyApp({super.key, required this.isActivated});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _fontScalePercent = 0.5;
  double _iconScalePercent = 0.5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScalePercent = prefs.getDouble('font_scale_percent') ?? 0.5;
      _iconScalePercent = prefs.getDouble('icon_scale_percent') ?? 0.5;
      _isLoading = false;
    });
  }

  double get _fontScale => 1.0 + _fontScalePercent;
  double get _iconScale => 1.0 + _iconScalePercent;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Al Hal Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 28 * _fontScale),
          displayMedium: TextStyle(fontSize: 24 * _fontScale),
          displaySmall: TextStyle(fontSize: 20 * _fontScale),
          headlineLarge: TextStyle(fontSize: 24 * _fontScale),
          headlineMedium: TextStyle(fontSize: 20 * _fontScale),
          headlineSmall: TextStyle(fontSize: 16 * _fontScale),
          titleLarge: TextStyle(fontSize: 18 * _fontScale),
          titleMedium: TextStyle(fontSize: 16 * _fontScale),
          titleSmall: TextStyle(fontSize: 14 * _fontScale),
          bodyLarge: TextStyle(fontSize: 14 * _fontScale),
          bodyMedium: TextStyle(fontSize: 12 * _fontScale),
          bodySmall: TextStyle(fontSize: 10 * _fontScale),
          labelLarge: TextStyle(fontSize: 14 * _fontScale),
          labelMedium: TextStyle(fontSize: 12 * _fontScale),
          labelSmall: TextStyle(fontSize: 10 * _fontScale),
        ),
        iconTheme: IconThemeData(size: 24 * _iconScale),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(iconSize: 24 * _iconScale),
        ),
        appBarTheme: AppBarTheme(
          toolbarHeight: 112.0,
          titleTextStyle: TextStyle(
            fontSize: 18 * _fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            size: 24 * _iconScale,
            color: Colors.white,
          ),
          toolbarTextStyle: TextStyle(
            fontSize: 14 * _fontScale,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(fontSize: 14 * _fontScale),
          hintStyle: TextStyle(fontSize: 12 * _fontScale),
          errorStyle: TextStyle(fontSize: 10 * _fontScale),
        ),
        listTileTheme: ListTileThemeData(
          titleTextStyle: TextStyle(fontSize: 14 * _fontScale),
          subtitleTextStyle: TextStyle(fontSize: 12 * _fontScale),
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontSize: 12 * _fontScale),
        ),
      ),
      home: widget.isActivated ? const LoginScreen() : const ActivationScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_fontScale),
          ),
          child: EscapeHandler(child: child!),
        );
      },
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';

// مدة النسخة التجريبية بالأيام
const int TRIAL_DURATION_DAYS = 7;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // إعدادات النافذة لنظام Windows
  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setFullScreen(true);
  await windowManager.setResizable(false);
  await windowManager.setMinimizable(false);
  await windowManager.setMaximizable(false);

  // التحقق من صلاحية النسخة التجريبية
  final prefs = await SharedPreferences.getInstance();

  final String? firstLaunchDate = prefs.getString('trial_first_launch_date');
  final DateTime now = DateTime.now();

  bool isTrialValid = true;
  int remainingDays = TRIAL_DURATION_DAYS;

  if (firstLaunchDate == null) {
    // أول تشغيل للتطبيق - حفظ تاريخ اليوم
    await prefs.setString(
        'trial_first_launch_date', now.toIso8601String().split('T')[0]);
    print('تم بدء النسخة التجريبية لمدة $TRIAL_DURATION_DAYS أيام');
    print('تاريخ البدء: ${now.year}/${now.month}/${now.day}');
    remainingDays = TRIAL_DURATION_DAYS;
  } else {
    // حساب الأيام المتبقية
    final DateTime firstLaunch = DateTime.parse(firstLaunchDate);
    final int daysPassed = now.difference(firstLaunch).inDays;

    print(
        'تاريخ أول تشغيل: ${firstLaunch.year}/${firstLaunch.month}/${firstLaunch.day}');
    print('الأيام المنقضية: $daysPassed');

    if (daysPassed >= TRIAL_DURATION_DAYS) {
      isTrialValid = false;
      remainingDays = 0;
      print('⚠️ انتهت صلاحية النسخة التجريبية!');
    } else {
      remainingDays = TRIAL_DURATION_DAYS - daysPassed;
      print('✅ متبقي: $remainingDays أيام');
    }
  }

  if (!isTrialValid) {
    runApp(const TrialExpiredApp());
  } else {
    runApp(MyApp(remainingTime: remainingDays));
  }
}

// تطبيق انتهاء الصلاحية
class TrialExpiredApp extends StatelessWidget {
  const TrialExpiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF2D2D2D),
                Color(0xFF1A1A1A),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة التحذير
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gpp_bad,
                  color: Colors.red,
                  size: 80,
                ),
              ),

              const SizedBox(height: 40),

              // عنوان انتهاء الصلاحية
              const Text(
                'انتهت صلاحية النسخة التجريبية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // رسالة المدة
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'انتهت فترة التجربة البالغة 7 أيام',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // معلومات الاتصال
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.teal, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'للحصول على النسخة الكاملة يرجى التواصل مع:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // معلومات المبرمج
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.code, color: Colors.teal, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'مبرمج:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'وائل بلال',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, color: Colors.teal, size: 18),
                              SizedBox(width: 5),
                              Text(
                                '+963935702074',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // معلومات المحاسب
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'محاسب:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'عدنان الحجي',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, color: Colors.orange, size: 18),
                              SizedBox(width: 5),
                              Text(
                                '+963944367326',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // زر إغلاق التطبيق
              ElevatedButton(
                onPressed: () {
                  windowManager.destroy();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'إغلاق التطبيق',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// التطبيق الرئيسي
class MyApp extends StatefulWidget {
  final int remainingTime;

  const MyApp({
    super.key,
    required this.remainingTime,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _fontScalePercent = 0.5;
  double _iconScalePercent = 0.5;
  bool _isLoading = true;
  bool _hasShownReminder = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScalePercent = prefs.getDouble('font_scale_percent') ?? 0.5;
      _iconScalePercent = prefs.getDouble('icon_scale_percent') ?? 0.5;
      _isLoading = false;
    });
  }

  double get _fontScale => 1.0 + _fontScalePercent;
  double get _iconScale => 1.0 + _iconScalePercent;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // عرض تنبيه عند بقاء 3 أيام أو أقل
    if (!_hasShownReminder &&
        widget.remainingTime <= 3 &&
        widget.remainingTime > 0) {
      _hasShownReminder = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ تنبيه: متبقي ${widget.remainingTime} أيام على انتهاء النسخة التجريبية',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }

    return MaterialApp(
      title: 'Al Hal Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 28 * _fontScale),
          displayMedium: TextStyle(fontSize: 24 * _fontScale),
          displaySmall: TextStyle(fontSize: 20 * _fontScale),
          headlineLarge: TextStyle(fontSize: 24 * _fontScale),
          headlineMedium: TextStyle(fontSize: 20 * _fontScale),
          headlineSmall: TextStyle(fontSize: 16 * _fontScale),
          titleLarge: TextStyle(fontSize: 18 * _fontScale),
          titleMedium: TextStyle(fontSize: 16 * _fontScale),
          titleSmall: TextStyle(fontSize: 14 * _fontScale),
          bodyLarge: TextStyle(fontSize: 14 * _fontScale),
          bodyMedium: TextStyle(fontSize: 12 * _fontScale),
          bodySmall: TextStyle(fontSize: 10 * _fontScale),
          labelLarge: TextStyle(fontSize: 14 * _fontScale),
          labelMedium: TextStyle(fontSize: 12 * _fontScale),
          labelSmall: TextStyle(fontSize: 10 * _fontScale),
        ),
        iconTheme: IconThemeData(size: 24 * _iconScale),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(iconSize: 24 * _iconScale),
        ),
        appBarTheme: AppBarTheme(
          toolbarHeight: 112.0,
          titleTextStyle: TextStyle(
            fontSize: 18 * _fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            size: 24 * _iconScale,
            color: Colors.white,
          ),
          toolbarTextStyle: TextStyle(
            fontSize: 14 * _fontScale,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: TextStyle(fontSize: 14 * _fontScale),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(fontSize: 14 * _fontScale),
          hintStyle: TextStyle(fontSize: 12 * _fontScale),
          errorStyle: TextStyle(fontSize: 10 * _fontScale),
        ),
        listTileTheme: ListTileThemeData(
          titleTextStyle: TextStyle(fontSize: 14 * _fontScale),
          subtitleTextStyle: TextStyle(fontSize: 12 * _fontScale),
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontSize: 12 * _fontScale),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_fontScale),
          ),
          child: child!,
        );
      },
    );
  }
}
