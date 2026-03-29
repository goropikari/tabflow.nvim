.PHONY: nvim fmt lint test all

nvim:
	nvim -u $(CURDIR)/dev/init.lua

fmt:
	stylua -g '*.lua' -- .
	dprint fmt

lint:
	typos -w

test:
	@mkdir -p .tests/config .tests/data
	XDG_CONFIG_HOME=$(PWD)/.tests/config XDG_DATA_HOME=$(PWD)/.tests/data \
		nvim --headless --clean \
		-u tests/init.lua \
		-c "PlenaryBustedDirectory tests { post_write_delay = 0 }"
	@rm -rf .tests

all: fmt lint test
