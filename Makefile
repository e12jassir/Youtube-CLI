PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall

install:
	@mkdir -p $(BINDIR)
	@install -m 755 bin/yt $(BINDIR)/yt
	@install -m 755 bin/yt-thumb-preview $(BINDIR)/yt-thumb-preview
	@echo "yt-cli instalado en $(BINDIR)"

uninstall:
	@rm -f $(BINDIR)/yt $(BINDIR)/yt-thumb-preview
	@echo "yt-cli desinstalado de $(BINDIR)"
