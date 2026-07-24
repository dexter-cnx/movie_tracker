enum WatchStatus { wantToWatch, watched, favorite }

class WatchlistItem {
  const WatchlistItem({
    required this.id,
    required this.movieId,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.status,
    this.personalRating,
    required this.addedAt,
    this.watchedAt,
    this.notes,
    this.runtimeMinutes,
    this.genre,
  });

  final String id;
  final int movieId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final WatchStatus status;
  final double? personalRating;
  final DateTime addedAt;
  final DateTime? watchedAt;
  final String? notes;
  final int? runtimeMinutes;
  final String? genre;

  Map<String, dynamic> toMap() => {
        'id': id,
        'movieId': movieId,
        'title': title,
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'status': status.name,
        'personalRating': personalRating,
        'addedAt': addedAt.toIso8601String(),
        'watchedAt': watchedAt?.toIso8601String(),
        'notes': notes,
        'runtimeMinutes': runtimeMinutes,
        'genre': genre,
      };

  factory WatchlistItem.fromMap(Map<dynamic, dynamic> map) => WatchlistItem(
        id: map['id'] as String,
        movieId: map['movieId'] as int,
        title: map['title'] as String,
        posterPath: map['posterPath'] as String?,
        backdropPath: map['backdropPath'] as String?,
        status: WatchStatus.values.firstWhere((e) => e.name == map['status'],
            orElse: () => WatchStatus.wantToWatch),
        personalRating: (map['personalRating'] as num?)?.toDouble(),
        addedAt: DateTime.parse(map['addedAt'] as String),
        watchedAt: map['watchedAt'] == null
            ? null
            : DateTime.parse(map['watchedAt'] as String),
        notes: map['notes'] as String?,
        runtimeMinutes: map['runtimeMinutes'] as int?,
        genre: map['genre'] as String?,
      );
}
