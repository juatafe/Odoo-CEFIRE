# Directori de les fonts i de la build
SOURCEDIR     = docs
BUILDDIR      = $(SOURCEDIR)/_build

# Activa l'entorn virtual
VENV = .venv/bin/activate

.PHONY: help html pdf clean serve

help:
	@echo "Ordres disponibles:"
	@echo "  make html   -> genera la documentació HTML"
	@echo "  make pdf    -> genera el PDF (LaTeX + Eisvogel si està configurat)"
	@echo "  make serve  -> compila i obri un servidor local"
	@echo "  make clean  -> neteja els _build"

html:
	. $(VENV) && sphinx-build -b html $(SOURCEDIR) $(BUILDDIR)/html

pdf:
	. $(VENV) && sphinx-build -b latex $(SOURCEDIR) $(BUILDDIR)/latex && \
	cd $(BUILDDIR)/latex && make all-pdf

serve: html
	cd $(BUILDDIR)/html && python3 -m http.server 8000

clean:
	rm -rf $(BUILDDIR)
