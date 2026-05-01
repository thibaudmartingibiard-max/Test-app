# QuickFinder — Makefile
# Cibles: build, run, clean, install
#
# build    : compile en mode release
# run      : compile puis exécute le binaire (l'app apparaît dans la barre de menu)
# clean    : supprime le dossier .build
# install  : copie le binaire dans /Applications/QuickFinder.app

APP_NAME := QuickFinder
BUILD_DIR := .build/release
BINARY := $(BUILD_DIR)/$(APP_NAME)
APP_BUNDLE := /Applications/$(APP_NAME).app

.PHONY: build run clean install uninstall

build:
	swift build -c release

run: build
	$(BINARY)

clean:
	swift package clean
	rm -rf .build

install: build
	@echo "Création du bundle .app dans $(APP_BUNDLE)"
	rm -rf "$(APP_BUNDLE)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$(BINARY)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "Installé. Lancer avec: open $(APP_BUNDLE)"

uninstall:
	rm -rf "$(APP_BUNDLE)"
