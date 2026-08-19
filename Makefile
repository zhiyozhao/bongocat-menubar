# BongoCat Menubar — pure-Swift menu bar app, built with swiftc (no Xcode project).

APP_NAME      := BongoCat Menubar
MIN_MACOS     := 13.0

CONFIG        ?= debug
ARCHS         ?= $(shell uname -m)

# Signing identity. "-" = ad-hoc (TCC/Accessibility permission is re-requested
# after every update). If the "BongoCat Menubar Development" certificate exists
# in the keychain (see scripts/create-signing-identity.sh) it is used
# automatically, so Accessibility permission survives upgrades.
IDENTITY_NAME := BongoCat Menubar Development
SIGNING_IDENTITY ?= $(shell security find-certificate -c "$(IDENTITY_NAME)" >/dev/null 2>&1 && echo "$(IDENTITY_NAME)" || echo "-")

BUILD_DIR     := .build/$(CONFIG)
APP_BUNDLE    := $(BUILD_DIR)/$(APP_NAME).app
BINARY        := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
# make cannot handle the space in the bundle path as a target name,
# so incremental builds are tracked via this stamp file instead.
STAMP         := $(BUILD_DIR)/.build-stamp

SOURCES       := $(sort $(wildcard Sources/*.swift))
ICONS         := $(wildcard Resources/Icons/*)
LPROJS        := $(wildcard Resources/*.lproj)
APPICON       := Resources/AppIcon.icns

# Version: latest git tag (v1.2.3 -> 1.2.3), falling back to Info.plist.
VERSION       := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
ifeq ($(VERSION),)
VERSION       := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
endif
BUILD_NUMBER  := $(shell git rev-list --count HEAD 2>/dev/null || echo 1)

ifeq ($(CONFIG),release)
SWIFTFLAGS    := -O -whole-module-optimization
else
SWIFTFLAGS    := -Onone -g
endif

.PHONY: all build run icon dmg clean help

all: build

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-8s %s\n", $$1, $$2}'

build: $(STAMP) ## Build and sign the .app bundle

$(STAMP): $(SOURCES) Info.plist $(ICONS) $(LPROJS) $(APPICON)
	@echo "==> Assembling $(APP_NAME).app ($(CONFIG), $(ARCHS), v$(VERSION)+$(BUILD_NUMBER))"
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources"
	@cp Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" "$(APP_BUNDLE)/Contents/Info.plist"
	@/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(BUILD_NUMBER)" "$(APP_BUNDLE)/Contents/Info.plist"
	@cp Resources/Icons/* "$(APP_BUNDLE)/Contents/Resources/"
	@for lproj in Resources/*.lproj; do cp -R "$$lproj" "$(APP_BUNDLE)/Contents/Resources/"; done
	@cp "$(APPICON)" "$(APP_BUNDLE)/Contents/Resources/"
	@echo "==> Compiling $(SOURCES)"
	@if [ $(words $(ARCHS)) -gt 1 ]; then \
		for arch in $(ARCHS); do \
			swiftc $(SWIFTFLAGS) -target $$arch-apple-macosx$(MIN_MACOS) \
				-framework AppKit -framework ApplicationServices \
				-framework CoreGraphics -framework ServiceManagement \
				-o "$(BUILD_DIR)/$(APP_NAME)-$$arch" $(SOURCES); \
		done; \
		lipo -create -output "$(BINARY)" $(foreach arch,$(ARCHS),"$(BUILD_DIR)/$(APP_NAME)-$(arch)"); \
		rm $(foreach arch,$(ARCHS),"$(BUILD_DIR)/$(APP_NAME)-$(arch)"); \
	else \
		swiftc $(SWIFTFLAGS) -target $(ARCHS)-apple-macosx$(MIN_MACOS) \
			-framework AppKit -framework ApplicationServices \
			-framework CoreGraphics -framework ServiceManagement \
			-o "$(BINARY)" $(SOURCES); \
	fi
	@echo "==> Signing ($(SIGNING_IDENTITY))"
	@codesign --force --deep --sign "$(SIGNING_IDENTITY)" "$(APP_BUNDLE)"
	@touch "$(STAMP)"
	@echo "==> Done: $(APP_BUNDLE)"

run: build ## Build, then launch the app
	@open "$(APP_BUNDLE)"

icon: ## Generate Resources/AppIcon.icns from the cat artwork
	@swift scripts/generate-icon.swift

$(APPICON):
	@$(MAKE) --no-print-directory icon

dmg: ## Build a release DMG (universal binary)
	@$(MAKE) --no-print-directory build CONFIG=release ARCHS="arm64 x86_64"
	@echo "==> Creating DMG"
	@rm -f ".build/release/BongoCat-Menubar-v$(VERSION).dmg"
	@hdiutil create -volname "$(APP_NAME)" -srcfolder ".build/release/$(APP_NAME).app" \
		-ov -format UDZO ".build/release/BongoCat-Menubar-v$(VERSION).dmg" >/dev/null
	@echo "==> Done: .build/release/BongoCat-Menubar-v$(VERSION).dmg"

clean: ## Remove all build artifacts
	@rm -rf .build
	@echo "==> Cleaned"
