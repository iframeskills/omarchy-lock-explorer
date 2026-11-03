test:
	node --test tests/*.test.cjs
	python3 tests/qml-syntax-report.test.py

.PHONY: test
