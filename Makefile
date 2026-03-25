# Directori de les fonts i de la build
SOURCEDIR = docs
BUILDDIR  = _build

.PHONY: help html pdf clean serve sync-static

help:
	@echo "Ordres disponibles:"
	@echo "  make html   -> genera la documentació HTML"
	@echo "  make pdf    -> genera el PDF amb XeLaTeX"
	@echo "  make serve  -> compila i obri un servidor local"
	@echo "  make clean  -> neteja els _build"

sync-static:
	@mkdir -p docs/_static/scripts
	cp -f scripts/comptabilitat.sh docs/_static/scripts/comptabilitat.sh || true
	cp -f scripts/deploy-odoo-docker.sh docs/_static/scripts/deploy-odoo-docker.sh || true
	cp -f scripts/test-docker-installation.sh docs/_static/scripts/test-docker-installation.sh || true
	cp -f scripts/diagnostic.sh docs/_static/scripts/diagnostic.sh || true
	cp -f scripts/monitor.sh docs/_static/scripts/monitor.sh || true
	cp -f scripts/backup-docker.sh docs/_static/scripts/backup-docker.sh || true
	cp -f scripts/restore-docker.sh docs/_static/scripts/restore-docker.sh || true

html: sync-static
	sphinx-build -b html $(SOURCEDIR) $(BUILDDIR)/html

pdf: sync-static
	# 1. Genera el codi LaTeX
	sphinx-build -b latex $(SOURCEDIR) $(BUILDDIR)/latex
	# 2. Compila el PDF amb XeLaTeX
	-cd $(BUILDDIR)/latex && latexmk -pdf -xelatex -f -interaction=nonstopmode *.tex
	@echo "-------------------------------------------------------"
	@echo "Procés finalitzat. Revisa el PDF a:"
	@echo "$(BUILDDIR)/latex/Odoo-CEFIRE.pdf"
	@echo "-------------------------------------------------------"

serve: html
	cd $(BUILDDIR)/html && python3 -m http.server 8000

clean:
	rm -rf $(BUILDDIR)