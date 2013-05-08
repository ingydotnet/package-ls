###
# This is a generic, reusable Makefile for Node.js/LiveScript projects,
# possibly using TestML.
###

# All the end-user targets are .PHONY:
.PHONY: build test clean purge help

# Include the project specific environment:
-include .env.mk

PACKAGE ?= ../package-ls
# TODO assert the PACKAGE dir exists.
TEMPLATE := $(PACKAGE)/template
TOOL := $(PACKAGE)/tool
TARGET ?= npm

# Define all the directories we'll need so we make pre-mkdir them:
ifdef SRC_TESTML
    NPM_TESTML := test/testml
    NPM_DIRS := $(NPM_TESTML)
endif
NPM_DIRS := \
	$(NPM_DIRS) \
	$(shell find lib -mindepth 1 -type d) \
	$(shell find test -mindepth 1 -type d) \
	$(shell cd $(PACKAGE); find test -mindepth 1 -type d) \
	$(shell find doc -mindepth 0 -type d)
NPM_DIRS := $(NPM_DIRS:%=$(TARGET)/%)

# Find all the LiveScript code files and their JavaScript targets:
SRC_CODE := $(shell find lib -name *.ls)
NPM_CODE := $(SRC_CODE:%.ls=$(TARGET)/%.js)

# Find all the local test files. Setup LS->JS conversions:
SRC_TEST := $(shell find test -type f) \
	$(shell cd $(PACKAGE); find test -type f)
NPM_TEST := $(SRC_TEST:%=$(TARGET)/%)
NPM_TEST := $(NPM_TEST:$(TARGET)/test/lib/%.ls=$(TARGET)/test/lib/%.js)

# Setup the TestML environment (if we are using that):
ifdef SRC_TESTML
    SRC_TML_FILES ?= $(shell find $(SRC_TESTML) -name *.tml)
    NPM_TML_FILES := $(SRC_TML_FILES:$(SRC_TESTML)/%=$(TARGET)/$(NPM_TESTML)/%)
    NPM_TML_TESTS ?= $(SRC_TML_FILES:$(SRC_TESTML)/%.tml=$(TARGET)/test/%.ls)
endif

# Gather the doc files:
SRC_DOCS := $(shell find doc -type f)
NPM_DOCS := $(SRC_DOCS:%=$(TARGET)/%)

# Gather the other ancillary packaging files for an NPM package:
SRC_TEXT := $(shell cd $(TEMPLATE); echo LICENSE* README*)
NPM_TEXT := $(SRC_TEXT:%=$(TARGET)/%)

# Define all the NPM package target files:
ALL := \
	$(NPM_DIRS) \
	$(NPM_CODE) \
	$(NPM_TEST) \
	$(NPM_TML_FILES) \
	$(NPM_TML_TESTS) \
	$(NPM_DOCS) \
	$(NPM_TEXT) \
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
	@echo MAKEFILE_LIST $(MAKEFILE_LIST)
	@echo CURDIR $(CURDIR)


# These rules are where the action happens. Define what is needed in order to
# make a target NPM package file from its dependencies:
Makefile: $(PACKAGE)/Makefile
	ln -fs $< $@

.gitignore: $(PACKAGE)/gitignore
	ln -fs $< $@

$(NPM_DIRS):
	mkdir -p $@

$(TARGET)/lib/%.js: lib/%.ls
	livescript --compile -p $< > $@

$(TARGET)/test/%.js: test/%.ls
	livescript --compile -p $< > $@

$(TARGET)/test/lib/%.js: $(PACKAGE)/test/lib/%.ls
	livescript --compile -p $< > $@

$(TARGET)/test/%: test/%
	cp $< $@

$(NPM_TEXT):
	cp $(@:$(TARGET)/%=$(TEMPLATE)/%) $(TARGET)/$(@:$(TARGET)/%=%)

$(NPM_DOCS):
	cp $(@:$(TARGET)/%=%) $(TARGET)/$(@:$(TARGET)/%=%)

$(TARGET)/package.json: package.yaml
	$(TOOL)/cdent-package-yaml-converter $< > $@

$(TARGET)/Makefile: $(PACKAGE)/npm.mk
	cp $< $@

$(TARGET)/test/%.ls: $(TEMPLATE)/testml.ls
	perl -pe 's/%NAME%/$(@:$(TARGET)/test/%.ls=%)/g' $< > $@

.SECONDEXPANSION:
$(TARGET)/$(NPM_TESTML)/%.tml: $(SRC_TESTML)/%.tml
	cp $< $@
