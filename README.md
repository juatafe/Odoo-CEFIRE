# Plantilla Sphinx + GitHub Pages (HTML + PDF)

Aquesta plantilla està pensada perquè el teu **repo** siga alhora *plantilla + tutorial* per a documentació HTML i PDF amb Sphinx i GitHub Pages.

## 🚀 Ús Recomanat (sense clonar ni baixar el repositori!)

**No cal baixar ni clonar aquest repositori!**  
Només necessites el fitxer `scripts/nou_sphinx_repo.sh` i seguir aquests passos:

### 1. Accedeix a GitHub i inicia sessió

Assegura't que estàs [logat a GitHub](https://github.com/login) amb el teu compte.

### 2. Descarrega només el script

Descarrega el fitxer [`scripts/nou_sphinx_repo.sh`](scripts/nou_sphinx_repo.sh) (pots fer-ho des de la web de GitHub amb "Raw" > "Desa com...").

### 3. Executa el script

Obri un terminal (si utilitzes **VS Code** és molt més còmode) i executa:

```bash
bash nou_sphinx_repo.sh
```

El script et guiarà per crear un nou repositori a partir d'aquesta plantilla, configurant tot el necessari (estructura, temes, workflows, etc.) sense necessitat de baixar manualment el repositori original.

---

## 📦 Què inclou la plantilla?

- Portada `docs/index.md` amb targetes i guia d'ús.
- Pàgines d'ajuda: `docs/guia-rapida.md`, `docs/personalitzacio.md`, `docs/duplicar-plantilla.md`.
- Workflow per a **Build & Deploy** d'HTML i PDF a **GitHub Pages** (usant contenidor).
- Script d'inicialització: `scripts/nou_sphinx_repo.sh`.
- `conf.py` adaptat a **pydata-sphinx-theme** i a generació de PDF amb `xelatex`.

---

## 💻 Desenvolupament en local (opcional)

Si vols treballar en local, pots fer-ho així (especialment còmode amb **Visual Studio Code**):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt  # opcional si no uses el contenidor
sphinx-build -b html docs docs/_build/html
```


---

## 🚦 Publicació automàtica

Fes *push* a la branca `main` i el workflow publicarà automàticament la documentació HTML i PDF a la branca `gh-pages`.

---

**Amb aquest sistema, només necessites el script i estar logat a GitHub. Si utilitzes VS Code, tot serà encara més senzill!**
