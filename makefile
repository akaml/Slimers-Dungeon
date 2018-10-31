VERSION=0.1.0
NAME=slimers
URL=https://akaml.itch.io/slimers-dungeon
AUTHOR=akaml
DESCRIPTION="roughlite-game"

LIBS := $(wildcard lib/*)
LUA := $(wildcard *.lua)
SRC := $(wildcard *.fnl)
OUT := $(patsubst %.fnl,%.lua,$(SRC))

LOVEFILE=releases/$(NAME)-$(VERSION).love

run: ; love $(PWD)

%.lua: %.fnl ; lua fennel --compile --correlate $< > $@
clean: ; rm -rf $(OUT)

$(LOVEFILE): $(LUA) $(OUT) $(LIBS)   assets
	mkdir -p releases/
	find $^ -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X $@ -@

love: $(LOVEFILE)

# platform-specific distributables

REL="/usr/local/bin/love-release" # https://p.hagelb.org/love-release.sh
FLAGS=-a "$(AUTHOR)" --description $(DESCRIPTION) -t "$(NAME)"\
	--love 11.1 --url $(URL) --version $(VERSION) --lovefile $(LOVEFILE) -L

releases/$(NAME)-$(VERSION)-x86_64.AppImage: $(LOVEFILE)
	cd appimage && ./build.sh 11.1 $(PWD)/$(LOVEFILE)
	mv appimage/game-x86_64.AppImage $@

releases/$(NAME)-$(VERSION)-macos.zip: $(LOVEFILE)
	$(REL) $(FLAGS) -M
	mv releases/slimers-macos.zip $@

releases/$(NAME)-$(VERSION)-win.zip: $(LOVEFILE)
	OUT="$(NAME)-$(VERSION).love" $(REL) $(FLAGS) -W32
	mv releases/slimers-win32.zip $@

linux: releases/$(NAME)-$(VERSION)-x86_64.AppImage
mac: releases/$(NAME)-$(VERSION)-macos.zip
windows: releases/$(NAME)-$(VERSION)-win.zip

#uploadlinux: releases/$(NAME)-$(VERSION)-x86_64.AppImage
#	butler push $^ technomancy/goo-runner:linux
#uploadmac: releases/$(NAME)-$(VERSION)-macos.zip
#	butler push $^ technomancy/goo-runner:mac
#uploadwindows: releases/$(NAME)-$(VERSION)-win.zip
#	butler push $^ technomancy/goo-runner:windows

#upload: uploadlinux uploadmac uploadwindows
