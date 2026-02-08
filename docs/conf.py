import os
import sys
import re
sys.path.append(os.path.abspath("."))
sys.path.append(os.path.abspath("./_ext"))


# ──────────────── Projecte ────────────────
project = "Sistemes de Gestió Empresarial"
author = "Juan Bautista Talens & Alicia González"
language = "ca"

# ----- i18n -----
locale_dirs = ['_locale']      # carpeta on viuran les traduccions
gettext_compact = False        # manté un .po per fitxer

# ──────────────── Extensions ────────────────
extensions = [
    "myst_parser",
    "sphinx.ext.graphviz",      # 👈 afegeix açò
    "sphinx_copybutton",
    "sphinx.ext.imgconverter",
    "sphinx_design",
    "sphinxcontrib.mermaid",    # si el fas servir, deixa-ho; si no, comenta-ho
    "diagrama_classe",
    
]

# (Opcional però recomanat per a HTML)
graphviz_output_format = "svg"
graphviz_dot_args = ["-Gbgcolor=transparent"]

myst_enable_extensions = ["colon_fence", "attrs_block", "deflist"]
myst_fence_as_directive = ["classe-diagrama"]


myst_heading_anchors = 3

# ──────────────── HTML (triar tema ací) ────────────────
# Pots triar via variable d'entorn: SPHINX_THEME=pydata_sphinx_theme make html
html_theme = os.environ.get("SPHINX_THEME", "sphinx_book_theme")  # "furo" | "sphinx_rtd_theme" | "pydata_sphinx_theme" | "alabaster"
html_title = "Sistemes de Gestió Empresarial"
html_baseurl = "https://juatafe.github.io/Odoo-CEFIRE/"
html_static_path = ["_static"]
# afegir script JS
html_js_files = [
    "release_control.js",
    "i18n-fixes.js",
]
templates_path = ["_templates"]
# Logos i favicon (com ja tenies)
html_logo = "_static/assets/img/logos/odoo_logo.svg"
html_favicon = "_static/assets/img/logos/logo50.ico"

# CSS personalitzat (ordre: general → específic)
html_css_files = [
    "assets/stylesheets/extracsspdf.css",
    "assets/stylesheets/customs.css",
    "assets/stylesheets/extra.css",
]

def slugify(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "-", s).strip("-").lower()

# Slug del site per al nom del PDF (mateixa lògica que tenies)
_repo = os.environ.get("GITHUB_REPOSITORY", "")
_repo_name = _repo.split("/")[-1] if _repo else ""
site_slug = _repo_name or slugify(project)
site_slug = os.environ.get("SITE_SLUG", "Odoo-CEFIRE")

# Enllaç relatiu al PDF dins del site (p. ex. pdf/plantilla-sphinx.pdf)
pdf_url = f"pdf/{site_slug}.pdf"

# ──────────────── Opcions per tema (cada tema entén les seues) ────────────────
_book_opts = {
    #"logo_only": False,  # mostra nom i logo
    "repository_url": "https://github.com/juatafe/Odoo-CEFIRE",
    "use_repository_button": True,
    "use_issues_button": True,
    "use_download_button": True,
    "navbar_start": ["jb-header-logos"],
}


_pydata_opts = {
    "show_nav_level": 2,
    "navigation_depth": 4,
    "secondary_sidebar_items": ["page-toc"],#, "sourcelink", "edit-this-page"],
    "use_edit_page_button": True,
    "show_prev_next": True,
    "show_toc_level": 2,
    "navbar_end": ["theme-switcher", "navbar-icon-links"],
    "icon_links": [
        {"name": "GitHub", "url": "https://github.com/juatafe/Odoo-CEFIRE", "icon": "fa-brands fa-github"},
        {"name": "Issues", "url": "https://github.com/juatafe/Odoo-CEFIRE", "icon": "fa-solid fa-circle-exclamation"},
        {"name": "PDF", "url": pdf_url, "icon": "fa-solid fa-file-pdf"},
    ],
    # Els teus logos en la navbar només quan el tema és PyData:
    "navbar_start": ["navbar-logo", "jb-header-logos"],
}

_rtd_opts = {
    "collapse_navigation": False,
    "sticky_navigation": True,
    "navigation_depth": 4,
    "includehidden": True,
    "titles_only": False,
}

_furo_opts = {
    # Furo té sidebar per pàgina; no hi ha navbar de toctree com PyData
    "light_logo": html_logo,
    "dark_logo": html_logo,
    "sidebar_hide_name": False,
    # Equivalent a "Edita esta pàgina" en Furo:
    "source_repository": "https://github.com/juatafe/Odoo-CEFIRE",
    "source_branch": "main",
    "source_directory": "docs/",
}

_alabaster_opts = {
    "logo": html_logo,
    "description": "Documentació",
    "fixed_sidebar": True,
    "page_width": "80%",
    "sidebar_width": "240px",
}

# Aplica les opcions segons el tema triat
if html_theme == "pydata_sphinx_theme":
    html_theme_options = _pydata_opts
elif html_theme == "sphinx_rtd_theme":
    html_theme_options = _rtd_opts
elif html_theme == "furo":
    html_theme_options = _furo_opts
elif html_theme == "alabaster":
    html_theme_options = _alabaster_opts
elif html_theme == "sphinx_book_theme":
    html_theme_options = _book_opts
else:
    html_theme_options = {}

# Afig opció global extra
html_theme_options["navigation_with_keys"] = True

# Context per a botó "Edita a GitHub" (el tenies actiu)
html_context = {
    "github_user": "juatafe",
    "github_repo": "Odoo-CEFIRE",
    "github_version": "main",
    "doc_path": "docs",
}

# Llengua del buscador
html_search_language = "ca"

# ──────────────── CONFIGURACIÓ ÚNICA LATEX / PDF ────────────────
latex_engine = "xelatex"
latex_toplevel_sectioning = "chapter"

# Detectem build PDF (suficient per a ús normal)
is_pdf = "latex" in sys.argv or "latexpdf" in sys.argv
latex_additional_files = [
    '_static/assets/img/logos/logo_Ministerio_UE_GeneralitatConselleria_FPCefire.pdf'
]
latex_elements = {
    "pointsize": "10pt" if is_pdf else "11pt",
    "extraclassoptions": "twoside,openany",
    "geometry": (
        r"\usepackage[paperwidth=7in,paperheight=10in,"
        r"top=2cm,bottom=2cm,left=2.5cm,right=2cm]{geometry}"
        if is_pdf
        else r"\usepackage[a4paper,margin=2.5cm]{geometry}"
    ),

    "fontpkg": "",
    "fncychap": "",
    "maketitle": r"\maketitle",

    "preamble": r"""
% ───── Idioma i fonts ─────
\usepackage{polyglossia}
\setmainlanguage{catalan}


% ───── Espai entre figures i text ─────
\setlength{\textfloatsep}{10pt}
\setlength{\intextsep}{10pt}

\usepackage{fontspec}
\setmainfont{FreeSerif}
\setsansfont{FreeSans}
\setmonofont{FreeMono}
% ───── Capítols ─────
\usepackage{titlesec}
\AtBeginDocument{
  \frontmatter
}

\setcounter{secnumdepth}{3}
\setcounter{tocdepth}{2}

\titleformat{\chapter}[display]
  {\bfseries\Huge}
  {Capítol \thechapter}
  {1em}
  {\Huge}

% ───── Convertir Mermaid en no-flotant ─────
\usepackage{float}
\makeatletter
\renewenvironment{figure}[1][htbp]
  {\def\@captype{figure}\par\medskip\noindent}
  {\par\medskip}
\makeatother


% ───── Silenciador de caràcters perduts (evita '?') ─────
\makeatletter
\tracinglostchars=0
\makeatother

% ───── WARNING sense icones ni emojis (PDF net) ─────
\usepackage{etoolbox}
\makeatletter
\renewenvironment{sphinxwarning}[1]
  {\begin{sphinxadmonition}{warning}{Advertència}{}}
  {\end{sphinxadmonition}}
\makeatother

% ───── Estil de pàgina ─────
\pagestyle{plain}

% ───── Suport per a llistes molt profundes (fins a 20 nivells) ─────
\usepackage{enumitem}
\setlistdepth{20}
\renewlist{itemize}{itemize}{20}
\setlist[itemize]{label=\textbullet}

\usepackage{float}
% ───── Ajust fi d'espais de figures (Mermaid, Graphviz, etc.) ─────
\setlength{\floatsep}{8pt}
\setlength{\textfloatsep}{10pt}
\setlength{\intextsep}{8pt}
\setlength{\abovecaptionskip}{4pt}
\setlength{\belowcaptionskip}{4pt}

% ───── Imatges a mida completa ─────
\usepackage{graphicx}
\setkeys{Gin}{width=1\linewidth,keepaspectratio}


% ───── Portada neta i professional ─────
\renewcommand{\maketitle}{
    \begin{titlepage}
        \centering

        % ───── Logos institucionals ─────
        \vspace*{1cm}
        \noindent{%
          \hspace*{\fill}%
          \sphinxincludegraphics[width=\textwidth]{logo_Ministerio_UE_GeneralitatConselleria_FPCefire.pdf}
        }
        % ───── Títol ─────
        {\Huge\bfseries Sistemes de Gestió Empresarial \par}
        \vspace{0.8cm}
        {\Large Apunts del curs (2n DAM) \par}

        \vfill

        % ───── Autoria ─────
        {\large Juan Bautista Talens \par}
        {\large Alicia González \par}

        \vspace{0.8cm}
        {\large 2026 \par}

    \end{titlepage}
    \clearpage
    \pagenumbering{arabic}
}
""",
}

latex_documents = [
    ("index", f"{site_slug}.tex", project, author, "book")
]


import re

_EMOJI_RE = re.compile(
    "["
    "\U0001F300-\U0001FAFF"
    "\U00002700-\U000027BF"
    "]+",
    flags=re.UNICODE,
)

_BOLD_RE = re.compile(r"\*\*(.*?)\*\*", flags=re.DOTALL)

def remove_emojis_only_for_pdf(app, docname, source):
    if app.builder.name != "latex":
        return

    text = source[0]

    # 1️⃣ DINS de negreta: eliminar emojis del tot
    def clean_bold(match):
        content = match.group(1)
        content = _EMOJI_RE.sub("", content)
        # normalitza espais interns
        content = re.sub(r"\s+", " ", content).strip()
        return f"**{content}**"

    text = _BOLD_RE.sub(clean_bold, text)

    # 2️⃣ FORA de negreta: substituir emojis per un espai
    text = _EMOJI_RE.sub(" ", text)

    # 3️⃣ Neteja general d’espais duplicats
    text = re.sub(r"[ \t]{2,}", " ", text)

    source[0] = text


def setup(app):
    app.connect("source-read", remove_emojis_only_for_pdf)

exclude_patterns = [
    '_build', 
    'Thumbs.db', 
    '.DS_Store', 
    'Unitats/Tema3/gestio_responsabilitat*.md',
    'Unitats/Tema3/_index.md',
    'Unitats/Tema3/ResponsabilitatPatrimonial.md'
]

suppress_warnings = [
    'design.grid',
]

mermaid_latex_float = False
mermaid_latex_inline = True
