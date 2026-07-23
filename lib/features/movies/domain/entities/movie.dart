class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.genreIds,
    this.popularity = 0,
    this.runtime,
    this.budget,
    this.revenue,
    this.voteCount,
    this.originalLanguage,
    this.genres = const [],
    this.cast = const [],
    this.trailerKey,
    this.similar = const [],
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final double voteAverage;
  final List<int> genreIds;
  final double popularity;
  final int? runtime;
  final int? budget;
  final int? revenue;
  final int? voteCount;
  final String? originalLanguage;
  final List<String> genres;
  final List<CastMember> cast;
  final String? trailerKey;
  final List<Movie> similar;

  int get releaseYear => int.tryParse(releaseDate.split('-').first) ?? 0;
}

class CastMember {
  const CastMember({required this.name, this.profilePath});
  final String name;
  final String? profilePath;
}
