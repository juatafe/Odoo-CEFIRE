FROM python:3.11-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    fontconfig \
    fonts-texgyre \
    texlive-xetex texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-european latexmk lmodern \
    inkscape imagemagick poppler-utils ghostscript \
    ca-certificates git curl \
 && fc-cache -f -v \
 && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
      sphinx \
      pydata-sphinx-theme \
      myst-parser \
      sphinx-design \
      sphinx-copybutton
      

WORKDIR /work
