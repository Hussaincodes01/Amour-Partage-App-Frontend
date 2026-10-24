import 'package:flutter/widgets.dart';

/// Demo imagery from the Figma theme. In production these come from the
/// couple's own encrypted data (avatars, vault photos, live camera feeds),
/// so they are kept in one place and easy to swap out.
abstract final class DemoImages {
  static const _dir = 'assets/demo';

  static const camille = AssetImage('$_dir/avatar_camille.jpg');
  static const julian = AssetImage('$_dir/avatar_julian.jpg');
  static const partnerVideo = AssetImage('$_dir/partner_video.jpg');
  static const selfVideo = AssetImage('$_dir/self_video.jpg');
  static const partnerCam = AssetImage('$_dir/lounge_partner_cam.jpg');

  static const kyoto = AssetImage('$_dir/vault_kyoto.jpg');
  static const bigSur = AssetImage('$_dir/vault_bigsur.jpg');
  static const montmartre = AssetImage('$_dir/vault_montmartre.jpg');
  static const movieNight = AssetImage('$_dir/vault_movie_night.jpg');
  static const stargazing = AssetImage('$_dir/vault_stargazing.jpg');
  static const lockedTeaser = AssetImage('$_dir/chat_locked_teaser.jpg');

  static const neonStreet = AssetImage('$_dir/lounge_neon_street.jpg');
  static const queueApocalypse = AssetImage('$_dir/queue_apocalypse.jpg');
  static const queueGhibli = AssetImage('$_dir/queue_ghibli.jpg');
  static const queueParis = AssetImage('$_dir/queue_paris_walk.jpg');

  static const mapParis = AssetImage('$_dir/map_paris.jpg');

  static const all = [
    camille, julian, partnerVideo, selfVideo, partnerCam, kyoto, bigSur, montmartre, movieNight,
    stargazing, lockedTeaser, neonStreet, queueApocalypse, queueGhibli, queueParis, mapParis,
  ];

  /// Decode everything up front so first frames of each tab never stall.
  static Future<void> precache(BuildContext context) =>
      Future.wait([for (final image in all) precacheImage(image, context)]);
}

/// Cover-fit image that decodes at display size (saves memory + GPU upload).
class CoverImage extends StatelessWidget {
  const CoverImage(this.image, {super.key, this.alignment = Alignment.center, this.colorFilter});

  final ImageProvider image;
  final Alignment alignment;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    Widget img = Image(
      image: image,
      fit: BoxFit.cover,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
    );
    if (colorFilter != null) img = ColorFiltered(colorFilter: colorFilter!, child: img);
    return img;
  }
}
