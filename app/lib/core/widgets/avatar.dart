import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Circular avatar: a photo when there is one, otherwise the initial.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.image, this.name = '', this.size = 40, this.ring = false, this.online});

  final ImageProvider? image;
  final String name;
  final double size;

  /// Brand gradient ring around the photo.
  final bool ring;

  /// Shows a presence dot (green when true, grey when false).
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final ringWidth = ring ? (size / 20).clamp(1.5, 3.0) : 0.0;
    final inner = size - ringWidth * 2;
    Widget face = image != null
        ? Image(
            image: ResizeImage.resizeIfNeeded((inner * dpr).round(), null, image!),
            width: inner,
            height: inner,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          )
        : Container(
            width: inner,
            height: inner,
            alignment: Alignment.center,
            decoration: const BoxDecoration(gradient: AppGradients.avatarRing),
            child: Text(
              name.isEmpty ? '♥' : name.characters.first.toUpperCase(),
              style: AppText.subhead.copyWith(color: const Color(0xFFFFFFFF), fontSize: inner * 0.4, height: 1),
            ),
          );
    face = ClipOval(child: face);
    if (ring) {
      face = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ringWidth),
        decoration: const BoxDecoration(gradient: AppGradients.avatarRing, shape: BoxShape.circle),
        child: face,
      );
    }
    if (online == null) return SizedBox.square(dimension: size, child: face);
    final dot = (size * 0.28).clamp(8.0, 14.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: online! ? c.success : c.textFaint,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two overlapping avatars ("Julian & Camille").
class CoupleAvatars extends StatelessWidget {
  const CoupleAvatars({super.key, required this.me, required this.partner, this.size = 44, this.meName = '', this.partnerName = ''});

  final ImageProvider? me;
  final ImageProvider? partner;
  final String meName;
  final String partnerName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = context.colors.surface;
    Widget ringed(ImageProvider? img, String name) => Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Avatar(image: img, name: name, size: size),
        );
    return SizedBox(
      width: size * 1.7 + 4,
      height: size + 4,
      child: Stack(
        children: [
          ringed(me, meName),
          Positioned(left: size * 0.7, child: ringed(partner, partnerName)),
        ],
      ),
    );
  }
}
