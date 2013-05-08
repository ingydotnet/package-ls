###
# This is a generic, reusable Makefile for Node.js/LiveScript projects,
# possibly using TestML.
###

# All the end-user targets are .PHONY:
.PHONY: init update build test clean purge help

# Include the project specific environment:
-include .env.mk

TARGET ?= npm
PACKAGE ?= ../package-ls
# TODO assert the PACKAGE dir exists.
TEMPLATE := $(PACKAGE)/template
TOOL := $(PACKAGE)/tool

# Define all the directories we'll need so we make pre-mkdir them:
ifdef SOURCE_TESTML
    TARGET_TESTML := test/testml
    TARGET_DIRS := $(TARGET_TESTML)
endif
TARGET_DIRS := \
	$(TARGET_DIRS) \
	$(shell find lib -mindepth 1 -type d) \
	$(shell find test -mindepth 1 -type d) \
	$(shell cd $(PACKAGE); find test -mindepth 1 -type d) \
	$(shell find doc -mindepth 0 -type d)
TARGET_DIRS := $(TARGET_DIRS:%=$(TARGET)/%)

# Find all the LiveScript code files and their JavaScript targets:
SOURCE_CODE := $(shell find lib -name *.ls)
TARGET_CODE := $(SOURCE_CODE:%.ls=$(TARGET)/%.js)

# Find all the local test files. Setup LS->JS conversions:
SOURCE_TEST := $(shell find test -type f) \
	$(shell cd $(PACKAGE); find test -type f)
TARGET_TEST := $(SOURCE_TEST:%=$(TARGET)/%)
TARGET_TEST := $(TARGET_TEST:$(TARGET)/test/lib/%.ls=$(TARGET)/test/lib/%.js)

# Setup the TestML environment (if we are using that):
ifdef SOURCE_TESTML
    SOURCE_TML_FILES ?= $(shell find $(SOURCE_TESTML) -name *.tml)
    TARGET_TML_FILES := $(SOURCE_TML_FILES:$(SOURCE_TESTML)/%=$(TARGET)/$(TARGET_TESTML)/%)
    TARGET_TML_TESTS ?= $(SOURCE_TML_FILES:$(SOURCE_TESTML)/%.tml=$(TARGET)/test/%.ls)
endif

# Gather the doc files:
SOURCE_DOCS := $(shell find doc -type f)
TARGET_DOCS := $(SOURCE_DOCS:%=$(TARGET)/%)

# Gather the other ancillary packaging files for an NPM package:
SOURCE_TEXT := $(shell cd $(TEMPLATE); echo LICENSE* README*)
TARGET_TEXT := $(SOURCE_TEXT:%=$(TARGET)/%)

# Define all the NPM package target files:
ALL := \
	$(TARGET_DIRS) \
	$(TARGET_CODE) \
	$(TARGET_TEST) \
	$(TARGET_TML_FILES) \
	$(TARGET_TML_TESTS) \
	$(TARGET_DOCS) \
	$(TARGET_TEXT) \
	$(TARGET)/package.json \
	$(TARGET)/Makefile \

# Define the Makefile targets that we support:
default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make init   - Initialize a new LiveScript project repo'
	@echo '    make update - Get project files up to date'
	@echo ''
	@echo '    make build  - Build the NPM package from sources'
	@echo '    make test   - Run the NPM tests'
	@echo ''
	@echo '    make clean  - Clean up'
	@echo '    make help   - Get Help'
	@echo ''

init: Makefile .gitignore

update: Makefile .gitignore

# Build the NPM package. (Simply *make* all of it's files!):
build: $(ALL)

# To test the package, `cd` into it and run `make test`:
test: build
	make -C $(TARGET) test

clean purge:
	rm -fr $(TARGET)

debug:
	@for d in $(ALL); do echo $$d; done
	# @echo MAKEFILE_LIST $(MAKEFILE_LIST)
	# @echo CURDIR $(CURDIR)


# These rules are where the action happens. Define what is needed in order to
# make a target NPM package file from its dependencies:
Makefile: $(PACKAGE)/Makefile
	ln -fs $< $@

.gitignore: $(PACKAGE)/gitignore
	ln -fs $< $@

$(TARGET_DIRS):
	mkdir -p $@

$(TARGET)/lib/%.js: lib/%.ls
	livescript --compile -p $< > $@

$(TARGET)/test/%.js: test/%.ls
	livescript --compile -p $< > $@

$(TARGET)/test/lib/%.js: $(PACKAGE)/test/lib/%.ls
	livescript --compile -p $< > $@

$(TARGET)/test/%: test/%
	cp $< $@

$(TARGET_TEXT):
	cp $(@:$(TARGET)/%=$(TEMPLATE)/%) $(TARGET)/$(@:$(TARGET)/%=%)

$(TARGET_DOCS):
	cp $(@:$(TARGET)/%=%) $(TARGET)/$(@:$(TARGET)/%=%)

$(TARGET)/package.json: package.yaml
	$(TOOL)/cdent-package-yaml-converter $< > $@

$(TARGET)/Makefile: $(PACKAGE)/npm.mk
	cp $< $@

$(TARGET)/test/%.ls: $(TEMPLATE)/testml.ls
	perl -pe 's/%NAME%/$(@:$(TARGET)/test/%.ls=%)/g' $< > $@

$(TARGET)/$(TARGET_TESTML)/%.tml: $(SOURCE_TESTML)/%.tml
	cp $< $@
