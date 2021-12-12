CC      ?= xcrun cc
CFLAGS  ?= -O2
LDFLAGS ?= -O2

SRC := Sources/defaults.m Sources/write.m
SRC += Sources/helpers.m
SRC += Sources/NSData+HexString.m

all: defaults

defaults: $(SRC:%=%.o)
	$(CC) $(LDFLAGS) -o $@ $^ -framework CoreFoundation -fobjc-arc
	-ldid -Sent.plist $@

%.m.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $< -fobjc-arc

clean:
	rm -rf defaults defaults.dSYM $(SRC:%=%.o)

.PHONY: clean all
