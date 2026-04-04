import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// زر خروج موحد يمكن استخدامه في جميع الشاشات
/// يدعم النقر العادي وزر Esc من لوحة المفاتيح
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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _handleBackButton();
        }
      },
      child: SizedBox(
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
      ),
    );
  }
}
