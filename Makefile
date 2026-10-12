PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
FILES  := yt yt-fmt yt-thumb-preview

.PHONY: install uninstall test lint

install:
	@mkdir -p $(BINDIR)
	@for f in $(FILES); do install -m 755 bin/$$f $(BINDIR)/$$f; done
	@echo "yt installed in $(BINDIR)"

uninstall:
	@for f in $(FILES); do rm -f $(BINDIR)/$$f; done
	@echo "yt removed from $(BINDIR)"

test:
	@bash tests/smoke.sh

lint:
	@shellcheck -x bin/yt bin/yt-thumb-preview install.sh tests/smoke.sh
	@python3 -m py_compile bin/yt-fmt
