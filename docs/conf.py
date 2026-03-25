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
latex_toplevel_sectioning = os.getenv("LATEX_TOPLEVEL_SECTIONING", "chapter")

# Detectem build PDF (suficient per a ús normal)
is_pdf = "latex" in sys.argv or "latexpdf" in sys.argv
latex_additional_files = [
  '_static/assets/img/logos/logo_Ministerio_UE_GeneralitatConselleria_FPCefire.pdf',
  '_static/scripts/comptabilitat.sh',
  '_static/scripts/main.py',
  '_static/scripts/scriptsetupodoo.sh',
  '_static/scripts/deploy-odoo-docker.sh',
  '_static/scripts/test-docker-installation.sh',
  '_static/scripts/diagnostic.sh',
  '_static/scripts/monitor.sh',
  '_static/scripts/backup-docker.sh',
  '_static/scripts/restore-docker.sh'
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



% ───── Forçar que Pygments NO elimine indentació ─────
\usepackage{fvextra}
\fvset{
  obeytabs=true,
  tabsize=2,
  gobble=0
}

% ───── Capítols ─────
\usepackage{titlesec}
% \AtBeginDocument{
%   \frontmatter
% }
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

  
% ───── Marques de capçalera per a Fancyhdr (Sphinx fix) ─────
\makeatletter

% Capítol → leftmark
\renewcommand{\chaptermark}[1]{%
  \markboth{\chaptername\ \thechapter\ --\ #1}{}%
}

% Secció → rightmark
\renewcommand{\sectionmark}[1]{%
  \markright{#1}%
}

\makeatother

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
%\pagestyle{plain}
% ───── Capçaleres i peus de pàgina professionals ─────
\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{} % neteja tot

% ─── Capçaleres ───
% Pàgines parells (esquerra): Capítol
\fancyhead[LE]{\small\itshape \leftmark}

% Pàgines senars (dreta): Tema / secció
\fancyhead[RO]{\small\itshape \rightmark}

% ─── Peu de pàgina ───
% Número de pàgina al centre
\fancyfoot[C]{\thepage}

% Peu esquerra: autoria
\fancyfoot[LE,RO]{\scriptsize Juan Bautista Talens \& Alicia González}

% Peu dreta (alternatiu si vols llicència)
% \fancyfoot[RE,LO]{\scriptsize CC BY-NC-SA}

% ─── Línies fines (elegant, no escandalós) ───
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0.2pt}

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

% ───── Portada estil Odoo amb logos ─────
\usepackage{xcolor}
\usepackage{pagecolor}
\usepackage{tikz}
\usepackage{graphicx}

% ───── Portada en color Odoo (LaTeX pur) ─────
\definecolor{odoopurple}{RGB}{113,75,103}
\definecolor{odoopurplelight}{RGB}{245,240,243}

\renewcommand{\maketitle}{
\begin{titlepage}
\pagecolor{odoopurple}
\color{white}

% ───── Fons amb franja inferior clara + logos ─────
\begin{tikzpicture}[remember picture,overlay]

    % Franja blanca inferior (BLANC PUR)
    \fill[white]
    (current page.south west)
    rectangle ([yshift=3.8cm]current page.south east);

  % Logos institucionals (grans i centrats)
  \node[
    anchor=south,
    yshift=1.9cm
  ] at (current page.south) {
    \includegraphics[width=1.3\textwidth]{logo_Ministerio_UE_GeneralitatConselleria_FPCefire.pdf}
  };

  % Llicència baix dels logos
  \node[
    anchor=south,
    yshift=0.6cm
  ] at (current page.south) {
    {\scriptsize
    Material docent publicat sota llicència Creative Commons BY-NC-SA}
  };

\end{tikzpicture}

\vspace{2cm}
\centering

% ───── Títol principal ─────
{\Huge\bfseries Sistemes de Gestió Empresarial\par}

\vspace{1cm}

% ───── Subtítol ─────
{\Large
26FP32CF013 – Odoo: entorn, desenvolupament de mòduls i projectes reals
\par}

\vfill

% ───── Autoria ─────
{\Large Juan Bautista Talens\par}
{\Large Alicia González\par}

\vspace{1cm}

% ───── Any ─────
{\large 2026\par}

\vspace*{1.2cm}


\end{titlepage}

% ───── Tornar a estat normal ─────
\nopagecolor
% \clearpage
% \pagenumbering{arabic}
}
% ───── Annexos: que diga "Annex" i no "Capítol" ─────
\makeatletter
\g@addto@macro\appendix{%
  \renewcommand{\chaptername}{Annex}%
}
\makeatother

% ───── Contraportada morada estil Odoo (robusta) ─────
\AtEndDocument{
  \clearpage
  \thispagestyle{empty}

  % Colors
  \definecolor{odoopurple}{RGB}{113,75,103}

  \begin{tikzpicture}[remember picture,overlay]

    % ───── FONS COMPLET MORAT ODOO ─────
    \fill[odoopurple]
      (current page.north west)
      rectangle (current page.south east);

    % ───── FRANJA BLANCA INFERIOR ─────
    \fill[white]
      (current page.south west)
      rectangle ([yshift=3.8cm]current page.south east);

    % ───── LOGOS (grans) ─────
    \node[
      anchor=south,
      yshift=1.8cm
    ] at (current page.south) {
      \includegraphics[width=1.3\textwidth]{logo_Ministerio_UE_GeneralitatConselleria_FPCefire.pdf}
    };

  \end{tikzpicture}

  % ───── TEXT ─────
  \color{white}
  \begin{center}
    \vspace*{2.8cm}

    {\Large\bfseries Sistemes de Gestió Empresarial\par}
    \vspace{0.9cm}

    {\large
    Aquest material recull els continguts del mòdul de
    \textbf{Sistemes de Gestió Empresarial} del cicle de
    \textbf{Desenvolupament d’Aplicacions Multiplataforma (DAM)}.
    \par}

    \vspace{0.7cm}

    {\large
    El llibre ofereix una aproximació pràctica als sistemes
    \textbf{ERP--CRM}, amb especial atenció a \textbf{Odoo},
    abordant tant la configuració de l’entorn com el
    desenvolupament de mòduls i la realització de projectes reals.
    \par}

    \vspace{0.7cm}

    {\large
    Està pensat com a suport docent i d’aprenentatge,
    amb exemples contextualitzats, pràctiques guiades
    i una orientació clarament aplicada a l’aula.
    \par}

    \vspace{1.8cm}

    % ───── QR BLANC ─────
    {\color{white}
    \qrcode[height=3.5cm]{https://github.com/juatafe/Odoo-CEFIRE}
    }

    \vspace{0.5cm}

    {\small Accés al repositori oficial del curs (GitHub)\par}

  \end{center}
}
% ───── FIX TÍTOLS ADMONITIONS (SAFE) ─────
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

# Opció temporal: ocultar l'etiqueta de capítol ("Capítol 1") però
# mantenir la numeració jeràrquica 1.1, 1.1.1, etc.
if os.getenv("LATEX_HIDE_CHAPTER_LABEL", "0") == "1":
    latex_elements["preamble"] += """
\\titleformat{\\chapter}[display]
  {\\normalfont\\huge\\bfseries}
  {}
  {0pt}
  {}
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
