.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .
	dprint fmt

.PHONY: lint
lint:
	typos -w

.PHONY: test
test:
	@mkdir -p .tests/config .tests/data
	XDG_CONFIG_HOME=$(PWD)/.tests/config XDG_DATA_HOME=$(PWD)/.tests/data \
		nvim --headless --clean \
		-u tests/init.lua \
		-c "PlenaryBustedDirectory tests { post_write_delay = 0 }"
	@rm -rf .tests

.PHONY: all
all: fmt lint test
