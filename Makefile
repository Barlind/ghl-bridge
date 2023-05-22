prefix ?= /usr/cd /usrlocal
bindir = $(prefix)/bin
libdir = $(prefix)/lib

APP = ghl-bridge

build:
	swift build -c release --disable-sandbox

install: build
	install -d $(bindir)
	install ".build/release/$(APP)" $(bindir)

uninstall:
	rm -rf "$(bindir)/$(APP)"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
