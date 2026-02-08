# Directori de les fonts i de la build
SOURCEDIR     = docs
BUILDDIR      = _build

# Activa l'entorn virtual (ajusta la ruta si el teu .venv està en un altre lloc)
VENV = .venv/bin/activate

.PHONY: help html pdf clean serve

help:
	@echo "Ordres disponibles:"
	@echo "  make html   -> genera la documentació HTML"
	@echo "  make pdf    -> genera el PDF (optimitzat per a Amazon/XeLaTeX)"
	@echo "  make serve  -> compila i obri un servidor local"
	@echo "  make clean  -> neteja els _build"

html:
	. $(VENV) && sphinx-build -b html $(SOURCEDIR) $(BUILDDIR)/html

pdf:
	# 1. Genera el codi LaTeX
	. $(VENV) && sphinx-build -b latex $(SOURCEDIR) $(BUILDDIR)/latex
	# 2. Compila el PDF usant xelatex
	# El guionet '-' inicial evita que el Makefile s'ature pels warnings de caràcters de LaTeX
	-cd $(BUILDDIR)/latex && latexmk -pdf -xelatex -f -interaction=nonstopmode *.tex
	@echo "-------------------------------------------------------"
	@echo "Procés finalitzat. Revisa el PDF a:"
	@echo "$(BUILDDIR)/latex/sistemes-de-gestio-empresarial.pdf"
	@echo "-------------------------------------------------------"

serve: html
	cd $(BUILDDIR)/html && python3 -m http.server 8000

clean:
	rm -rf $(BUILDDIR)