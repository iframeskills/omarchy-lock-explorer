test:
	node --test tests/
	python3 tests/qml-syntax-report.test.py

.PHONY: test
