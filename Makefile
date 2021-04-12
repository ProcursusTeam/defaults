.PHONY: clean all

CC_MAC := xcrun --sdk macosx clang
CC_IOS := xcrun --sdk iphoneos clang -miphoneos-version-min=10.0
CFLAGS := -O2 -arch arm64 -fobjc-arc
LIBS   := -framework Foundation
SIGN   := ldid -Sent.plist

clean:
	rm -rf bin/

ios:
	$(CC_IOS) $(CFLAGS) Sources/defaults.m -o bin/defaults $(LIBS)
	$(SIGN) bin/defaults

macos:
	$(CC_MAC) $(CFLAGS) Sources/defaults.m -o bin/defaults $(LIBS)