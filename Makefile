# Makefile for building the thesis

###
# Configuration
###

# Change these variables according to needs

# Set name of main latex file
MAIN = main
# Set dependencies
DEPENDENCIES = diss.tex chapters/*.tex preface/*.tex appendix/*.tex packages.tex commands.tex macros.tex literature.bib own_publications.bib style/*.sty style/*.tex
# Set name of output directory
OUT_DIR = output
# Set name of resulting file
NAME = dissertation
# Set additional directory which must be created in the output directory
# Tikz extern must coincide with directory given in macros.tex
ADD_DIRS = tikz_extern,chapters,preface,appendix
# Set folder for copy operation
COPY_DIR = ~/sync
# Set style file for index
INDEX_STYLE = style/index.ist


# Helper variables

# Main files and directories for specific builds
MAIN_CURRENT = $(MAIN)_current
DIR_CURRENT = $(OUT_DIR)/current
MAIN_COMPLETE = $(MAIN)_complete
DIR_COMPLETE = $(OUT_DIR)/complete
MAIN_CONTINUOUS = $(MAIN)_complete
DIR_CONTINUOUS = $(OUT_DIR)/continuous
MAIN_DEBUG = $(MAIN)_debug
DIR_DEBUG = $(OUT_DIR)/debug

# Possible tools
LUALATEX = lualatex --file-line-error --halt-on-error --shell-escape
LTX2ANY = ltx2any -e lualatex
LATEXMK = latexmk -pdf -lualatex --file-line-error -halt-on-error -logfilewarninglist -latexoption="--shell-escape"
BIB = biber

# Set open command depending on OS
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	OPEN = xdg-open
endif
ifeq ($(UNAME), Darwin)
	OPEN = open
endif


# General targets
.PHONY: default complete current debug clean all

default: current

all: complete current debug


###
# Build complete thesis (thesis.pdf)
###
# Specify tool to use
complete: latexmk

# Commands for specific tools
latexmk: $(MAIN_COMPLETE).tex $(DEPENDENCIES)
	mkdir -p $(DIR_COMPLETE)/{$(ADD_DIRS)}
	$(LATEXMK) -output-directory=$(DIR_COMPLETE) $(MAIN_COMPLETE)
	cp $(DIR_COMPLETE)/$(MAIN_COMPLETE).pdf $(OUT_DIR)/$(NAME).pdf

lualatex: $(MAIN_COMPLETE).tex $(DEPENDENCIES)
	mkdir -p $(DIR_COMPLETE)/{$(ADD_DIRS)}
	$(LUALATEX) --output-directory=$(DIR_COMPLETE) --draftmode $(MAIN_COMPLETE)
	$(BIB) --output-directory $(DIR_COMPLETE) $(MAIN_COMPLETE)
	makeindex -d $(DIR_COMPLETE) -s $(INDEX_STYLE) $(MAIN_COMPLETE)
	makeglossaries -d $(DIR_COMPLETE) $(MAIN_COMPLETE)
	$(LUALATEX) --output-directory=$(DIR_COMPLETE) --draftmode $(MAIN_COMPLETE)
	$(LUALATEX) --output-directory=$(DIR_COMPLETE) $(MAIN_COMPLETE)
	cp $(DIR_COMPLETE)/$(MAIN_COMPLETE).pdf $(OUT_DIR)/$(NAME).pdf

ltx2any: $(MAIN_COMPLETE).tex $(DEPENDENCIES)
	mkdir -p $(DIR_COMPLETE)/{$(ADD_DIRS)}
	$(LTX2ANY) -t $(DIR_COMPLETE) $(MAIN_COMPLETE)
	mv $(MAIN_COMPLETE).log.md $(DIR_COMPLETE)
	mv $(MAIN_COMPLETE).pdf $(OUT_DIR)/$(NAME).pdf


# Continuous
continuous: $(MAIN_COMPLETE).tex $(DEPENDENCIES)
	mkdir -p $(DIR_CONTINUOUS)/{$(ADD_DIRS)}
	$(LATEXMK) -output-directory=$(DIR_CONTINUOUS) -pvc $(MAIN_CONTINUOUS)


###
# Special build configurations
###

# Only for current use
current: $(MAIN_CURRENT).tex $(DEPENDENCIES)
	mkdir -p $(DIR_CURRENT)/{$(ADD_DIRS)}
	$(LATEXMK) -output-directory=$(DIR_CURRENT) $(MAIN_CURRENT)
	cp $(DIR_CURRENT)/$(MAIN_CURRENT).pdf $(DIR_CURRENT)/$(MAIN_CURRENT)2.pdf

# Only perform one build path for quicker compilation
# also disable index, etc.
current_lualatex: $(MAIN_CURRENT).tex $(DEPENDENCIES)
	mkdir -p $(DIR_CURRENT)/{$(ADD_DIRS)}
	$(LUALATEX) --output-directory=$(DIR_CURRENT) $(MAIN_CURRENT)
	cp $(DIR_CURRENT)/$(MAIN_CURRENT).pdf $(DIR_CURRENT)/$(MAIN_CURRENT)2.pdf

current_bib: $(MAIN_CURRENT).tex $(DEPENDENCIES)
	$(BIB) --output-directory $(DIR_CURRENT) $(MAIN_CURRENT)
	$(LUALATEX) --output-directory=$(DIR_CURRENT) $(MAIN_CURRENT)

# Build to debug
debug: $(MAIN_DEBUG).tex debug/*.tex $(DEPENDENCIES)
	mkdir -p $(DIR_DEBUG)/{$(ADD_DIRS),debug}
	$(LUALATEX) --output-directory=$(DIR_DEBUG) --draftmode $(MAIN_DEBUG)
	$(BIB) --output-directory $(DIR_DEBUG) --validate-datamodel $(MAIN_DEBUG)
	makeindex $(DIR_DEBUG)/$(MAIN_DEBUG) -s $(INDEX_STYLE)
	makeglossaries -d $(DIR_DEBUG) $(MAIN_DEBUG)
	$(LUALATEX) --output-directory=$(DIR_DEBUG) --draftmode $(MAIN_DEBUG)
	$(LUALATEX) --output-directory=$(DIR_DEBUG) $(MAIN_DEBUG)
	chktex $(MAIN_DEBUG).tex


###
# Helper functions
###

# Open pdf
open: current
	$(OPEN) $(DIR_CURRENT)/$(MAIN_CURRENT).pdf
open_complete: complete
	$(OPEN) $(DIR_COMPLETE)/$(MAIN_COMPLETE).pdf
open_debug: debug
	$(OPEN) $(DIR_DEBUG)/$(MAIN_DEBUG).pdf

# Copy pdf and sources
copy: copy_pdf copy_all

copy_pdf: complete
	cp $(OUT_DIR)/$(NAME).pdf $(COPY_DIR)/$(NAME)_`date +"%Y-%m-%d"`.pdf

copy_source:
	git archive --format zip --output $(COPY_DIR)/$(NAME)_source_`date +"%Y-%m-%d"`.zip master

copy_all:
	zip -q -r $(COPY_DIR)/$(NAME)_all_`date +"%Y-%m-%d"`.zip * -x "*.git"

# Clean
clean:
	@# Be careful to not remove from root
	@rm -r ./$(OUT_DIR)

clean_current:
	@rm -r ./$(DIR_CURRENT)

clean_complete:
	@rm -r ./$(DIR_COMPLETE)

clean_debug:
	@rm -r ./$(DIR_DEBUG)
