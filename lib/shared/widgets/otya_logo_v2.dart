import 'package:flutter/material.dart';

/// Displays the owner-approved Otya master lockup exactly as supplied.
/// The source-derived image is bundled locally so the brand remains available offline.
class OtyaLogo extends StatelessWidget {
  const OtyaLogo({
    super.key,
    this.fontSize = 30,
    this.letterSpacing = -1.2,
    this.color,
    this.iconOnly = false,
    this.borderRadius = 12,
    this.padding = EdgeInsets.zero,
  });

  final double fontSize;
  final double letterSpacing;
  final Color? color;
  final bool iconOnly;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return OtyaMark(size: fontSize * 1.25, borderRadius: borderRadius);
    }

    final height = fontSize * 1.9;
    final width = height * (560 / 179);
    return Padding(
      padding: padding,
      child: Image.asset(
        'assets/branding/otya_master_lockup.webp',
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Otya — One ecosystem. Endless possibilities.',
      ),
    );
  }
}

/// Exact orbital symbol crop from the approved Otya artwork.
class OtyaMark extends StatelessWidget {
  const OtyaMark({
    super.key,
    this.size = 36,
    this.color,
    this.borderRadius = 10,
  });

  final double size;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: Colors.white,
          child: Image.asset(
            'assets/branding/otya_orbital_mark.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Otya orbital mark',
          ),
        ),
      ),
    );
  }
}

/// Compact presentation of the same approved orbital artwork.
class OtyaThinkingMark extends StatelessWidget {
  const OtyaThinkingMark({
    super.key,
    this.size = 36,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => OtyaMark(size: size);
}
