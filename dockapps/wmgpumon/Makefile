PROG    = wmgpumon
CC      = gcc
CFLAGS  = -Wall -O2 $(shell pkg-config --cflags xft)
LIBS    = $(shell pkg-config --libs xft) -lX11 -lXext -lXpm

PREFIX  = /usr/local
BINDIR  = $(PREFIX)/bin

$(PROG): wmgpumon.c
	$(CC) $(CFLAGS) wmgpumon.c -o $(PROG) $(LIBS)

install: $(PROG)
	install -m 755 $(PROG) $(BINDIR)

uninstall:
	rm -f $(BINDIR)/$(PROG)

clean:
	rm -f $(PROG)

.PHONY: install uninstall clean
