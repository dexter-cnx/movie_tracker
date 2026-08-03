FLUTTER ?= flutter
DART ?= dart
COVERAGE_MIN ?= 55

.PHONY: help get clean format format-check analyze test test-unit test-widget integration golden golden-update coverage coverage-check check ci

help:
	@echo "Available targets:"
	@echo "  make get                       - Install Flutter dependencies"
	@echo "  make clean                     - Clean Flutter build artifacts"
	@echo "  make format                    - Format lib/, test/, and integration_test/"
	@echo "  make format-check              - Verify formatting without changing files"
	@echo "  make analyze                   - Run static analysis"
	@echo "  make test                      - Run the full host test suite"
	@echo "  make test-unit                 - Run unit tests by feature/core folder"
	@echo "  make test-widget               - Run widget tests"
	@echo "  make integration DEVICE=<id>   - Run integration tests on a device"
	@echo "  make golden                    - Run golden tests against committed baselines"
	@echo "  make golden-update             - Generate/update golden baseline images"
	@echo "  make coverage                  - Generate coverage/lcov.info"
	@echo "  make coverage-check            - Enforce line coverage threshold"
	@echo "  make check                     - Format check + analyze + host tests"
	@echo "  make ci                        - Full CI validation including coverage threshold"

get:
	$(FLUTTER) pub get

clean:
	$(FLUTTER) clean

format:
	$(DART) format lib test integration_test

format-check:
	$(DART) format --output=none --set-exit-if-changed lib test integration_test

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

test-unit:
	$(FLUTTER) test test/core test/features/movies test/features/watchlist test/features/profile test/features/auth test/features/search test/localization

test-widget:
	$(FLUTTER) test test/widgets

integration:
	@test -n "$(DEVICE)" || (echo "Usage: make integration DEVICE=<device-id>" && exit 1)
	$(FLUTTER) test integration_test -d $(DEVICE)

golden:
	$(FLUTTER) test --dart-define=RUN_GOLDENS=true test/goldens

golden-update:
	$(FLUTTER) test --dart-define=RUN_GOLDENS=true --update-goldens test/goldens

coverage:
	$(FLUTTER) test --coverage

coverage-check: coverage
	@awk -F: '/^LF:/{found+=$$2} /^LH:/{hit+=$$2} END { pct=(found==0?0:hit*100/found); printf "Line coverage: %.2f%% (minimum $(COVERAGE_MIN)%%)\n", pct; if (pct+0.0001 < $(COVERAGE_MIN)) exit 1 }' coverage/lcov.info

check: format-check analyze test

ci: format-check analyze coverage-check
