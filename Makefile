# MakeFile for building all the docs at once.
# Inspired by the Makefile used by bazaar.
# http://bazaar.launchpad.net/~bzr-pqm/bzr/2.3/

PYTHON = python
ES_HOST =

.PHONY: all clean html website website-dirs rebuild-index build-html

# You can set these variables from the command line.
SOURCE := $(shell pwd)
DEST := ./website
LANG = en
INDEX_PREFIX =
ALLSPHINXOPTS = -d $(BUILD_DIR)/doctrees/$(LANG) -c ./ $(SPHINXOPTS) .

# Tool names
SPHINXBUILD = sphinx-build
PYTHON = python

# Languages that can be built.
LANGS = en

# Get path to theme directory to build static assets.
THEME_DIR = $(shell python -c 'import os, cakephpsphinx; print os.path.abspath(os.path.dirname(cakephpsphinx.__file__))')

# Temporary build output directory
BUILD_DIR = ./build


# Copy-paste the English Makefile everywhere it's needed (if non existing).
%/Makefile: en/Makefile
	cp -n $< $@

#
# The various formats the documentation can be created in.
#
# Loop over the possible languages and call other build targets.
#
html: $(foreach lang, $(LANGS), html-$(lang))
populate-index: $(foreach lang, $(LANGS), populate-index-$(lang))
server: $(foreach lang, $(LANGS), server-$(lang))
rebuild-index: $(foreach lang, $(LANGS), rebuild-index-$(lang))


# Make the HTML version of the documentation with correctly nested language folders.
html-%:
	make build-html LANG=$* SOURCE=$(SOURCE) DEST=$(DEST)
	make build/html/$*/_static/css/app.css SOURCE=$(SOURCE)
	make build/html/$*/_static/app.js SOURCE=$(SOURCE)

build-html:
	cd $(SOURCE)/$(LANG) && $(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(DEST)/html/$(LANG)
	@echo
	@echo "Build finished. The HTML pages are in $(DEST)/html/$(LANG)."

server-%:
	cd build/html/$* && python -m SimpleHTTPServer

populate-index-%:
	php scripts/populate_search_index.php $(INDEX_PREFIX) $* $(ES_HOST)

rebuild-index-%:
	curl -XDELETE $(ES_HOST)/documentation/$(INDEX_PREFIX)-$*
	php scripts/populate_search_index.php $(INDEX_PREFIX) $* $(ES_HOST)

website-dirs:
	# Make the directory if its not there already.
	[ ! -d $(DEST) ] && mkdir $(DEST) || true

	# Make the downloads directory
	[ ! -d $(DEST)/_downloads ] && mkdir $(DEST)/_downloads || true

	# Make downloads for each language
	$(foreach lang, $(LANGS), [ ! -d $(DEST)/_downloads/$(lang) ] && mkdir $(DEST)/_downloads/$(lang) || true;)

website: website-dirs html populate-index
	# Move HTML
	$(foreach lang, $(LANGS), cp -r build/html/$(lang) $(DEST)/$(lang);)

clean:
	rm -rf build/*

clean-website:
	rm -rf $(DEST)/*

build/html/%/_static:
	mkdir -p build/html/$*/_static

build/html/%/_static/css: build/html/%/_static
	mkdir -p build/html/$*/_static/css

CSS_FILES = $(THEME_DIR)/themes/cakephp/static/css/fonts.css \
  $(THEME_DIR)/themes/cakephp/static/css/bootstrap.min.css \
  $(THEME_DIR)/themes/cakephp/static/css/font-awesome.min.css \
  $(THEME_DIR)/themes/cakephp/static/css/style.css \
  $(THEME_DIR)/themes/cakephp/static/css/default.css \
  $(THEME_DIR)/themes/cakephp/static/css/pygments.css \
  $(THEME_DIR)/themes/cakephp/static/css/responsive.css

build/html/%/_static/css/app.css: build/html/%/_static/css $(CSS_FILES)
	# echo all dependencies ($$^) into the output ($$@)
	cat $(CSS_FILES) > $@

JS_FILES = $(THEME_DIR)/themes/cakephp/static/jquery.js \
  $(THEME_DIR)/themes/cakephp/static/vendor.js \
  $(THEME_DIR)/themes/cakephp/static/app.js \
  $(THEME_DIR)/themes/cakephp/static/search.js \
  $(THEME_DIR)/themes/cakephp/static/typeahead.js

build/html/%/_static/app.js: build/html/%/_static $(JS_FILES)
	# echo all dependencies ($JS_FILES) into the output ($$@)
	cat $(JS_FILES) > $@
