# Apunts Odoo – CEFIRE

Apunts del curs sobre **Odoo**, elaborats amb **Sphinx + MyST Markdown**, amb doble eixida:

- 🌍 **Versió web (HTML)**  
  https://juatafe.github.io/Odoo-CEFIRE/

- 📘 **Versió llibre (PDF)**  
  [_build/latex/sistemes-de-gestio-empresarial.pdf](./_build/latex/sistemes-de-gestio-empresarial.pdf)

Aquest repositori conté tant **les fonts dels apunts** com **els resultats finals** en format HTML i PDF.

---

## 📚 Estructura del projecte

- `docs/` → Fonts de la documentació (Markdown / MyST)
- `_build/html/` → Resultat HTML generat amb Sphinx
- `_build/latex/` → Resultat PDF (llibre)
- `.github/workflows/` → Automatització amb GitHub Actions
- `requirements.txt` → Dependències Python
- `Makefile` → Ordres ràpides (`make clean`, `make build`, `make html`, `make serve`, `make pdf`…)

> ⚠️ Les carpetes `_build/` **no s’editen mai a mà**.

---

## 🌍 Consulta dels apunts

### Versió web (HTML)
La documentació web es publica automàticament amb **GitHub Pages**:

👉 https://juatafe.github.io/Odoo-CEFIRE/

No cal instal·lar res.

### Versió llibre (PDF)
El llibre complet en PDF es pot descarregar directament des del repositori:

👉 [Descarregar el PDF](./_build/latex/sistemes-de-gestio-empresarial.pdf)

---

## 👩‍🏫 Col·laboració

### 🔹 Només consultar els apunts
No cal clonar el repositori ni instal·lar res:
- Consulta la versió web (HTML) Encara que aquesta versió està pensada per a pdf, és totalment funcional com a web.
- O descarrega directament el PDF

### 🔹 Editar contingut
Per a col·laborar en l’edició dels apunts:

```bash
git clone https://github.com/juatafe/Odoo-CEFIRE.git
cd Odoo-CEFIRE
```

- Edita **només** els fitxers de la carpeta `docs/`
- Fes `git commit` i `git push`
- La web s’actualitza automàticament amb GitHub Actions

👉 **No cal compilar res en local** si no vols. No obstant, l'ordre natural seria fer un `make clean`, un `make html` i un `make serve` per visualitzar en local o un `make pdf` per tal de generar el pdf. 

---

## 🧪 Previsualització local (opcional)

Només recomanat si vols comprovar el resultat abans de pujar canvis.

### Crear entorn virtual
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Generar HTML
```bash
make html
```

El resultat es troba a:
```text
_build/html/index.html
```

### Generar PDF
```bash
make pdf
```

El PDF generat serà:
```text
_build/latex/sistemes-de-gestio-empresarial.pdf
```

---

## ⚙️ Automatització

- Cada *push* a la branca `main`:
  - compila la documentació HTML
  - la publica automàticament a GitHub Pages
- El PDF es genera de manera manual quan cal (format llibre)

---

## ℹ️ Notes importants

- El contingut editable viu a `docs/`
- No cal tocar `.github/` si no saps exactament què fas
- Les carpetes `_build/` són resultats, no fonts

---

Apunts pensats per a **ús docent real**, amb un flux senzill i sense maldecaps:
escriure → pujar → publicar.
