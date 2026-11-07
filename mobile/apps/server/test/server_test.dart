import 'dart:convert';

import 'package:buno_server/buno_server.dart';
import 'package:buno_shared/buno_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

late Handler _app;

Future<(int, Object?)> _call(String method, String path, {Object? body, String? token}) async {
  final res = await _app(Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body == null ? null : jsonEncode(body),
    headers: {if (token != null) 'authorization': 'Bearer $token'},
  ));
  final text = await res.readAsString();
  return (res.statusCode, text.isEmpty ? null : jsonDecode(text));
}

Future<String> _signIn([String email = 'student@uni.edu.eg']) async {
  final (_, body) = await _call('POST', ApiPaths.authVerify, body: {'email': email, 'code': '1234'});
  return SessionDto.fromJson(body! as Json).token;
}

void main() {
  setUp(() => _app = buildBunoServer(clock: () => DateTime.utc(2026, 11, 4, 10)));

  test('health', () async {
    final (status, body) = await _call('GET', ApiPaths.health);
    expect(status, 200);
    expect(body, {'status': 'ok'});
  });

  group('auth', () {
    test('any 4 digits sign in; anything else is refused', () async {
      expect((await _call('POST', ApiPaths.authSendCode, body: {'email': 'a@b.c'})).$1, 204);
      expect((await _call('POST', ApiPaths.authVerify, body: {'email': 'a@b.c', 'code': '12'})).$1, 401);
      expect((await _call('POST', ApiPaths.authVerify, body: {'email': 'a@b.c'})).$1, 400);
      expect(await _signIn(), startsWith('tok-'));
    });

    test('signed-in routes need a token', () async {
      final (status, body) = await _call('GET', ApiPaths.wallet);
      expect(status, 401);
      expect(body, {'error': 'unauthorized'});
      expect((await _call('GET', ApiPaths.wallet, token: 'nope')).$1, 401);
    });
  });

  test('stations: list and by code', () async {
    final (status, list) = await _call('GET', ApiPaths.stations);
    expect(status, 200);
    expect((list! as List).length, 4);
    final (_, one) = await _call('GET', ApiPaths.station('bun-01'));
    expect(StationDto.fromJson(one! as Json).readyCount, 4);
    expect((await _call('GET', ApiPaths.station('BUN-99'))).$1, 404);
  });

  test('wallet starts at the mock balance', () async {
    final (_, body) = await _call('GET', ApiPaths.wallet, token: await _signIn());
    expect(WalletDto.fromJson(body! as Json).balance, 50);
  });

  group('rentals', () {
    test('take a unit, then return it to another station', () async {
      final token = await _signIn();
      final (status, started) =
          await _call('POST', ApiPaths.rentals, token: token, body: const BayRequest(stationCode: 'BUN-01', bay: 0).toJson());
      expect(status, 201);
      final rental = RentalDto.fromJson(started! as Json);
      expect(rental.unitCharge, 92);

      final (_, station) = await _call('GET', ApiPaths.station('BUN-01'));
      expect(StationDto.fromJson(station! as Json).bays.first, isNull);

      expect((await _call('POST', ApiPaths.rentals, token: token, body: {'stationCode': 'BUN-01', 'bay': 1})).$2,
          {'error': 'alreadyRenting'});
      expect((await _call('GET', ApiPaths.currentRental, token: token)).$1, 200);

      final (_, done) = await _call('POST', ApiPaths.returnRental(rental.id),
          token: token, body: const BayRequest(stationCode: 'BUN-02', bay: 1).toJson());
      expect(RentalDto.fromJson(done! as Json).status, RentalStatus.returned);
      final (_, back) = await _call('GET', ApiPaths.station('BUN-02'));
      expect(StationDto.fromJson(back! as Json).bays[1], 92);
      expect((await _call('GET', ApiPaths.currentRental, token: token)).$1, 404);
    });

    test('a low or empty bay cannot be rented', () async {
      final token = await _signIn();
      expect((await _call('POST', ApiPaths.rentals, token: token, body: {'stationCode': 'BUN-01', 'bay': 2})).$2,
          {'error': 'bayNotReady'});
      expect((await _call('POST', ApiPaths.rentals, token: token, body: {'stationCode': 'BUN-01', 'bay': 4})).$2,
          {'error': 'bayNotReady'});
    });
  });

  test('promo: a code works once per user', () async {
    final token = await _signIn();
    final (_, before) = await _call('GET', ApiPaths.promoOffers, token: token);
    expect((await _call('POST', ApiPaths.promoRedeem, token: token, body: {'code': 'welcome30'})).$1, 201);
    expect((await _call('POST', ApiPaths.promoRedeem, token: token, body: {'code': 'WELCOME30'})).$2,
        {'error': 'codeAlreadyUsed'});
    expect((await _call('POST', ApiPaths.promoRedeem, token: token, body: {'code': 'NOPE'})).$2, {'error': 'invalidCode'});
    final (_, after) = await _call('GET', ApiPaths.promoOffers, token: token);
    expect((after! as List).length, (before! as List).length + 1);

    final other = await _signIn('other@uni.edu.eg');
    expect((await _call('POST', ApiPaths.promoRedeem, token: other, body: {'code': 'WELCOME30'})).$1, 201);
  });

  test('favorites: add, list, remove', () async {
    final token = await _signIn();
    expect((await _call('PUT', ApiPaths.favorite('BUN-04'), token: token)).$1, 204);
    expect((await _call('PUT', ApiPaths.favorite('BUN-99'), token: token)).$1, 404);
    final (_, list) = await _call('GET', ApiPaths.favorites, token: token);
    expect([for (final s in list! as List) (s as Json)['code']], ['BUN-04']);
    expect((await _call('DELETE', ApiPaths.favorite('bun-04'), token: token)).$1, 204);
    expect((await _call('GET', ApiPaths.favorites, token: token)).$2, isEmpty);
  });
}
