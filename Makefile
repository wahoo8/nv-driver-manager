PACKAGE := nvidia-driver-manager

.PHONY: all build clean shellcheck lint

all:
	@true

build:
	@true

clean:
	@true

shellcheck:
	@if [ -d src ] || [ -d lib ]; then \
		find src lib -type f -exec shellcheck {} + 2>/dev/null || true; \
	else \
		echo "No src/ or lib/ directories yet."; \
	fi

lint:
	lintian ../$(PACKAGE)_*.changes
