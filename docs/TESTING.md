# Testing Guide

The project test suite is organized by responsibility so failures are easier to isolate.

## Coverage

- `test/core/network/` — Dio rate-limit retry behavior.
- `test/features/movies/data/` — TMDB model mapping and repository fallback policies.
- `test/features/movies/presentation/` — locale mapping and provider argument equality.
- `test/features/watchlist/domain/` — watchlist serialization.
- `test/features/watchlist/data/` — Hive data-source behavior.
- `test/features/watchlist/presentation/` — Riverpod controller state refresh.
- `test/localization/` — CSV schema, empty values, and duplicate keys.
- `test/widgets/` — reusable UI widget behavior.
- `test/goldens/` — deterministic visual regression coverage for cinematic dark components.

## Common Commands

```bash
make get
make analyze
make test
make check
```

## Golden Tests

Golden tests are skipped during the default `make test` run so a fresh checkout does not fail before a platform-specific baseline has been generated.

Generate or refresh the baseline with:

```bash
make golden-update
```

Then commit the generated PNG under:

```text
test/goldens/goldens/
```

Run visual regression verification with:

```bash
make golden
```

Golden baselines should normally be generated on the same OS and Flutter version used by CI to minimize font-rasterization and rendering differences.

## Coverage Report

```bash
make coverage
```

This writes Flutter coverage output to:

```text
coverage/lcov.info
```

## CI Validation

Use:

```bash
make ci
```

This runs formatting validation, static analysis, and the standard test suite.
