import 'package:flutter/material.dart';

import 'data/repositories.dart';
import 'data/mock_rental.dart';
import 'theme/buno_tokens_ext.dart';
import 'data/mock_topup.dart';
import 'screens/account/edit_profile_screen.dart';
import 'screens/account/help_screen.dart';
import 'screens/account/notifications_screen.dart';
import 'screens/account/plans_screen.dart';
import 'screens/account/referral_screen.dart';
import 'screens/account/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_code_screen.dart';
import 'screens/auth/verify_uni_screen.dart';
import 'screens/exam/exam_night_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/offline/no_internet_screen.dart';
import 'screens/offline/offline_code_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/ops/ops_home_screen.dart';
import 'screens/ops/ops_rebalance_screen.dart';
import 'screens/ops/ops_station_screen.dart';
import 'screens/ops/ops_tasks_screen.dart';
import 'screens/permissions/permissions_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/promo/promo_screen.dart';
import 'screens/rental/active_rental_screen.dart';
import 'screens/rental/receipt_screen.dart';
import 'screens/rental/release_screen.dart';
import 'screens/rental/report_screen.dart';
import 'screens/rental/return_done_screen.dart';
import 'screens/rental/return_screen.dart';
import 'screens/rental/unit_screen.dart';
import 'screens/rental/unlocking_screen.dart';
import 'screens/rental/verifying_screen.dart';
import 'screens/reserve/reserve_screen.dart';
import 'screens/reserve/reserved_screen.dart';
import 'screens/scan/scan_code_screen.dart';
import 'screens/scan/scan_methods_screen.dart';
import 'screens/scan/scan_nfc_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/sos/sos_got_screen.dart';
import 'screens/sos/sos_help_screen.dart';
import 'screens/sos/sos_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/station/confirm_screen.dart';
import 'screens/station/station_info_screen.dart';
import 'screens/station/station_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/support/emergency_screen.dart';
import 'screens/support/guarantee_screen.dart';
import 'screens/stations/all_stations_screen.dart';
import 'screens/stations/stations_screen.dart';
import 'screens/topup/topup_done_screen.dart';
import 'screens/topup/topup_pending_screen.dart';
import 'screens/topup/topup_screen.dart';
import 'screens/topup/transfer_screen.dart';
import 'screens/trust/trust_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/wrapped/wrapped_screen.dart';
import 'l10n/buno_locale.dart';

/// Route names. `flutter run --route <name>` (or `/#<name>` on web) opens a
/// screen directly.
class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const verify = '/verify';

  /// App start: logo intro, then [onboarding] the first time, [home] after.
  static const splash = '/splash';

  /// Sign-up after [verify]: permission switches, then [verifyUni].
  static const permissions = '/permissions';

  /// Optional university e-mail; sending or skipping enters the app.
  static const verifyUni = '/verify-uni';
  static const rental = '/rental';

  /// The unit in hand (RFID id, charge, temperature), from [rental].
  static const rentalUnit = '/rental/unit';
  static const wallet = '/wallet';
  static const profile = '/profile';
  static const scan = '/scan';
  static const scanCode = '/scan/code';

  /// QR, NFC or code; opened from the "other ways" link on [scan].
  static const scanMethods = '/scan/methods';

  /// Hold the phone on the NFC mark; the debug tap opens [station].
  static const scanNfc = '/scan/nfc';

  /// Hold a bay when the phone is low; home's main button opens it below
  /// 20%. Takes a [Station] as `arguments` (default: nearest with a ready
  /// unit); replaces itself with [reserved].
  static const reserve = '/reserve';

  /// Countdown on the held bay; "وصلت؟ امسح" opens [scan], cancel goes home.
  static const reserved = '/reserved';

  /// Takes the scanned or typed station code as `arguments` (String).
  static const station = '/station';

  /// Hours, return bays and directions, from the "i" on [station]. Takes the
  /// station code (String) as `arguments`.
  static const stationInfo = '/station/info';

  /// Hearted stations (the heart on [station]); empty state when none.
  static const favorites = '/favorites';

  /// Takes `(Station, int bayIndex)` as `arguments`; without them, the best
  /// bay of the first mock station.
  static const confirm = '/confirm';

  /// Server checks before the bay opens. Takes `(Station, int bayIndex)`
  /// like [confirm]; replaces itself with [unlocking].
  static const verifying = '/verifying';

  /// Follows [rentalSession] while the bay unlocks, then replaces itself
  /// with [release].
  static const unlocking = '/unlocking';

  /// The bay is open; "خدتها" starts the rental and opens [rental].
  static const release = '/release';

  /// Problem report, from /rental and /return; send pops back.
  static const report = '/report';

  /// How to return the unit; the debug-only simulate link opens [returnDone].
  static const returnUnit = '/return';

  /// The unit is back; its button replaces it with [receipt].
  static const returnDone = '/return/done';

  /// "تمام" resets [rentalSession] and goes home. With a [FinishedTrip] as
  /// `arguments` it shows that past trip and "تمام" pops back.
  static const receipt = '/receipt';

  /// Every station on a map or in a list. Takes a station code (String) as
  /// `arguments` to preselect on the map.
  static const stations = '/stations';

  /// Every station in a list by distance with filters (reference 108), from
  /// home's "كل المحطات"; "الخريطة" goes back.
  static const allStations = '/stations/all';

  /// Full-screen search from home's search field (reference 107). Pops with
  /// the picked [Station] or [MapPlace].
  static const search = '/search';

  /// Finished trips (رحلاتي tab).
  static const history = '/history';

  /// Amount and payment method. Takes the preselected amount (int) as
  /// `arguments`. The flow ends on [topupDone], which pops back to whatever
  /// opened /topup.
  static const topup = '/topup';

  /// Where to send the money, receipt photo, reference number. Takes a
  /// [TopupRequest] as `arguments` (default: 100 by Vodafone Cash).
  static const topupTransfer = '/topup/transfer';

  /// Mock review of a [TopupRequest]; replaces itself with [topupDone].
  static const topupPending = '/topup/pending';

  /// Balance counts up. Takes a [TopupReceipt] as `arguments`.
  static const topupDone = '/topup/done';

  /// Account screens, opened from /profile (and /plans from /wallet).
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/profile/edit';
  static const help = '/help';
  static const plans = '/plans';
  static const referral = '/referral';

  /// No connection (empty state); its link opens [offlineCode].
  static const offline = '/offline';

  /// Six-digit code for unlocking a bay without internet.
  static const offlineCode = '/offline-code';

  /// «إلحقني»: ask a friend to pay the first hour, from home's low-battery
  /// card and the low-balance sheet (open it with `openSos`). One a day.
  static const sos = '/sos';

  /// The friend's side: pay the first hour from the wallet, or not now.
  static const sosHelp = '/sos/help';

  /// The friend paid; "امسح وخد" opens [scan] and [confirm] says who paid.
  static const sosGot = '/sos/got';

  /// Home in exam week, whatever the debug toggle in /settings says.
  static const exam = '/exam';

  /// The running study-night pack, from the card on [exam] home.
  static const examNight = '/exam/night';

  /// Discount code ticket and the user's offers, from the wallet's "كود خصم".
  static const promo = '/promo';

  /// Trust level (new → regular → trusted), from /profile and the wallet
  /// card's level badge.
  static const trust = '/trust';

  /// The active plan and this month's usage, from the wallet's "اشتراكي";
  /// "غيّر الباقة" opens [plans].
  static const subscription = '/subscription';

  /// Full-station guarantee and the once-a-term free emergency hour, both
  /// from /help.
  static const guarantee = '/guarantee';
  static const emergency = '/emergency';

  /// Last month as three story pages, from home's banner at the start of a
  /// month (or the debug toggle in /settings).
  static const wrapped = '/wrapped';

  /// Operations mode for the team running the stations, from the
  /// debug-only row in /settings. Its own bottom nav ([opsTabs]); the exit
  /// in its header goes back to [home].
  static const ops = '/ops';

  /// Tasks generated from the mock state, most urgent first.
  static const opsTasks = '/ops/tasks';

  /// One station's 8 bays (open, lock, transfer). Takes the station code
  /// (String) as `arguments`.
  static const opsStation = '/ops/station';

  /// Moving units between stations in 4 steps ([MockOps.rebalance]).
  static const opsRebalance = '/ops/rebalance';

  /// Bottom-nav tabs, in nav order. `null` = not built yet.
  static const List<String?> tabs = [home, history, wallet, profile];

  /// Ops bottom-nav tabs: today, tasks, stations, reports.
  static const List<String?> opsTabs = [ops, opsTasks, null, null];

  /// Scan to receipt: these share one fade + slight slide ([_flowRoute]).
  static const _rentalFlow = {
    scan, scanCode, scanMethods, scanNfc, reserve, reserved, station, confirm,
    verifying, unlocking, release, rental, rentalUnit, report, returnUnit,
    returnDone, receipt,
  };

  /// Top-up shown when a /topup/* route is opened directly.
  static const _defaultTopup = TopupRequest(amount: 100, method: TopupMethod.vodafoneCash);

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      home => const HomeScreen(),
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      signup => const SignupScreen(),
      verify => const VerifyCodeScreen(),
      splash => const SplashScreen(),
      permissions => const PermissionsScreen(),
      verifyUni => const VerifyUniScreen(),
      rental => const ActiveRentalScreen(),
      rentalUnit => const UnitScreen(),
      wallet => const WalletScreen(),
      profile => const ProfileScreen(),
      scan => const ScanScreen(),
      scanCode => const ScanCodeScreen(),
      scanMethods => const ScanMethodsScreen(),
      scanNfc => const ScanNfcScreen(),
      reserve => ReserveScreen(station: settings.arguments as Station?),
      reserved => const ReservedScreen(),
      station => StationScreen(code: settings.arguments as String?),
      stationInfo => StationInfoScreen(code: settings.arguments as String?),
      favorites => const FavoritesScreen(),
      confirm => switch (settings.arguments) {
          (Station s, int bay) => ConfirmScreen(station: s, bayIndex: bay),
          _ => ConfirmScreen(
              station: Repos.stations.all.first,
              bayIndex: Repos.stations.all.first.bestBayIndex!,
            ),
        },
      verifying => switch (settings.arguments) {
          (Station s, int bay) => VerifyingScreen(station: s, bayIndex: bay),
          _ => VerifyingScreen(
              station: Repos.stations.all.first,
              bayIndex: Repos.stations.all.first.bestBayIndex!,
            ),
        },
      unlocking => const UnlockingScreen(),
      release => const ReleaseScreen(),
      report => const ReportScreen(),
      returnUnit => const ReturnScreen(),
      returnDone => const ReturnDoneScreen(),
      receipt => ReceiptScreen(trip: settings.arguments as FinishedTrip?),
      stations => StationsScreen(selectCode: settings.arguments as String?),
      allStations => const AllStationsScreen(),
      search => const SearchScreen(),
      history => const HistoryScreen(),
      topup => TopupScreen(amount: settings.arguments as int?),
      topupTransfer => TransferScreen(request: settings.arguments as TopupRequest? ?? _defaultTopup),
      topupPending => TopupPendingScreen(request: settings.arguments as TopupRequest? ?? _defaultTopup),
      topupDone => TopupDoneScreen(
          receipt: settings.arguments as TopupReceipt? ??
              TopupReceipt(
                request: _defaultTopup,
                before: rentalSession.balance,
                after: rentalSession.balance + _defaultTopup.amount,
              ),
        ),
      notifications => const NotificationsScreen(),
      AppRoutes.settings => const SettingsScreen(),
      editProfile => const EditProfileScreen(),
      help => const HelpScreen(),
      plans => const PlansScreen(),
      referral => const ReferralScreen(),
      offline => const NoInternetScreen(),
      offlineCode => const OfflineCodeScreen(),
      sos => const SosScreen(),
      sosHelp => const SosHelpScreen(),
      sosGot => const SosGotScreen(),
      exam => const HomeScreen(exam: true),
      examNight => const ExamNightScreen(),
      promo => const PromoScreen(),
      trust => const TrustScreen(),
      subscription => const SubscriptionScreen(),
      guarantee => const GuaranteeScreen(),
      emergency => const EmergencyScreen(),
      wrapped => const WrappedScreen(),
      ops => const OpsHomeScreen(),
      opsTasks => const OpsTasksScreen(),
      opsStation => OpsStationScreen(code: settings.arguments as String?),
      opsRebalance => const OpsRebalanceScreen(),
      _ => null,
    };
    if (page == null) return null;
    // Switching tabs is instant, like a tab bar; everything else slides.
    if (tabs.contains(settings.name) || opsTabs.contains(settings.name)) {
      return PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (_, _, _) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }
    if (_rentalFlow.contains(settings.name)) return _flowRoute(settings, page);
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  /// Fade in while rising 4% of the screen; instant under reduced motion.
  static Route<void> _flowRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: BunoMotion.slow,
      reverseTransitionDuration: BunoMotion.base,
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        final curved = CurvedAnimation(parent: animation, curve: BunoMotion.easing);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Bottom-nav handler shared by the tab screens.
  static void goToTab(BuildContext context, int index, int current) =>
      _goToTab(context, tabs, index, current);

  /// Bottom-nav handler of the ops tab screens.
  static void goToOpsTab(BuildContext context, int index, int current) =>
      _goToTab(context, opsTabs, index, current);

  /// Leaves operations mode for the app's home, clearing the back stack.
  static void leaveOps(BuildContext context) => enterApp(context);

  static void _goToTab(BuildContext context, List<String?> tabs, int index, int current) {
    if (index == current) return;
    final name = tabs[index];
    if (name == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(tr('الشاشة دي هتكون جاهزة قريب', 'This screen is coming soon')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    Navigator.of(context).pushReplacementNamed(name);
  }

  /// Leaves the auth flow for the app, clearing the back stack.
  static void enterApp(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(home, (_) => false);
}
