import 'package:flutter/material.dart';

/// User-supplied Listd brand logo (purple "L" with check inside).
///
/// Source asset lives at `assets/images/listd_logo.png` and is rendered
/// at the requested [size] with a square aspect ratio. Use this in the
/// auth screen, sidebar header, and anywhere else the product wordmark
/// would be appropriate.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.semanticLabel = 'Listd',
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/listd_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
    );
  }
}
