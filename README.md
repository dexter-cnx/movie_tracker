# Movie Tracker & Watchlist

**Popcorn - Movie Tracker & Watchlist** is a modern Flutter movie discovery and tracking application for searching movies, exploring trending content, managing a personal watchlist, recording watch history, and viewing detailed movie information.

The app uses **TMDB API** as its primary movie data source and includes a built-in **mock data fallback with 10 movies** so the application can still demonstrate its UI and core flows when TMDB is unavailable or when a bearer token has not been configured.

The current design direction is a **Cinematic Dark Minimal UI** inspired by the supplied reference image. The interface focuses on large movie artwork, dark surfaces, rounded posters, soft shadows, white pill-shaped actions, and minimal navigation so that movie content remains the visual focus.

---

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Architecture:** Clean Architecture + MVVM-style presentation layer
- **HTTP Client:** Dio
- **Rate Limit Handling:** Custom `RateLimitInterceptor` with retry support for HTTP 429
- **Local Storage:** Hive
- **Charts:** fl_chart
- **Localization:** easy_localization
- **Localization Source of Truth:** `assets/langs/langs.csv`
- **Environment Variables:** flutter_dotenv
- **Remote API:** TMDB API v3

---

## Core Features

### Home Dashboard

The Home screen provides a quick overview of the user's movie activity and current recommendations.

It includes:

- Welcome header
- Search bar
- Your Watch Stats
- Trending Now
- My Watchlist / Continue Watching
- Quick access to the main sections of the app

The **Your Watch Stats** section uses `fl_chart` to visualize movie watching activity.

Trending movie cards display information such as poster, title, rating, genre, and popularity. When the TMDB API cannot be reached, the app automatically falls back to local mock movie data.

### Movie Detail

The Movie Detail screen presents extended information about a selected movie, including:

- Large backdrop image
- Movie title
- Rating
- Release year
- Runtime
- Genre chips
- Localized overview
- Rating distribution chart
- Budget
- Revenue
- Vote count
- Original language
- Cast list
- Trailer
- Similar movies

Users can add a movie to the watchlist, mark it as watched, or mark it as a favorite.

The detail request is designed around TMDB's `append_to_response` support so credits, videos, and similar movies can be retrieved together with the main movie detail response.

### Watchlist / My List

The Watchlist feature manages the user's personal movie collection using Hive.

The main local model is:

```text
WatchlistItem
```

with fields such as:

```text
id
movieId
title
posterPath
backdropPath
status
personalRating
addedAt
watchedAt
```

Supported statuses include:

- Want to Watch
- Watched
- Favorite

When adding or editing a movie, the user can store status, personal rating, notes, and watched date.

The Watchlist section can also calculate personal statistics such as:

- Total movies watched
- Total watch hours
- Average personal rating
- Favorite genre

### Search & Discover

The Search and Discover experience allows users to explore the TMDB catalog.

Supported flows include:

- Movie search
- Genre filtering
- Trending movies
- Top Rated
- Upcoming
- Now Playing

The genre list is loaded from TMDB and can be used to filter discover results.

The app also includes **Movie Roulette**, a random movie picker that can optionally be filtered by genre.

### Release Calendar

The Release Calendar presents upcoming movie content in a schedule-inspired timeline.

The screen includes:

- Date selector
- Release timeline
- Movie cards
- Movie overview
- Cast avatars or production company information

The goal of this section is to make upcoming releases easier to scan in a calendar-like experience rather than presenting them as a standard movie grid.

---

## Architecture

The project follows a Clean Architecture approach with a MVVM-style presentation layer.

The general dependency flow is:

```text
UI
 ↓
ViewModel / Riverpod Provider
 ↓
Use Case
 ↓
Repository
 ↓
Remote / Local Data Source
 ↓
Dio / Hive
```

Typical project structure:

```text
lib/
├── core/
│   ├── network/
│   ├── theme/
│   └── constants/
│
├── features/
│   ├── movies/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── home/
│   ├── movie_detail/
│   ├── watchlist/
│   ├── search/
│   └── calendar/
│
├── shared/
│   └── widgets/
│
└── main.dart
```

### Layer Responsibilities

**Data**
- API models
- Remote data sources
- Local data sources
- Repository implementations

**Domain**
- Entities
- Repository contracts
- Use cases

**Presentation**
- Screens
- Widgets
- Riverpod providers
- ViewModel-style controllers

This separation keeps UI code independent from concrete API and local storage implementations.

---

## Network Layer

The project uses Dio as the HTTP client.

A custom `RateLimitInterceptor` handles TMDB rate-limit responses. When the API responds with:

```text
HTTP 429 Too Many Requests
```

the interceptor retries the request after a delay.

When available, the interceptor respects the `Retry-After` header. Otherwise, it falls back to a retry delay strategy.

The intended remote flow is:

```text
Presentation
   ↓
Provider / ViewModel
   ↓
Use Case
   ↓
Repository
   ↓
Remote Data Source
   ↓
Dio
   ↓
TMDB API
```

If the remote source fails:

```text
TMDB API
   ↓ error
Mock Data Fallback
   ↓
UI
```

This allows the demo application to remain usable even when the external API is unavailable.

---

## Local Storage

Hive is used for persistent local data such as:

- Watchlist
- Favorite movies
- Watched movies
- Watch history
- Personal ratings

Watchlist data is stored as JSON-compatible maps so the demo does not require generated Hive adapters.

This keeps the persistence layer lightweight while still preserving user data between app launches.

---

## Localization

`assets/langs/langs.csv` is the single source of truth for localization.

The app initially supports:

- English
- Thai

Example:

```csv
key,en,th
welcome,Welcome {name},ยินดีต้อนรับ {name}
searchHint,Search movie actor genre...,ค้นหาหนัง นักแสดง แนวหนัง...
watchStats,Your Watch Stats,สถิติการดูของคุณ
trendingNow,Trending Now,กำลังมาแรงตอนนี้
myWatchlist,My Watchlist,รายการของฉัน
```

UI strings are expected to use `.tr()`.

TMDB language mapping:

- English → `en-US`
- Thai → `th-TH`

The app also sends image and video language preferences where required.

Because CSV localization is loaded at runtime, malformed rows can cause startup failures. A recommended improvement is to add a CSV validation test and a safe localization fallback strategy before production deployment.

---

## UI / Design Direction

The current visual direction is **Cinematic Dark Minimal**.

Key characteristics:

- Dark background
- Dark surface cards
- White primary text
- Gray secondary text
- Rounded movie posters
- Large movie backdrops
- White pill-shaped primary actions
- Orange accent for ratings and highlights
- Minimal navigation
- Floating bottom navigation
- Soft shadows
- Subtle borders

The layout is designed so that posters, backdrops, and movie artwork remain the strongest visual elements.

---

## Environment Configuration

Create or update:

```text
assets/.env
```

and add your TMDB API Read Access Token:

```env
TMDB_BEARER_TOKEN=your_token_here
```

Do not commit a real production token to a public repository.

---

## Run

1. Install a compatible Flutter SDK.
2. Configure the TMDB bearer token in `assets/.env`.
3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

The app automatically falls back to 10 built-in mock movies when TMDB is unavailable or when no token is configured.

---

## Recommended Validation

Before submitting or releasing the project, run:

```bash
flutter analyze
flutter test
```

Recommended additional tests include:

- Localization CSV structure validation
- Repository fallback tests
- Dio 429 retry tests
- Hive watchlist persistence tests
- Riverpod provider / ViewModel tests
- Widget tests for Home, Search, Movie Detail, and Watchlist
- Golden tests for the main cinematic dark UI screens

---

## Notes

- 429 responses are retried by `RateLimitInterceptor`.
- Hive stores watchlist items as JSON-compatible maps.
- The project includes 10 mock movies as a fallback data source.
- The current generation environment did not include a Flutter SDK, so the project could not be compiled or analyzed there. Run `flutter analyze` and `flutter test` locally after `flutter pub get`.
- The current app is a demo foundation and can be extended with authentication, cloud sync, user profiles, notification reminders, and backend watch-history synchronization.
