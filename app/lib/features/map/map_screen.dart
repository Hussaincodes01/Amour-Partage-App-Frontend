import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';
import '../home/home_screen.dart';
import 'share_location_sheet.dart';

/// Where you both are. Sharing is mutual, visible and time-boxed.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _Map(partner: state.partnerLocation, me: state.myShare.myPoint, partnerPerson: state.couple?.partner)),
          Positioned(
            top: pad.top + 8,
            left: 12,
            child: RoundIconButton(icon: Symbols.arrow_back, color: c.surface, semanticLabel: 'Back', onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: pad.bottom + 12,
            child: const FadePop(child: _ShareCard()),
          ),
        ],
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.partner, required this.me, required this.partnerPerson});

  final PartnerLocation? partner;
  final GeoPoint? me;
  final Person? partnerPerson;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Map tiles need the network; tests show a still image instead.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return CoverImage(DemoImages.mapParis);
    final points = [
      if (partner != null) LatLng(partner!.point.lat, partner!.point.lng),
      if (me != null) LatLng(me!.lat, me!.lng),
    ];
    final style = c.isDark ? 'dark_all' : 'light_all';
    return FlutterMap(
      options: MapOptions(
        initialCenter: points.isNotEmpty ? points.first : const LatLng(48.8566, 2.3522),
        initialZoom: 13,
        initialCameraFit: points.length > 1 ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(60, 120, 60, 260), maxZoom: 15) : null,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/$style/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.amourpartage.app',
        ),
        MarkerLayer(
          markers: [
            if (me != null)
              Marker(
                point: LatLng(me!.lat, me!.lng),
                width: 22,
                height: 22,
                child: Container(decoration: BoxDecoration(color: c.lavender, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
              ),
            if (partner != null)
              Marker(
                point: LatLng(partner!.point.lat, partner!.point.lng),
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (partner!.approximate) Container(decoration: BoxDecoration(color: c.pink.withValues(alpha: 0.18), shape: BoxShape.circle)),
                    Avatar(image: partnerPerson?.photo, name: partnerPerson?.name ?? '', size: 44, ring: true),
                  ],
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(source: Text('© OpenStreetMap · © CARTO')),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard();

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    return '${d.inHours} h ago';
  }

  String _left(DateTime? until) {
    if (until == null) return 'until you stop';
    final d = until.difference(DateTime.now());
    if (d.inMinutes < 60) return '${d.inMinutes.clamp(0, 59)} min left';
    return '${d.inHours} h ${d.inMinutes % 60} min left';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final partner = state.partnerLocation;
    final share = state.myShare;
    return AmourCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(image: state.couple?.partner.photo, name: state.partnerName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner == null ? '${state.partnerName} isn’t sharing' : '${state.partnerName} · ${formatDistance(partner.distanceKm)} away', style: AppText.subhead),
                    const SizedBox(height: 2),
                    Text(
                      partner == null ? 'You’ll see them here when they share.' : 'Updated ${_ago(partner.updatedAt)}${partner.approximate ? ' · approximate' : ''}',
                      style: AppText.small.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Container(height: 1, color: c.border)),
          if (share.active)
            Row(
              children: [
                PingDot(color: c.success, size: 8),
                const SizedBox(width: 10),
                Expanded(child: Text('You’re sharing · ${_left(share.until)}', style: AppText.smallStrong)),
                TonalButton(
                  label: 'Stop',
                  icon: Symbols.location_off,
                  expand: false,
                  height: 40,
                  color: c.danger,
                  onTap: () async {
                    await state.backend.stopSharing();
                    if (context.mounted) showToast(context, 'Location sharing stopped', icon: Symbols.location_off);
                  },
                ),
              ],
            )
          else
            GradientButton(label: 'Share my location', icon: Symbols.near_me, onTap: () => showAmourSheet<void>(context, builder: (_) => const ShareLocationSheet())),
        ],
      ),
    );
  }
}
