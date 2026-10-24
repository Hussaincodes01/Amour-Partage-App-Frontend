import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Circular photo avatar with optional gradient ring and status dot.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.image,
    this.size = 32,
    this.ring,
    this.ringWidth = 2,
    this.status,
    this.statusSize = 10,
    this.statusBorder,
    this.glow,
  });

  final ImageProvider image;
  final double size;
  final Gradient? ring;
  final double ringWidth;
  final Color? status;
  final double statusSize;
  final Color? statusBorder;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final inner = size - (ring != null ? ringWidth * 2 : 0);
    Widget photo = ClipOval(
      child: Image(
        image: ResizeImage.resizeIfNeeded((inner * dpr).round(), null, image),
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      ),
    );
    if (ring != null) {
      photo = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          gradient: ring,
          shape: BoxShape.circle,
          boxShadow: glow != null ? [BoxShadow(color: glow!, blurRadius: 10)] : null,
        ),
        child: photo,
      );
    }
    if (status == null) return SizedBox.square(dimension: size, child: photo);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          photo,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: statusSize,
              height: statusSize,
              decoration: BoxDecoration(
                color: status,
                shape: BoxShape.circle,
                border: statusBorder != null ? Border.all(color: statusBorder!, width: 2) : null,
                boxShadow: [BoxShadow(color: status!.withValues(alpha: 0.8), blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Initial-letter avatar ("J", "C", "YOU", "CA").
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.text, required this.color, this.size = 14, this.textColor = const Color(0xFFFFFFFF), this.fontSize = 8, this.borderColor});

  final String text;
  final Color color;
  final double size;
  final Color textColor;
  final double fontSize;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!, width: 2) : null,
      ),
      child: Text(text, style: AppText.label.copyWith(fontSize: fontSize, height: 1, letterSpacing: 0, color: textColor)),
    );
  }
}

/// Default ring for partner avatars.
const partnerRing = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [AppColors.lavender, AppColors.hotPink],
);
