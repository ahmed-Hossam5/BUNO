import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_back_button.dart';
import '../../widgets/buno_buttons.dart';
import '../../widgets/buno_heart.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_lottie_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../../l10n/buno_locale.dart';

/// /favorites (reference 48_favorites): hearted stations with their bays,
/// walk time, open/closed and a "وديني" that opens the map on them. Empty
/// state when there are none. Tapping a card opens /station.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: ListenableBuilder(
            listenable: Repos.favorites,
            builder: (context, _) {
              final stations = Repos.favorites.stations;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(tr('المفضلة', 'Favorites'), maxLines: 1, style: BunoType.h3)),
                      if (stations.isNotEmpty)
                        BunoText(
                          '${stations.length} ${stations.length == 1 ? tr('محطة', 'station') : tr('محطات', 'stations')}',
                          style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                        ),
                      const SizedBox(width: BunoSpace.s3),
                      const BunoBackButton(),
                    ],
                  ),
                  Expanded(
                    child: stations.isEmpty
                        ? const _Empty()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: BunoSpace.s5),
                            itemCount: stations.length,
                            separatorBuilder: (_, _) => const SizedBox(height: BunoSpace.s3),
                            itemBuilder: (_, i) => _FavoriteCard(station: stations[i]),
                          ),
                  ),
                  BunoPrimaryButton(
                    label: stations.isEmpty ? tr('دوّر على محطة', 'Find a station') : tr('ضيف محطة للمفضلة', 'Add a station to favorites'),
                    icon: stations.isEmpty ? BunoIcons.location : BunoIcons.plus,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.stations),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final info = Repos.stations.infoOf(station);
    final label = Repos.favorites.labelOf(station);
    final ready = station.readyCount;
    final open = info.isOpenAt(DateTime.now());
    return BunoPressable(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.station, arguments: station.code),
      semanticLabel: station.name,
      child: Container(
        padding: const EdgeInsets.all(BunoSpace.s4),
        decoration: BoxDecoration(
          color: BunoDark.card,
          borderRadius: BorderRadius.circular(BunoRadius.xl),
          border: Border.all(color: BunoDark.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: BunoSize.avatarMd,
                  height: BunoSize.avatarMd,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BunoColors.primary_soft,
                    borderRadius: BorderRadius.circular(BunoRadius.md),
                  ),
                  child: const BunoIcon(BunoIcons.location, color: BunoColors.primary),
                ),
                const SizedBox(width: BunoSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: BunoType.title)),
                          if (label != null) ...[
                            const SizedBox(width: BunoSpace.s2),
                            _Tag(label),
                          ],
                        ],
                      ),
                      Text(
                        info.area,
                        maxLines: 1,
                        style: BunoType.caption.copyWith(color: BunoDark.text_secondary),
                      ),
                    ],
                  ),
                ),
                _RemoveHeart(station: station),
              ],
            ),
            const SizedBox(height: BunoSpace.s3),
            Row(
              children: [
                Expanded(child: _BaySegments(station: station)),
                const SizedBox(width: BunoSpace.s3),
                BunoText(
                  ready > 0 ? tr('$ready جاهز', '$ready ready') : tr('مفيش وحدات دلوقتي', 'No units right now'),
                  style: BunoType.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ready > 0 ? BunoColors.secondary : BunoColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BunoSpace.s3),
            Row(
              children: [
                Expanded(child: _Meta(text: tr('${station.walkMinutes} دقايق مشي', '${station.walkMinutes} min walk'), lottie: 'pin')),
                const SizedBox(width: BunoSpace.s2),
                Expanded(child: _Meta(text: open ? tr('مفتوحة', 'Open') : tr('مقفولة', 'Closed'), lottie: 'clock', highlight: open)),
                const SizedBox(width: BunoSpace.s2),
                Expanded(child: _GoButton(station: station, enabled: ready > 0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's name for the favourite ("الجامعة").
class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s2),
      decoration: BoxDecoration(
        color: BunoColors.primary,
        borderRadius: BorderRadius.circular(BunoRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: BunoDark.on_primary),
      ),
    );
  }
}

/// Filled heart; tapping removes the station from favourites.
class _RemoveHeart extends StatelessWidget {
  const _RemoveHeart({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: () => Repos.favorites.toggle(station),
      semanticLabel: tr('شيلها من المفضلة', 'Remove from favorites'),
      child: const SizedBox.square(
        dimension: BunoSize.touchMin,
        child: Center(
          child: BunoHeart(on: true, size: BunoSize.iconSm),
        ),
      ),
    );
  }
}

/// One segment per bay: ready green, low grey, empty dark.
class _BaySegments extends StatelessWidget {
  const _BaySegments({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('${station.readyCount} من ${station.bays.length} جاهزين', '${station.readyCount} of ${station.bays.length} ready'),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < station.bays.length; i++) ...[
              if (i > 0) const SizedBox(width: BunoSpace.s1),
              Expanded(
                child: Container(
                  height: BunoSpace.s5,
                  decoration: BoxDecoration(
                    color: station.isReady(i)
                        ? BunoColors.primary
                        : station.bays[i] != null
                            ? BunoDark.text_disabled
                            : BunoDark.elevated,
                    borderRadius: BorderRadius.circular(BunoRadius.xs),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text, required this.lottie, this.highlight = false});

  final String text;
  final String lottie;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? BunoColors.secondary : BunoDark.text_secondary;
    return Container(
      constraints: const BoxConstraints(minHeight: BunoSize.buttonMd),
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s2, vertical: BunoSpace.s1),
      decoration: BoxDecoration(
        color: BunoDark.background,
        borderRadius: BorderRadius.circular(BunoRadius.md),
        border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BunoLottieIcon(name: lottie, size: BunoSize.iconSm, color: color),
          const SizedBox(width: BunoSpace.s1),
          Flexible(
            child: BunoText(
              text,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: BunoType.caption.copyWith(height: 1.3, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the map on this station; greyed out when nothing is ready.
class _GoButton extends StatelessWidget {
  const _GoButton({required this.station, required this.enabled});

  final Station station;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? BunoColors.primary : BunoDark.text_disabled;
    return BunoPressable(
      onTap: enabled ? () => Navigator.of(context).pushNamed(AppRoutes.stations, arguments: station.code) : null,
      semanticLabel: tr('وديني ${station.name}', 'Take me to ${station.name}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: BunoSize.buttonMd),
        padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s2),
        decoration: BoxDecoration(
          color: enabled ? BunoColors.primary_soft : BunoDark.elevated,
          borderRadius: BorderRadius.circular(BunoRadius.md),
          border: Border.all(color: enabled ? BunoColors.primary : BunoDark.border, width: BunoStroke.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BunoLottieIcon(name: 'navigate', size: BunoSize.iconSm, color: color),
            const SizedBox(width: BunoSpace.s1),
            Flexible(
              child: Text(
                tr('وديني', 'Take me'),
                maxLines: 1,
                style: BunoType.caption.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reference 65_favorites_empty: nothing hearted yet.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: BunoSpace.s8),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: BunoColors.primary_soft, shape: BoxShape.circle),
            child: const BunoLottieIcon(name: 'heart', size: 56, playKey: 'empty', color: BunoColors.primary),
          ),
          const SizedBox(height: BunoSpace.s5),
          Text(tr('لسه مفيش محطات في المفضلة', 'No favorite stations yet'), textAlign: TextAlign.center, style: BunoType.h3),
          const SizedBox(height: BunoSpace.s2),
          Text(
            tr('دوس على القلب في صفحة أي محطة، وهتلاقيها هنا على طول.', "Tap the heart on any station's page and you'll find it here."),
            textAlign: TextAlign.center,
            style: BunoType.body.copyWith(color: BunoDark.text_secondary),
          ),
        ],
      ),
    );
  }
}
