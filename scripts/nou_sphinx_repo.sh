#!/usr/bin/env bash
# Ús:
#   ./nou_sphinx_repo.sh NOU_REPO "Títol nou" UsuariGitHub [ORIGEN] [NomPDF.pdf]
# Exemples:
#   ./nou_sphinx_repo.sh plantilla-sphinx "Repo de plantilla sphinx" juatafe
#   ./nou_sphinx_repo.sh apunts-xarxes "Apunts de Xarxes" juatafe https://github.com/juatafe/sge.git ApuntsDeXarxes.pdf

set -euo pipefail

# ——— Helpers
die(){ echo "❌ $*" >&2; exit 1; }
info(){ echo -e "$*"; }

trap 'die "Ha petat a la línia $LINENO. Revisa el missatge anterior."' ERR

# ——— Args
if [[ $# -lt 3 || $# -gt 5 ]]; then
  die "Ús: $0 NOU_REPO \"Títol nou\" UsuariGitHub [ORIGEN] [NomPDF.pdf]"
fi

NOU_REPO="$1"
TITOL="$2"
USUARI="$3"
ORIGEN="${4:-https://github.com/juatafe/plantilla-sphinx.git}"   # repo base per defecte
PDF_NAME="${5:-${NOU_REPO}.pdf}"                    # PDF per defecte = nom del repo

# ——— Dependències
command -v gh  >/dev/null || die "Falta 'gh' (GitHub CLI). Fes 'gh auth login'."
command -v git >/dev/null || die "Falta 'git' al PATH."

# ——— Clona base i neteja
TMP_DIR="$(mktemp -d)"
info "📥 Clonant origen: $ORIGEN"
git clone --depth=1 "$ORIGEN" "$TMP_DIR/src" >/dev/null

cd "$TMP_DIR/src"
info "🧹 Netejant historial Git…"
rm -rf .git

# ——— Detecta workflow (per a saber si té sentit esperar)
WF=""
if [[ -f ".github/workflows/docs.yml" ]]; then
  WF=".github/workflows/docs.yml"
elif [[ -f ".github/workflows/sphinx.yml" ]]; then
  WF=".github/workflows/sphinx.yml"
elif [[ -f ".github/workflows/build-deploy.yml" ]]; then
  WF=".github/workflows/build-deploy.yml"
fi

# ——— Ajustos conf.py
CONF="docs/conf.py"
if [[ -f "$CONF" ]]; then
  sed -i "s/^project = .*/project = \"$TITOL\"/" "$CONF"
  sed -i "s/^html_title = .*/html_title = \"$TITOL\"/" "$CONF"
  sed -i "s|https://github.com/[^/\"']\+/[^\"']\+|https://github.com/$USUARI/$NOU_REPO|g" "$CONF" || true
  sed -i "s|https://[^/\"']\+\.github\.io/[^/\"']\+/pdf/[^\"']\+|https://$USUARI.github.io/$NOU_REPO/pdf/$PDF_NAME|g" "$CONF" || true
else
  info "⚠️  No he trobat $CONF; salte canvis de conf.py"
fi

# ——— Ajusta el workflow perquè deixe el PDF amb nom fix
if [[ -n "$WF" ]]; then
  sed -i "s|cp _build/latex/\*\.pdf .*|cp _build/latex/*.pdf site_html/pdf/$PDF_NAME|g" "$WF" || true
  sed -i "s|cp docs/_build/latex/\*\.pdf .*|cp docs/_build/latex/*.pdf docs/_build/html/pdf/$PDF_NAME|g" "$WF" || true
else
  info "⚠️  No he trobat workflow a .github/workflows; crea’l després si cal."
fi

# ——— Inicialitza i puja
info "📦 Inicialitzant repo nou local…"
git init -q
git add .
git commit -m "Bootstrap $TITOL (Sphinx + HTML/PDF + Pages)" >/dev/null
git branch -M main
BRANCA_ORIG="main"

info "☁️  Creant $USUARI/$NOU_REPO a GitHub i fent push inicial…"
gh repo create "$USUARI/$NOU_REPO" --public --source=. --remote=origin --push >/dev/null
info "✓ Push inicial: https://github.com/$USUARI/$NOU_REPO"

# ——— Configurar GitHub Pages: espera curta + fallback immediat
info "⚙️  Configurant GitHub Pages… (esperant 'gh-pages' del workflow si n'hi ha)"

MAX_SEC=60                # espera curteta: 60s
INTERVAL=3
TICKS=$((MAX_SEC / INTERVAL))
OK=0

# si NO hi ha workflow, no perdem temps esperant
if [[ -n "$WF" ]]; then
  for (( i=1; i<=TICKS; i++ )); do
    if gh api -X GET "/repos/$USUARI/$NOU_REPO/branches/gh-pages" >/dev/null 2>&1; then
      OK=1; break
    fi
    printf "\r   Esperant gh-pages… %2ds/%2ds" $((i*INTERVAL)) $MAX_SEC
    sleep "$INTERVAL"
  done
  printf "\r%*s\r" 40 ""  # neteja línia
fi

if [[ "$OK" -eq 1 ]]; then
  info "✅ 'gh-pages' detectada."
else
  info "⚠️  No hi ha 'gh-pages'. La cree orfe amb placeholder per a activar Pages…"
  git checkout --orphan gh-pages >/devnull 2>&1 || git checkout --orphan gh-pages
  git rm -rf . >/dev/null 2>&1 || true
  touch .nojekyll index.html
  printf "<!doctype html><meta charset='utf-8'><title>%s</title><h1>%s</h1><p>Placeholder de gh-pages. El workflow el substituirà.</p>" "$NOU_REPO" "$NOU_REPO" > index.html
  git add .nojekyll index.html
  git commit -m "chore: bootstrap gh-pages (placeholder)" >/dev/null
  git push origin gh-pages >/dev/null
  git checkout "$BRANCA_ORIG" >/dev/null
  info "✓ 'gh-pages' creada amb placeholder."
fi

# ——— Activa Pages en gh-pages /
info "🌐 Activant GitHub Pages (branch: gh-pages, path: /)…"
if ! gh api -X POST     -H "Accept: application/vnd.github+json"     "/repos/$USUARI/$NOU_REPO/pages"     -F build_type=legacy     -F source[branch]=gh-pages     -F source[path]=/ >/dev/null 2>&1; then
  gh api -X PUT     -H "Accept: application/vnd.github+json"     "/repos/$USUARI/$NOU_REPO/pages"     -F build_type=legacy     -F source[branch]=gh-pages     -F source[path]=/ >/dev/null
fi

echo
info "✅ Fet!"
info "   Repo: https://github.com/$USUARI/$NOU_REPO"
info "   Web:  https://$USUARI.github.io/$NOU_REPO/"
info "   PDF:  https://$USUARI.github.io/$NOU_REPO/pdf/$PDF_NAME"
info "   (si veus el placeholder, en pocs minuts el workflow el sobreescriu)