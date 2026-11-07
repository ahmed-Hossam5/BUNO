import 'package:flutter/foundation.dart';
import '../l10n/buno_locale.dart';

/// A friend the user can ask to pay their first hour («إلحقني»).
class SosFriend {
  const SosFriend({required this.id, required this._name, required this._note});

  final String id;
  final Tr _name;
  final Tr _note;

  String get name => _name.text;

  /// Under the name on /sos: how often they help, or when they last did.
  String get note => _note.text;

  /// First letter, shown in the avatar.
  String get initial => String.fromCharCode(name.runes.first);
}

/// Stand-in friends until contacts exist; the first is pre-selected.
const mockSosFriends = [
  SosFriend(id: 'fr-01', name: Tr('أحمد', 'Ahmed'), note: Tr('منتظم · قريب منك', 'Regular · near you')),
  SosFriend(id: 'fr-02', name: Tr('سارة', 'Sara'), note: Tr('آخر مرة امبارح', 'Last time yesterday')),
  SosFriend(id: 'fr-03', name: Tr('يوسف', 'Youssef'), note: Tr('آخر مرة من أسبوع', 'Last time a week ago')),
];

/// Who asks on the friend's side (/sos/help) and the charge they're at.
String get mockSosAsker => tr('محمد', 'Mohamed');
const mockSosAskerCharge = 2;

/// idle → waiting (sent, no answer yet) → paid (the friend covered the first
/// hour, until the next rental uses it).
enum SosState { idle, waiting, paid }

/// The user's «إلحقني» request. One per day: sending uses the day's request,
/// cancelling before an answer gives it back. Nothing is sent anywhere.
class SosSession extends ChangeNotifier {
  SosSession({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  SosState _state = SosState.idle;
  SosFriend? _friend;
  DateTime? _usedOn;

  SosState get state => _state;

  /// Asked friend while waiting; the one who paid once paid.
  SosFriend? get friend => _friend;

  /// Whether today's request is still free.
  bool get canSendToday {
    final used = _usedOn, now = _clock();
    return used == null || used.year != now.year || used.month != now.month || used.day != now.day;
  }

  /// The friend paying the next rental's first hour; null when none.
  SosFriend? get firstHourPaidBy => _state == SosState.paid ? _friend : null;

  /// Asks [friend]. Throws while a request is open or after today's.
  void send(SosFriend friend) {
    if (_state != SosState.idle) throw StateError('Request already open (state: $_state)');
    if (!canSendToday) throw StateError('Already asked today');
    _friend = friend;
    _usedOn = _clock();
    _state = SosState.waiting;
    notifyListeners();
  }

  /// Withdraws a request nobody answered; today's request is free again.
  void cancel() {
    if (_state != SosState.waiting) return;
    _friend = null;
    _usedOn = null;
    _state = SosState.idle;
    notifyListeners();
  }

  /// The asked friend paid (debug link on /sos until a backend exists).
  void markPaid() {
    if (_state != SosState.waiting) throw StateError('Nothing to pay (state: $_state)');
    _state = SosState.paid;
    notifyListeners();
  }

  /// The rental that the friend's payment covered has started.
  void useFirstHour() {
    if (_state != SosState.paid) return;
    _friend = null;
    _state = SosState.idle;
    notifyListeners();
  }

  /// Test only: forgets every request, including today's.
  @visibleForTesting
  void debugReset() {
    _friend = null;
    _usedOn = null;
    _state = SosState.idle;
    notifyListeners();
  }
}

/// The one request the screens read.
final sosSession = SosSession();
