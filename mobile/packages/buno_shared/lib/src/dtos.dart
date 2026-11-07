import 'rules.dart';

typedef Json = Map<String, Object?>;

/// A station as the API sends it. [bays] holds each bay's charge in
/// percent, or null when the bay is empty.
class StationDto {
  const StationDto({
    required this.id,
    required this.code,
    required this.name,
    required this.walkMinutes,
    required this.bays,
  });

  factory StationDto.fromJson(Json j) => StationDto(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        walkMinutes: j['walkMinutes'] as int,
        bays: List<int?>.from(j['bays'] as List),
      );

  final String id;
  final String code;
  final String name;
  final int walkMinutes;
  final List<int?> bays;

  int get readyCount => bays.where((b) => (b ?? -1) >= minReadyCharge).length;
  int get emptyCount => bays.where((b) => b == null).length;

  Json toJson() => {'id': id, 'code': code, 'name': name, 'walkMinutes': walkMinutes, 'bays': bays};
}

class VerifyCodeRequest {
  const VerifyCodeRequest({required this.email, required this.code});

  factory VerifyCodeRequest.fromJson(Json j) =>
      VerifyCodeRequest(email: j['email'] as String, code: j['code'] as String);

  final String email;
  final String code;

  Json toJson() => {'email': email, 'code': code};
}

class SessionDto {
  const SessionDto({required this.token, required this.userId});

  factory SessionDto.fromJson(Json j) => SessionDto(token: j['token'] as String, userId: j['userId'] as String);

  final String token;
  final String userId;

  Json toJson() => {'token': token, 'userId': userId};
}

class WalletDto {
  const WalletDto({required this.balance});

  factory WalletDto.fromJson(Json j) => WalletDto(balance: (j['balance'] as num).toDouble());

  /// EGP.
  final double balance;

  Json toJson() => {'balance': balance};
}

/// Body of `POST /v1/rentals`: which bay to unlock. The return body has the
/// same shape (where the unit went back).
class BayRequest {
  const BayRequest({required this.stationCode, required this.bay});

  factory BayRequest.fromJson(Json j) => BayRequest(stationCode: j['stationCode'] as String, bay: j['bay'] as int);

  final String stationCode;

  /// 0-based bay index.
  final int bay;

  Json toJson() => {'stationCode': stationCode, 'bay': bay};
}

enum RentalStatus { active, returned }

class RentalDto {
  const RentalDto({
    required this.id,
    required this.stationCode,
    required this.bay,
    required this.unitCharge,
    required this.startedAt,
    required this.status,
    this.returnStationCode,
    this.endedAt,
  });

  factory RentalDto.fromJson(Json j) => RentalDto(
        id: j['id'] as String,
        stationCode: j['stationCode'] as String,
        bay: j['bay'] as int,
        unitCharge: j['unitCharge'] as int,
        startedAt: DateTime.parse(j['startedAt'] as String),
        status: RentalStatus.values.byName(j['status'] as String),
        returnStationCode: j['returnStationCode'] as String?,
        endedAt: j['endedAt'] == null ? null : DateTime.parse(j['endedAt'] as String),
      );

  final String id;
  final String stationCode;
  final int bay;
  final int unitCharge;
  final DateTime startedAt;
  final RentalStatus status;
  final String? returnStationCode;
  final DateTime? endedAt;

  Json toJson() => {
        'id': id,
        'stationCode': stationCode,
        'bay': bay,
        'unitCharge': unitCharge,
        'startedAt': startedAt.toIso8601String(),
        'status': status.name,
        'returnStationCode': returnStationCode,
        'endedAt': endedAt?.toIso8601String(),
      };
}

class PromoOfferDto {
  const PromoOfferDto({required this.title, required this.source, this.expired = false});

  factory PromoOfferDto.fromJson(Json j) => PromoOfferDto(
        title: j['title'] as String,
        source: j['source'] as String,
        expired: j['expired'] as bool? ?? false,
      );

  final String title;
  final String source;
  final bool expired;

  Json toJson() => {'title': title, 'source': source, 'expired': expired};
}

/// Error codes the server returns as `{"error": "<name>"}`.
enum ApiError {
  badRequest,
  unauthorized,
  notFound,
  invalidCode,
  codeAlreadyUsed,
  alreadyRenting,
  noActiveRental,
  bayNotReady,
  bayNotEmpty,
  lowBalance,
}
