class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  Map<String, String> toMap() => {
        'userId': userId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory AuthSession.fromMap(Map<String, String> map) => AuthSession(
        userId: map['userId'] ?? '',
        accessToken: map['accessToken'] ?? '',
        refreshToken: map['refreshToken'] ?? '',
        expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
