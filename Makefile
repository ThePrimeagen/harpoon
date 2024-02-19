fmt:
	echo "===> Formatting"
	stylua lua/ --config-path=.stylua.toml

lint:
	echo "===> Linting"
	luacheck lua/ --globals vim

test:
	echo "===> Testing"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
        -c "PlenaryBustedDirectory lua/harpoon/test/ {minimal_init = 'scripts/tests/minimal.vim'}"

.PHONY: doc
doc:
	echo "===> Generating docs"
	panvimdoc.sh \
		--description "Getting you where you want with the fewest keystrokes" \
		--input-file README.md --project-name harpoon --toc false
	nvim +"helptags doc | exit"


clean:
	echo "===> Cleaning"
	rm /tmp/lua_*

pr-ready: fmt lint test
