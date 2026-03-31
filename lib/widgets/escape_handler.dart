import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EscapeHandler extends StatelessWidget {
  final Widget child;

  const EscapeHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
