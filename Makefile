.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .
	dprint fmt

.PHONY: lint
lint:
	typos -w

.PHONY: check
check: fmt lint
