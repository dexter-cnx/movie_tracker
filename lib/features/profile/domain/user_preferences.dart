class UserPreferences {
  const UserPreferences({
    this.displayName = 'Dexter',
    this.email = '',
    this.favoriteGenre = '',
    this.languageCode = 'en',
    this.notificationsEnabled = true,
    this.autoplayTrailers = false,
  });

  final String displayName;
  final String email;
  final String favoriteGenre;
  final String languageCode;
  final bool notificationsEnabled;
  final bool autoplayTrailers;

  UserPreferences copyWith({
    String? displayName,
    String? email,
    String? favoriteGenre,
    String? languageCode,
    bool? notificationsEnabled,
    bool? autoplayTrailers,
  }) {
    return UserPreferences(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoplayTrailers: autoplayTrailers ?? this.autoplayTrailers,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'favoriteGenre': favoriteGenre,
        'languageCode': languageCode,
        'notificationsEnabled': notificationsEnabled,
        'autoplayTrailers': autoplayTrailers,
      };

  factory UserPreferences.fromMap(Map<dynamic, dynamic> map) {
    return UserPreferences(
      displayName: (map['displayName'] as String?)?.trim().isNotEmpty == true
          ? map['displayName'] as String
          : 'Dexter',
      email: map['email'] as String? ?? '',
      favoriteGenre: map['favoriteGenre'] as String? ?? '',
      languageCode: map['languageCode'] == 'th' ? 'th' : 'en',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      autoplayTrailers: map['autoplayTrailers'] as bool? ?? false,
    );
  }
}
