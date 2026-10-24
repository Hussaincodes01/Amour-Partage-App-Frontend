import 'package:flutter/widgets.dart';

/// Material Symbols glyph (the icon set the Figma theme is drawn with).
/// [size] is the icon font size, as in the design's icon containers.
class Sym extends StatelessWidget {
  const Sym(this.icon, {super.key, this.size = 20, this.color, this.fill = false, this.weight = 400});

  final IconData icon;
  final double size;
  final Color? color;
  final bool fill;
  final double weight;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color, fill: fill ? 1 : 0, weight: weight, opticalSize: size.clamp(20, 48));
  }
}
