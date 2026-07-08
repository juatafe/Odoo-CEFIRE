import os
import sys
import re
sys.path.append(os.path.abspath("."))
sys.path.append(os.path.abspath("./_ext"))


# ──────────────── Projecte ────────────────
project = "Sistemes de Gestió Empresarial"
author = "Reina del Carmen Peiró Arnau"
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
    "sphinxcontrib.tikz",
    "sphinx.ext.mathjax",       # renderitza fórmules LaTeX en HTML
]

tikz_proc_suite = "ImageMagick" # o "Ghostscript"
tikz_latex_preamble = r"""
\usetikzlibrary{shapes.geometric,positioning,calc}
"""
# (Opcional però recomanat per a HTML)
graphviz_output_format = "svg"
graphviz_dot_args = ["-Gbgcolor=transparent"]

myst_enable_extensions = ["colon_fence", "attrs_block", "deflist", "dollarmath", "amsmath"]
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
site_slug = os.environ.get("SITE_SLUG", "SGE-Morralla Odoo")

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
latex_toplevel_sectioning = os.getenv("LATEX_TOPLEVEL_SECTIONING", "chapter")

# Detectem build PDF (suficient per a ús normal)
is_pdf = "latex" in sys.argv or "latexpdf" in sys.argv
is_paperback = os.getenv("SPHINX_PAPERBACK", "0") == "1"
latex_additional_files = [
      '_static/assets/img/logos/logoUPVGandia.png',
      '_static/assets/img/logos/Logo_Morralla.png',
      '_static/assets/img/logos/imatgeCentralLlibreSGE.png',
]

latex_elements = {
    "pointsize": "10pt" if is_pdf else "11pt",
    "extraclassoptions": "oneside",
    "geometry": (
        r"\usepackage[paperwidth=7in,paperheight=10in,"
        r"top=2cm,bottom=2cm,left=2cm,right=2cm]{geometry}"
        if is_pdf
        else r"\usepackage[a4paper,margin=2cm]{geometry}"
    ),
    
    # Configuració oficial de Sphinx per a forçar el tall de línia
    "sphinxsetup": "verbatimwrapslines=true, verbatimwithframe=true",

    "fontpkg": "",
    "fncychap": "",
    "maketitle": "" if is_paperback else r"\maketitle",

    "preamble": r"""
% ───── Idioma i fonts ─────
\usepackage{polyglossia}
\setmainlanguage{catalan}

\makeatletter
\def\sphinxVerbatimFormatLine#1{\hspace{0pt}#1}
\makeatother

\usepackage{qrcode}
\usepackage{attachfile2}
\attachfilesetup{color=0 0 0}

% ───── Espai entre figures i text ─────
\setlength{\textfloatsep}{10pt}
\setlength{\intextsep}{10pt}

\usepackage{fontspec}
\setmainfont{FreeSerif}
\setsansfont{FreeSans}
\setmonofont{FreeMono}

% ───── TikZ (global) ─────
\usepackage{tikz}
\usetikzlibrary{shapes.geometric,positioning,calc}

% ───── Capítols ─────
\usepackage{titlesec}

% ───── Netejar numeració estranya del TOC ─────
\usepackage{tocloft}
\renewcommand{\cftsecnumwidth}{2.5em}
\renewcommand{\cftsubsecnumwidth}{3.5em}
\renewcommand{\cftsubsubsecnumwidth}{4.5em}

\setcounter{secnumdepth}{2}
\setcounter{tocdepth}{1}

\titleformat{\chapter}[display]
  {\bfseries\Huge}
  {\chaptername\ \thechapter}
  {1em}
  {\Huge}

% ───── Convertir Mermaid en no-flotant ─────
\usepackage{float}
\makeatletter
\renewenvironment{figure}[1][htbp]
  {\def\@captype{figure}\par\medskip\noindent}
  {\par\medskip}
\makeatother

% ───── Portada estil Odoo amb logos ─────
\usepackage{xcolor}
\usepackage{pagecolor}

% Definició de colors
\definecolor{odoopurple}{RGB}{113,75,103}
\definecolor{odoopurplelight}{RGB}{245,240,243}
\definecolor{BlauUPV}{HTML}{005C84}

\renewcommand{\maketitle}{
    \begin{titlepage}
        % Fons decoratiu suau per a un estil modern
        \begin{tikzpicture}[remember picture, overlay]
            \fill[BlauUPV] (current page.north west) rectangle (current page.south east);
            \fill[white] (current page.north west) rectangle ([yshift=-3cm]current page.north east);
        \end{tikzpicture}
        
        \centering
        \vspace{-2cm}
        
        % Capsçalera amb el logo de la UPV a la dreta
        \hfill
        \begin{minipage}{0.4\textwidth}
            \flushleft
            \includegraphics[height=2cm]{logoUPVGandia.png }  \hspace{2cm} \\
        \end{minipage}
        \hspace{2cm}
        \begin{minipage}{0.4\textwidth}
            \flushright       
            \includegraphics[height=1.8cm]{Logo_Morralla.png} % Logo La Morralla
        \end{minipage}
        
        \vspace{2cm}
        % Bloc de títols emmarcat
        \begin{minipage}{0.8\textwidth}
            \flushleft     
            \color{white}
            {\fontsize{35}{42}\selectfont \textbf{Dossier d'activitats d'SGE amb Odoo 19} \par} 
            \vspace{1cm}
            \centering
            {\LARGE \textit{Desenvolupament d'un mòdul de gestió per a una colla de dolçaines i tabals}} \\
            \vspace{0.6cm}        
        \end{minipage}
        
        
        % --- IMATGE CENTRAL DE LA INFOGRAFIA ---        
        \begin{tikzpicture}
            \node[inner sep=0pt] (imatge) at (0,0) {\includegraphics[width=0.75\textwidth]{imatgeCentralLlibreSGE.png}};
            \draw[BlauUPV, line width=2pt] (imatge.north west) -- (imatge.north east);
            \draw[BlauUPV, line width=2pt] (imatge.south west) -- (imatge.south east);
        \end{tikzpicture}
        
        %\vspace{2cm}
        \vfill        
        % Detalls de l'autora i any
        \begin{minipage}{0.85\textwidth}
            \centering
            \color{white}
            {\large \textbf{Reina del Carmen Peiró Arnau}} \\
            \vspace{0.4cm}
            {\large 2026}
        \end{minipage}
        
        \vspace{2cm}
        
        
        % Nota de crèdits
        \begin{minipage}{1\textwidth}
            \centering            
            \begin{minipage}{0.95\textwidth}
                \centering \vspace{0.8cm}
                \color{white}
                {\large Material adaptat del curs SGE dels autors: \\ \textbf{Juan Bautista Talens i Alicia González}}
                \vspace{-0.6cm}
            \end{minipage}        
        \end{minipage}
        
        
    
    \end{titlepage}
    \nopagecolor
}

% ───── Capçaleres i peus de pàgina professionals (Solució Definitiva per a 'make pdf') ─────
\usepackage{fancyhdr}
\usepackage{etoolbox}

\AtBeginDocument{
  % 1. Forcem a que Sphinx NO convertisca el text a majúscules
  \patchcmd{\chaptermark}{\MakeUppercase}{}{}{}
  \patchcmd{\sectionmark}{\MakeUppercase}{}{}{}

  % 2. Congelem les marques: el capítol escriurà a la banda esquerra (leftmark)
  % i anul·lem completament que les seccions (apartats) escriguen res.
  \renewcommand{\chaptermark}[1]{\markboth{\chaptername\ \thechapter\ - #1}{}}
  \renewcommand{\sectionmark}[1]{}
  \renewcommand{\subsectionmark}[1]{}

  % 3. Redefinim 'plain' (l'estil de Sphinx per als inicis de capítol)
  \fancypagestyle{plain}{
    \fancyhf{}
    \fancyfoot[L]{\small\itshape\leftmark}  % Nom del capítol
    \fancyfoot[R]{\thepage}                 % Número de pàgina
    \renewcommand{\headrulewidth}{0pt}
    \renewcommand{\footrulewidth}{0.2pt}
  }

  % 4. Redefinim 'normal' (l'estil secret que Sphinx aplica a la resta de pàgines)
  \fancypagestyle{normal}{
    \fancyhf{}
    \fancyfoot[L]{\small\itshape\leftmark}  % El mateix nom del capítol congelat
    \fancyfoot[R]{\thepage}                 % El mateix número
    \renewcommand{\headrulewidth}{0pt}
    \renewcommand{\footrulewidth}{0.2pt}
  }
}


% ───── Suport per a llistes molt profundes (fins a 20 nivells) ─────
\usepackage{enumitem}
\setlistdepth{20}
\renewlist{itemize}{itemize}{20}
\setlist[itemize]{label=\textbullet}

\usepackage{float}
\setlength{\floatsep}{8pt}
\setlength{\textfloatsep}{10pt}
\setlength{\intextsep}{8pt}
\setlength{\abovecaptionskip}{4pt}
\setlength{\belowcaptionskip}{4pt}

% ───── Imatges a mida completa ─────
\usepackage{graphicx}
\setkeys{Gin}{width=1\linewidth,keepaspectratio}

\makeatletter
\g@addto@macro\appendix{%
  \renewcommand{\chaptername}{Activitat}
}
\makeatother

\AtBeginDocument{
\makeatletter
\def\sphinx@note@title{Nota}
\def\sphinx@tip@title{Consell}
\def\sphinx@warning@title{Advertència}
\def\sphinx@important@title{Important}
\def\sphinx@caution@title{Precaució}
\def\sphinx@danger@title{Perill}
\makeatother
}
""",
}

latex_elements["preamble"] = f"\\newif\\ifpaperback\n\\paperback{'true' if is_paperback else 'false'}\n" + latex_elements["preamble"]

# Opció temporal: ocultar l'etiqueta de capítol ("Capítol 1") però
# mantenir la numeració jeràrquica 1.1, 1.1.1, etc.
if os.getenv("LATEX_HIDE_CHAPTER_LABEL", "0") == "1":
    latex_elements["preamble"] += """
\\titleformat{\\chapter}[display]
  {\\normalfont\\huge\\bfseries}
  {}
  {0pt}
  {}

\\makeatletter
\\renewcommand{\\chaptermark}[1]{\\markboth{#1}{}}
\\makeatother
"""

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
_EMOJI_ARTIFACT_RE = re.compile(r"[\uFE0E\uFE0F\u200D\u20E3]")

_BOLD_RE = re.compile(r"\*\*(.*?)\*\*", flags=re.DOTALL)
_FENCED_CODE_RE = re.compile(r"(^```.*?^```\s*$)", flags=re.MULTILINE | re.DOTALL)
_PDF_EMOJI_MAP = {
  # En text normal (incloent títols), no volem etiquetes [OK]/[RUN]:
  # les icones es lleven directament amb _EMOJI_RE.
}

_PDF_CODE_EMOJI_MAP = {
    "✅": "[OK]",
    "✔": "[OK]",
    "✓": "[OK]",
    "❌": "[ERROR]",
    "🚀": "[RUN]",
    "🏗️": "[BUILD]",
    "🏗": "[BUILD]",
    "📦": "[PKG]",
    "🔧": "[SERVICE]",
    "🌐": "[WEB]",
    "📡": "[HTTP]",
    "👤": "[USER]",
    "🐘": "[POSTGRES]",
    "🔑": "[ROLE]",
    "📁": "[FILES]",
    "🐍": "[PYTHON]",
    "🎉": "[DONE]",
}

def remove_emojis_only_for_pdf(app, docname, source):
    if app.builder.name != "latex":
        return

    text = source[0]

    # No tocar blocs de codi fenced: preservar indentació i espais exactes
    parts = _FENCED_CODE_RE.split(text)
    processed_parts = []

    def replace_known_pdf_emojis(value: str) -> str:
        for emoji, replacement in _PDF_EMOJI_MAP.items():
            value = value.replace(emoji, replacement)
        return value

    def replace_codeblock_pdf_emojis(value: str) -> str:
      for emoji, replacement in _PDF_CODE_EMOJI_MAP.items():
        value = value.replace(emoji, replacement)
      return value

    for part in parts:
      # Bloc de codi fenced (comença per ```): tractament específic
      if part.startswith("```"):
        part = replace_codeblock_pdf_emojis(part)
        part = _EMOJI_RE.sub(" ", part)
        part = _EMOJI_ARTIFACT_RE.sub("", part)
        processed_parts.append(part)
        continue

      # 1️⃣ DINS de negreta: eliminar emojis del tot
      def clean_bold(match):
        content = match.group(1)
        content = replace_known_pdf_emojis(content)
        content = _EMOJI_RE.sub("", content)
        content = _EMOJI_ARTIFACT_RE.sub("", content)
        content = re.sub(r"\s+", " ", content).strip()
        return f"**{content}**"

      part = _BOLD_RE.sub(clean_bold, part)
      part = replace_known_pdf_emojis(part)

      # 2️⃣ FORA de negreta: substituir emojis per un espai
      part = _EMOJI_RE.sub(" ", part)
      part = _EMOJI_ARTIFACT_RE.sub("", part)
      processed_parts.append(part)

    source[0] = "".join(processed_parts)


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