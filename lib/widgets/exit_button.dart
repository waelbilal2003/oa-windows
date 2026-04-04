import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// زر خروج موحد يمكن استخدامه في جميع الشاشات
/// يدعم النقر العادي وزر Esc من لوحة المفاتيح
/// يعمل بغض النظر عن أي widget لديه الـ focus حالياً
class ExitButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final String text;

  const ExitButton({
    super.key,
    this.onPressed,
    this.width,
    this.height,
    this.text = 'خروج',
  });

  @override
  State<ExitButton> createState() => _ExitButtonState();
}

class _ExitButtonState extends State<ExitButton> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      // التحقق من عدم وجود نافذة منبثقة (Dialog) مفتوحة حالياً
      // إذا كانت هناك نافذة مفتوحة، نتركها تعالج Esc بنفسها
      if (mounted) {
        final NavigatorState? navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          // التحقق: هل الشاشة الحالية هي أعلى مستوى أم أن هناك dialog مفتوح
          // نستخدم ModalRoute للتحقق
          final route = ModalRoute.of(context);
          if (route != null && route.isCurrent) {
            _handleBackButton();
            return true; // تم معالجة الحدث، لا تنقله
          }
        }
      }
    }
    return false; // لم يُعالج، انقله للـ widgets الأخرى
  }

  void _handleBackButton() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 140,
      height: widget.height ?? 80,
      child: ElevatedButton(
        onPressed: _handleBackButton,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
        child: Text(
          widget.text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
