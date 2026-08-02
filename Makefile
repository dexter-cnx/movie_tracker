FLUTTER ?= flutter
DART ?= dart

.PHONY: help get clean format format-check analyze test test-unit test-widget integration golden golden-update coverage check ci

help:
	@echo "Available targets:"
	@echo "  make get            - Install Flutter dependencies"
	@echo "  make clean          - Clean Flutter build artifacts"
	@echo "  make format         - Format lib/, test/, and integration_test/"
	@echo "  make format-check   - Verify formatting without changing files"
	@echo "  make analyze        - Run static analysis"
	@echo "  make test           - Run the full host test suite"
	@echo "  make test-unit      - Run non-widget unit tests"
	@echo "  make test-widget    - Run widget tests"
	@echo "  make integration DEVICE=<id> - Run integration tests on a device"
	@echo "  make golden         - Run golden tests against committed baselines"
	@echo "  make golden-update  - Generate/update golden baseline images"
	@echo "  make coverage       - Run tests with coverage output"
	@echo "  make check          - Format check + analyze + host tests"
	@echo "  make ci             - Alias for make check"

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
	$(FLUTTER) test test/core test/features/movies test/features/watchlist test/features/profile test/localization

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

check: format-check analyze test

ci: check
