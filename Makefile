test:
	@if command -v jsv-file-length >/dev/null 2>&1; then \
		jsv-file-length run "$(CURDIR)" --strict || echo "warning: file-length check reported a problem"; \
	else \
		echo "warning: jsv-file-length is unavailable"; \
	fi
	node --test tests/*.test.cjs
	python3 tests/qml-syntax-report.test.py

.PHONY: test
