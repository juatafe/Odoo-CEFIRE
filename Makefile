# Directori de les fonts i de la build
SOURCEDIR = docs
BUILDDIR  = _build

# Usa el venv del projecte si existeix (evita errors d'extensions no trobades)
PYTHON ?= python3
ifneq ("$(wildcard .venv/bin/python)","")
PYTHON := .venv/bin/python
endif

SPHINXBUILD = $(PYTHON) -m sphinx

.PHONY: help html pdf epub kindle clean serve sync-static

help:
	@echo "Ordres disponibles:"
	@echo "  make html   -> genera la documentació HTML"
	@echo "  make pdf    -> genera el PDF amb XeLaTeX"
	@echo "  make serve  -> compila i obri un servidor local"
	@echo "  make clean  -> neteja els _build"

sync-static:
	@mkdir -p docs/_static/scripts
	cp -f scripts/comptabilitat.sh docs/_static/scripts/comptabilitat.sh || true
	cp -f scripts/main.py docs/_static/scripts/main.py || true
	cp -f docs/_static/assets/scriptsetupodoo.sh docs/_static/scripts/scriptsetupodoo.sh || true
	cp -f scripts/deploy-odoo-docker.sh docs/_static/scripts/deploy-odoo-docker.sh || true
	cp -f scripts/test-docker-installation.sh docs/_static/scripts/test-docker-installation.sh || true
	cp -f scripts/diagnostic.sh docs/_static/scripts/diagnostic.sh || true
	cp -f scripts/monitor.sh docs/_static/scripts/monitor.sh || true
	cp -f scripts/backup-docker.sh docs/_static/scripts/backup-docker.sh || true
	cp -f scripts/restore-docker.sh docs/_static/scripts/restore-docker.sh || true

html: sync-static
	$(SPHINXBUILD) -b html $(SOURCEDIR) $(BUILDDIR)/html

pdf: sync-static
	# 1. Genera el codi LaTeX
	$(SPHINXBUILD) -b latex $(SOURCEDIR) $(BUILDDIR)/latex
	# 2. Compila el PDF amb XeLaTeX
	-cd $(BUILDDIR)/latex && latexmk -pdf -xelatex -f -interaction=nonstopmode *.tex
	@echo "-------------------------------------------------------"
	@echo "Procés finalitzat. Revisa el PDF a:"
	@echo "$(BUILDDIR)/latex/Odoo-CEFIRE.pdf"
	@echo "-------------------------------------------------------"
epub: sync-static
	$(SPHINXBUILD) -b epub $(SOURCEDIR) $(BUILDDIR)/epub
	@echo "ePub generat a: $(BUILDDIR)/epub/"

kindle: epub
	@command -v ebook-convert >/dev/null 2>&1 || { echo "ERROR: Calibre no trobat. Instal·la'l amb: sudo apt-get install calibre"; exit 1; }
	ebook-convert $(BUILDDIR)/epub/*.epub $(BUILDDIR)/epub/$(notdir $(BUILDDIR)/epub/*.epub:.epub=.mobi) \
		--output-profile kindle \
		--no-inline-toc \
		--title "$(project)" \
		--authors "$(author)"
	@echo "MOBI generat a: $(BUILDDIR)/epub/"
serve: html
	cd $(BUILDDIR)/html && $(PYTHON) -m http.server 8000

clean:
	rm -rf $(BUILDDIR)