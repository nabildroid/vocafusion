import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final class AccessTokenModel extends Equatable {
  final String token;
  final String refreshToken;
  final DateTime expires;

  const AccessTokenModel({
    required this.token,
    required this.refreshToken,
    required this.expires,
  });

  bool get isExpired => DateTime.now().compareTo(expires) > 0;

  String toJson() {
    return jsonEncode({
      "token": token,
      "refreshToken": refreshToken,
      "expires": expires.toString(),
    } as Map<String, dynamic>);
  }

  factory AccessTokenModel.fromJson(String str) {
    final Map<String, dynamic> data = jsonDecode(str);
    return AccessTokenModel(
      expires: DateTime.parse(data["expires"]),
      refreshToken: data["refreshToken"],
      token: data["token"],
    );
  }

  AccessTokenModel refresh(String freshToken) {
    final Map<String, dynamic> data = JwtDecoder.decode(freshToken);

    return AccessTokenModel(
      expires: DateTime.fromMillisecondsSinceEpoch((data["exp"] * 1000)),
      refreshToken: refreshToken,
      token: freshToken,
    );
  }

  @override
  List<Object?> get props => [token];
}
