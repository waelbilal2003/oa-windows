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

// وضع الاختبار: تغيير هذه القيمة للتبديل بين وضع الاختبار والوضع الحقيقي
const bool TEST_MODE =
    true; // true = وضع الاختبار (دقائق), false = وضع حقيقي (أيام)
const int TRIAL_DURATION_MINUTES = 2; // مدة الاختبار بالدقائق (للتجربة)
const int TRIAL_DURATION_DAYS = 7; // المدة الحقيقية بالأيام

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

  if (TEST_MODE) {
    // حذف بيانات الاختبار السابقة لبدء اختبار جديد (اختياري)
    // await prefs.remove('trial_first_launch_datetime');

    final String? firstLaunchDateTime =
        prefs.getString('trial_first_launch_datetime');
    final DateTime now = DateTime.now();

    bool isTrialValid = true;
    int remainingMinutes = TRIAL_DURATION_MINUTES;

    if (firstLaunchDateTime == null) {
      // أول تشغيل - حفظ وقت بدء الاختبار
      await prefs.setString(
          'trial_first_launch_datetime', now.toIso8601String());
      print('═══ وضع الاختبار ═══');
      print('تم بدء الاختبار في: ${now.hour}:${now.minute}:${now.second}');
      print('مدة الاختبار: $TRIAL_DURATION_MINUTES دقائق');
      print(
          'سينتهي الاختبار في: ${now.add(Duration(minutes: TRIAL_DURATION_MINUTES)).hour}:${now.add(Duration(minutes: TRIAL_DURATION_MINUTES)).minute}');
      remainingMinutes = TRIAL_DURATION_MINUTES;
    } else {
      final DateTime firstLaunch = DateTime.parse(firstLaunchDateTime);
      final int minutesPassed = now.difference(firstLaunch).inMinutes;

      print('═══ وضع الاختبار ═══');
      print(
          'وقت البدء: ${firstLaunch.hour}:${firstLaunch.minute}:${firstLaunch.second}');
      print('الدقائق المنقضية: $minutesPassed');

      if (minutesPassed >= TRIAL_DURATION_MINUTES) {
        isTrialValid = false;
        remainingMinutes = 0;
        print('⚠️ انتهت فترة الاختبار!');
      } else {
        remainingMinutes = TRIAL_DURATION_MINUTES - minutesPassed;
        print('✅ متبقي: $remainingMinutes دقائق');
      }
    }

    if (!isTrialValid) {
      runApp(const TrialExpiredApp(isTestMode: true));
    } else {
      runApp(MyApp(remainingTime: remainingMinutes, isTestMode: true));
    }
  } else {
    // الوضع الحقيقي (أيام)
    final String? firstLaunchDate = prefs.getString('trial_first_launch_date');
    final DateTime now = DateTime.now();

    bool isTrialValid = true;
    int remainingDays = TRIAL_DURATION_DAYS;

    if (firstLaunchDate == null) {
      await prefs.setString(
          'trial_first_launch_date', now.toIso8601String().split('T')[0]);
      remainingDays = TRIAL_DURATION_DAYS;
    } else {
      final DateTime firstLaunch = DateTime.parse(firstLaunchDate);
      final int daysPassed = now.difference(firstLaunch).inDays;

      if (daysPassed >= TRIAL_DURATION_DAYS) {
        isTrialValid = false;
        remainingDays = 0;
      } else {
        remainingDays = TRIAL_DURATION_DAYS - daysPassed;
      }
    }

    if (!isTrialValid) {
      runApp(const TrialExpiredApp(isTestMode: false));
    } else {
      runApp(MyApp(remainingTime: remainingDays, isTestMode: false));
    }
  }
}

// تطبيق انتهاء الصلاحية
class TrialExpiredApp extends StatelessWidget {
  final bool isTestMode;

  const TrialExpiredApp({super.key, required this.isTestMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF1A1A1A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gpp_bad,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 30),
              Text(
                isTestMode
                    ? 'انتهت فترة الاختبار!'
                    : 'انتهت صلاحية النسخة التجريبية',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isTestMode
                    ? 'يمكنك إعادة تشغيل التطبيق لبدء اختبار جديد'
                    : 'انتهت فترة التجربة البالغة 7 أيام',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى الاتصال بالمطور للحصول على النسخة الكاملة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      windowManager.destroy();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'إغلاق التطبيق',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isTestMode) ...[
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // إعادة تعيين البيانات للتجربة مرة أخرى
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('trial_first_launch_datetime');
                        // عرض SnackBar بشكل صحيح
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'تم إعادة التعيين. أعد تشغيل التطبيق للتجربة مرة أخرى.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'إعادة التجربة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// التطبيق الرئيسي مع عرض الوقت المتبقي
class MyApp extends StatefulWidget {
  final int remainingTime;
  final bool isTestMode;

  const MyApp({
    super.key,
    required this.remainingTime,
    required this.isTestMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _fontScalePercent = 0.5;
  double _iconScalePercent = 0.5;
  bool _isLoading = true;
  String _remainingText = '';
  bool _hasShownReminder = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _updateRemainingText();
  }

  void _updateRemainingText() {
    if (widget.isTestMode) {
      _remainingText = '⏱ اختبار: ${widget.remainingTime} دقائق متبقية';
    } else {
      _remainingText = '📅 تجريبي: ${widget.remainingTime} أيام متبقية';
    }
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

    // استخدام addPostFrameCallback لتأخير عرض SnackBar حتى يتم بناء الشجرة
    if (!_hasShownReminder &&
        widget.remainingTime <= 3 &&
        widget.remainingTime > 0) {
      _hasShownReminder = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          String message;
          if (widget.isTestMode) {
            message = '⚠️ تنبيه: متبقي ${widget.remainingTime} دقائق فقط!';
          } else {
            message =
                '⚠️ تنبيه: متبقي ${widget.remainingTime} أيام على انتهاء النسخة التجريبية';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
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
      home: Builder(
        builder: (context) {
          // إضافة شريط علوي يوضح الوقت المتبقي في وضع الاختبار
          if (widget.isTestMode) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: widget.remainingTime <= 2 ? Colors.red : Colors.orange,
                  child: Text(
                    _remainingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(child: LoginScreen()),
              ],
            );
          }
          return const LoginScreen();
        },
      ),
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
