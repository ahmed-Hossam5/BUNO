import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../app_routes.dart';
import '../../data/mock_exam.dart';
import '../../data/repositories.dart';
import '../../data/mock_rental.dart';
import '../../data/mock_search.dart';
import '../../data/mock_settings.dart';
import '../../data/mock_sos.dart';
import '../../data/mock_station_info.dart';
import '../../data/mock_wrapped.dart';
import '../../data/phone_battery.dart';
import '../../data/user_location.dart';
import '../../theme/buno_tokens.dart';
import '../../theme/buno_tokens_ext.dart';
import '../../widgets/buno_bay_tile.dart' show chargeColor;
import '../../widgets/buno_bottom_nav.dart';
import '../../widgets/buno_icon.dart';
import '../../widgets/buno_pressable.dart';
import '../../widgets/buno_text.dart';
import '../exam/exam_cards.dart';
import '../sos/sos_screen.dart' show openSos;
import '../wrapped/wrapped_banner.dart';
import 'home_map.dart';
import 'home_sheet.dart';
import 'home_state_bodies.dart';
import 'home_top_bar.dart';
import '../../l10n/buno_locale.dart';

/// What home leads with, from the phone battery and the rental.
enum HomeMode {
  /// 20% or more (or unreadable): calm, nearest station.
  calm,

  /// Below [HomeScreen.reserveBelow] and not charging: red ring, reserve.
  low,

  /// Charging while a Buno unit is rented (reference 101).
  buno,
}

/// Home (references 99, 100, 101): a map centred on the user, whose dot is
/// wrapped in the phone-battery ring, the nearest station with a dotted
/// walk to it, and a draggable sheet with that station (or the running
/// rental) and the main button. Mock data. In exam week
/// ([MockSettings.examMode], or [exam] on /exam) the exam cards open the
/// sheet (reference 55).
///
/// The sheet also shows, first match wins: a held bay (112), a closed
/// station picked on the map (113), location off (110), and no station
/// within 3 km (111). The search field opens /search (107); "?" opens how
/// it works (109).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.exam = false});

  /// Shows the exam-week cards whatever [MockSettings.examMode] says.
  final bool exam;

  /// Below this charge (and not charging) home turns red and the main
  /// button reserves a unit instead of scanning.
  static const reserveBelow = 20;

  /// "الحلقة حواليك = بطارية موبايلك" shows until tapped or until home is
  /// left once. Memory only.
  static final ringHintSeen = ValueNotifier<bool>(false);

  /// "بلّغني" when no station is nearby (reference 111). Memory only.
  static final nearbyAlert = ValueNotifier<bool>(false);

  static HomeMode modeFor(BatteryReading r, {required bool renting}) {
    if (r.charging && renting) return HomeMode.buno;
    final p = r.percent;
    if (p != null && p < reserveBelow && !r.charging) return HomeMode.low;
    return HomeMode.calm;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tab = 0;

  /// Horizontal screen margin measured on the reference (22pt).
  static const _gutter = 22.0;

  static List<BunoNavItem> get _navItems => [
    BunoNavItem(icon: BunoIcons.home, label: tr('الرئيسية', 'Home')),
    BunoNavItem(icon: BunoIcons.history, label: tr('رحلاتي', 'Trips')),
    BunoNavItem(icon: BunoIcons.wallet, label: tr('المحفظة', 'Wallet')),
    BunoNavItem(icon: BunoIcons.profile, label: tr('حسابي', 'Profile')),
  ];

  final _map = GlobalKey<HomeMapState>();

  /// Keeps the rental's elapsed time fresh; runs only while renting.
  Timer? _ticker;

  /// Ticks the held bay's countdown; runs only while a bay is held.
  Timer? _holdTicker;

  /// Picked in search or on the map (a closed station); null = nearest.
  Station? _selected;

  /// A place picked in search: the map centres on it.
  LatLng? _focus;

  /// Collapsed sheet height, measured after layout; null before the first.
  double? _sheetHeight;
  bool _hintShown = false;

  static bool get _renting => rentalSession.state == RentalState.active;

  @override
  void initState() {
    super.initState();
    rentalSession.addListener(_onRental);
    reservationSession.addListener(_onRental);
    _syncTicker();
  }

  @override
  void dispose() {
    rentalSession.removeListener(_onRental);
    reservationSession.removeListener(_onRental);
    _ticker?.cancel();
    _holdTicker?.cancel();
    if (_hintShown) HomeScreen.ringHintSeen.value = true;
    super.dispose();
  }

  void _onRental() {
    if (!mounted) return;
    // Other screens change the rental while building (e.g. /release starts
    // the unlock); rebuild after that frame.
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => _onRental());
      return;
    }
    _syncTicker();
    setState(() {});
  }

  void _syncTicker() {
    if (_renting) {
      _ticker ??= Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
    if (reservationSession.current != null) {
      _holdTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        // Running out notifies, which stops this ticker.
        if (!reservationSession.expireIfDue()) setState(() {});
      });
    } else {
      _holdTicker?.cancel();
      _holdTicker = null;
    }
  }

  void _onSheetHeight(double h) {
    if (!mounted || (_sheetHeight != null && (_sheetHeight! - h).abs() < 0.5)) return;
    setState(() => _sheetHeight = h);
  }

  void _push(String route, [Object? arguments]) => Navigator.of(context).pushNamed(route, arguments: arguments);

  void _onScan() => _push(MockSettings.simulateOffline.value ? AppRoutes.offline : AppRoutes.scan);

  void _onStudyNight() {
    studyNight.start();
    _push(AppRoutes.examNight);
  }

  void _onReserve() => _push(reservationSession.current == null ? AppRoutes.reserve : AppRoutes.reserved);

  /// A closed station stays on home with its hours; an open one opens
  /// /station.
  void _onStation(Station s) {
    if (isStationOpen(s)) {
      _push(AppRoutes.station, s.code);
    } else {
      setState(() => _selected = s);
    }
  }

  /// A station picked in search is selected; a place centres the map.
  Future<void> _openSearch() async {
    final picked = await Navigator.of(context).pushNamed<Object?>(AppRoutes.search);
    if (!mounted) return;
    setState(() {
      if (picked is Station) {
        _selected = picked;
        _focus = null;
      } else if (picked is MapPlace) {
        _focus = picked.position;
        _selected = null;
      }
    });
  }

  void _recenter() {
    setState(() {
      _selected = null;
      _focus = null;
    });
    _map.currentState?.recenter();
  }

  /// Same as "وديني" on /station/info: the station on the stations map.
  void _directions(Station s) => _push(AppRoutes.stations, s.code);

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  void _cancelReservation() {
    reservationSession.cancel();
    _toast(tr('اتلغى الحجز', 'Reservation cancelled'));
  }

  void _notifyNearby() {
    HomeScreen.nearbyAlert.value = true;
    _toast(tr('تمام، هنبلّغك أول ما محطة تفتح قريب منك', "Done. We'll tell you when a station opens near you"));
  }

  /// "+N%" gained since pickup; null when either reading is unknown.
  static int? get _gain {
    final now = PhoneBattery.shared.reading.percent, then = rentalSession.phoneChargeAtPickup;
    return now == null || then == null ? null : now - then;
  }

  /// Ring colour: same thresholds as the phone's charge everywhere else.
  static Color _ringColor(BatteryReading reading, HomeMode mode) => switch (mode) {
        HomeMode.low => BunoColors.error,
        HomeMode.buno => BunoColors.primary,
        HomeMode.calm when reading.charging => BunoColors.primary,
        HomeMode.calm => reading.percent == null ? BunoDark.text_secondary : chargeColor(reading.percent),
      };

  static String _ringLabel(BatteryReading reading, HomeMode mode) {
    final percent = reading.percent;
    if (percent == null) return tr('بطارية موبايلك مش معروفة', "Your phone's battery is unknown");
    final label = switch (mode) {
      HomeMode.buno => tr('بيشحن من بونو', 'Charging from Buno'),
      HomeMode.calm when reading.charging => tr('بيشحن', 'charging'),
      _ => tr('موبايلك', 'Your phone'),
    };
    return tr('بطارية موبايلك $percent%، $label', "Your phone's battery is $percent%, $label");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BunoDark.background,
      body: LayoutBuilder(
        builder: (context, c) => ListenableBuilder(
          listenable: Listenable.merge(
            [
              PhoneBattery.shared, reservationSession, sosSession, MockSettings.examMode, studyNight,
              MockSettings.wrappedNow, MockWrapped.dismissed, HomeScreen.ringHintSeen, UserLocation.shared,
              HomeScreen.nearbyAlert,
            ],
          ),
          builder: (context, _) => _body(context, c.biggest),
        ),
      ),
      // In the Scaffold slot so toasts float above it (components.md Toast).
      bottomNavigationBar: BunoBottomNav(
        items: _navItems,
        currentIndex: _tab,
        onSelected: (i) => AppRoutes.goToTab(context, i, _tab),
      ),
    );
  }

  Widget _body(BuildContext context, Size size) {
    final reading = PhoneBattery.shared.reading;
    final renting = _renting;
    final mode = HomeScreen.modeFor(reading, renting: renting);
    final exam = widget.exam || MockSettings.examMode.value;
    final wrapped = MockWrapped.bannerVisible;
    final stations = Repos.stations.all;
    final ready = Repos.stations.nearestReady() ?? stations.first;
    final returnTo = renting ? Repos.stations.nearestReturn() : null;
    final location = UserLocation.shared;
    final locationOff = location.needsEnabling;
    final reservation = renting ? null : reservationSession.current;
    final selected = _selected;
    final closedPick = selected != null && !isStationOpen(selected) ? selected : null;

    // No station within 3 km of a known location (reference 111).
    Station? closest;
    for (final s in stations) {
      final m = s.metersAway;
      if (m != null && (closest == null || m < closest.metersAway!)) closest = s;
    }
    final closestMeters = closest?.metersAway;
    final far = !renting && !locationOff && closestMeters != null && closestMeters > HomeNothingNearBody.farMeters;

    final nearest = reservation?.station ?? selected ?? returnTo ?? (far ? closest! : ready);
    final color = _ringColor(reading, mode);
    final topInset = MediaQuery.paddingOf(context).top;

    // Room above the sheet decides the ring; the user sits just above it.
    final sheet = _sheetHeight ?? size.height * 0.45;
    final above = size.height - sheet;
    final ringSize = (above * 0.24).clamp(72.0, 116.0);
    final topBand = topInset + 18 + BunoSize.touchMin + 56;
    final anchorY = (above - ringSize / 2 - 22).clamp(topBand + ringSize / 2, double.infinity);
    final anchor = Offset(size.width / 2, anchorY);

    _hintShown = _hintShown || (mode == HomeMode.calm && !locationOff && !far && !HomeScreen.ringHintSeen.value);
    final pill = switch (mode) {
      HomeMode.low => _MapPill(
          color: BunoColors.error,
          text: tr('موبايلك هيفصل قريب · أقرب وحدة على بعد ${ready.walkMinutes} د',
              'Your phone will die soon · nearest unit is ${ready.walkMinutes} min away'),
        ),
      HomeMode.buno => _GainPill(gain: _gain),
      // Location refused or off: the map sits on the campus default.
      HomeMode.calm when locationOff => _MapPill(
          color: BunoDark.text_primary,
          text: tr('الخريطة على وسط الحرم', 'Map centred on campus'),
        ),
      HomeMode.calm when far => _MapPill(
          color: BunoDark.text_secondary,
          text: tr('أقرب محطة على بعد ${distanceLabel(closestMeters)}', 'Nearest station is ${distanceLabel(closestMeters)} away'),
        ),
      HomeMode.calm when !HomeScreen.ringHintSeen.value => _MapPill(
          color: BunoDark.text_primary,
          text: tr('الحلقة حواليك = بطارية موبايلك', 'The ring around you = your phone battery'),
          onTap: () => HomeScreen.ringHintSeen.value = true,
        ),
      _ => null,
    };

    final others = [
      for (final s in stations)
        if (s.id != nearest.id) s,
    ]..sort((a, b) => a.walkMinutes.compareTo(b.walkMinutes));

    return Stack(
      children: [
        Positioned.fill(
          child: HomeMap(
            key: _map,
            user: location.center,
            anchor: anchor,
            stations: stations,
            nearest: nearest,
            focus: _focus,
            showUser: !locationOff,
            reservedLeft: reservation == null ? null : reservationSession.remaining,
            ringSize: ringSize,
            routeColor: reservation == null ? color : BunoColors.warning,
            bottomInset: sheet,
            onStation: _onStation,
            ring: HomeUserRing(
              percent: reading.percent,
              color: color,
              size: ringSize,
              bolt: mode == HomeMode.buno,
              semanticsLabel: _ringLabel(reading, mode),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              // The profile button's 44pt touch target overhangs its 40pt
              // circle by 2pt; the reference aligns the circle to the gutter.
              padding: const EdgeInsetsDirectional.fromSTEB(_gutter, 18, _gutter - 2, 0),
              child: Column(
                children: [
                  HomeTopBar(battery: reading, onSearch: _openSearch),
                  if (pill != null) ...[
                    const SizedBox(height: BunoSpace.s3),
                    pill,
                  ],
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: BunoSpace.s4,
          top: (anchorY - 84).clamp(topBand, double.infinity),
          child: Column(
            children: [
              _MapButton(icon: BunoIcons.help, label: tr('إزاي بيشتغل؟', 'How it works'), onTap: () => showHowItWorks(context)),
              const SizedBox(height: BunoSpace.s3),
              _MapButton(
                icon: BunoIcons.locate,
                label: tr('رجّعني لمكاني', 'Back to my location'),
                color: BunoColors.primary,
                onTap: _recenter,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: HomeSheet(
            onBaseHeight: _onSheetHeight,
            tint: renting
                ? null
                : reservation != null
                    ? BunoColors.warning
                    : closedPick != null
                        ? BunoDark.text_disabled
                        : mode == HomeMode.low && !locationOff && !far
                            ? BunoColors.error
                            : null,
            startExpanded: exam || wrapped,
            maxExtra: (size.height - sheet - topInset - 70).clamp(0.0, double.infinity),
            base: renting
                ? HomeRentalBody(
                    elapsed: rentalSession.duration ?? Duration.zero,
                    unitId: rentalSession.unit?.id,
                    returnStation: returnTo,
                    onReturn: () => _push(AppRoutes.returnUnit),
                    onDetails: () => _push(AppRoutes.rental),
                  )
                : reservation != null
                    ? HomeReservedBody(
                        reservation: reservation,
                        remaining: reservationSession.remaining,
                        hold: reservationSession.hold,
                        onScan: _onScan,
                        onDirections: () => _directions(reservation.station),
                        onCancel: _cancelReservation,
                        onCountdown: () => _push(AppRoutes.reserved),
                      )
                    : closedPick != null
                        ? HomeClosedBody(
                            station: closedPick,
                            open: Repos.stations.nearestReady(),
                            onTakeMe: (s) => setState(() => _selected = s),
                          )
                        : locationOff
                            ? HomeLocationOffBody(onEnable: location.openSettings, onSearch: _openSearch)
                            : far
                                ? HomeNothingNearBody(
                                    station: closest!,
                                    meters: closestMeters,
                                    notifyOn: HomeScreen.nearbyAlert.value,
                                    onDirections: () => _directions(closest!),
                                    onNotify: _notifyNearby,
                                  )
                                : HomeStationBody(
                    station: selected ?? ready,
                    nearest: selected == null,
                    reserve: mode == HomeMode.low,
                    // «إلحقني» replaces "has return space" when low; hidden
                    // once today's is used and answered.
                    askFriend: mode == HomeMode.low && (sosSession.canSendToday || sosSession.state != SosState.idle),
                    onScan: _onScan,
                    onReserve: _onReserve,
                    onAskFriend: () => openSos(context),
                    onAll: () => _push(AppRoutes.allStations),
                    onFavorites: () => _push(AppRoutes.favorites),
                    onReturnSpace: () => _push(AppRoutes.stations, Repos.stations.nearestReturn()?.code),
                  ),
            extra: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wrapped) ...[
                  WrappedBanner(onOpen: () => _push(AppRoutes.wrapped)),
                  const SizedBox(height: BunoSpace.s4),
                ],
                if (exam) ...[
                  ExamHomeCards(onNight: _onStudyNight),
                  const SizedBox(height: BunoSpace.s4),
                ],
                HomeOtherStations(stations: others, onStation: _onStation),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round map control on the end side (search, locate).
class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.label, required this.onTap, this.color = BunoDark.text_primary});

  final BunoIcons icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BunoPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BunoDark.card,
          border: Border.all(color: BunoDark.border, width: BunoStroke.hairline),
        ),
        child: BunoIcon(icon, color: color),
      ),
    );
  }
}

/// One-line pill under the top bar, tinted with [color].
class _MapPill extends StatelessWidget {
  const _MapPill({required this.color, required this.text, this.onTap});

  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s2),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.08), BunoDark.card),
        borderRadius: BorderRadius.circular(BunoRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35), width: BunoStroke.hairline),
      ),
      child: BunoText(
        text,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: color),
      ),
    );
    return onTap == null ? pill : BunoPressable(onTap: onTap!, semanticLabel: text, child: pill);
  }
}

/// "بيشحن من بونو · +16% من ساعة ما خدته"; the number is a placeholder
/// when the charge at pickup wasn't readable.
class _GainPill extends StatelessWidget {
  const _GainPill({required this.gain});

  final int? gain;

  @override
  Widget build(BuildContext context) {
    final style = BunoType.bodySm.copyWith(fontWeight: FontWeight.w600, color: BunoColors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BunoSpace.s4, vertical: BunoSpace.s2),
      decoration: BoxDecoration(
        color: BunoColors.primary_soft,
        borderRadius: BorderRadius.circular(BunoRadius.pill),
        border: Border.all(color: BunoColors.primary.withValues(alpha: 0.35), width: BunoStroke.hairline),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: tr('بيشحن من بونو · ', 'Charging from Buno · ')),
          // "+" inside the isolate so it stays before the number. The
          // placeholder is Arabic, so it keeps the Arabic font.
          if (gain == null)
            TextSpan(text: tr('+[النسبة]%', '+[percent]%'))
          else
            TextSpan(text: '\u2066+$gain%\u2069', style: BunoType.number(style)),
          TextSpan(text: tr(' من ساعة ما خدته', ' since you took it')),
        ]),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
