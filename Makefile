# Directori de les fonts i de la build
SOURCEDIR = docs
BUILDDIR  = _build

.PHONY: help html pdf clean serve

help:
	@echo "Ordres disponibles:"
	@echo "  make html   -> genera la documentació HTML"
	@echo "  make pdf    -> genera el PDF amb XeLaTeX"
	@echo "  make serve  -> compila i obri un servidor local"
	@echo "  make clean  -> neteja els _build"

html:
	sphinx-build -b html $(SOURCEDIR) $(BUILDDIR)/html

pdf:
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