# Apunts Odoo – CEFIRE

Apunts del curs sobre **Odoo**, elaborats amb **Sphinx + MyST Markdown**, amb doble eixida:

- 🌍 **Versió web (HTML)**  
  https://juatafe.github.io/Odoo-CEFIRE/

- 📘 **Versió llibre (PDF)**  
  Disponible a l’última *release* del projecte:  
  https://github.com/juatafe/Odoo-CEFIRE/releases/latest

Aquest repositori conté tant **les fonts dels apunts** com **els resultats finals** en format HTML i PDF.

---

## 📚 Estructura del projecte

- `docs/` → Fonts de la documentació (Markdown / MyST)
- `.github/workflows/` → Automatització amb GitHub Actions
- `requirements.txt` → Dependències Python
- `Makefile` → Ordres ràpides (`make clean`, `make html`, `make serve`, `make pdf`, …)

> ⚠️ La carpeta `_build/` conté fitxers **generats** i **no s’edita ni es versiona a mà**.

---

## 🌍 Consulta dels apunts

### Versió web (HTML)
La documentació web es publica automàticament amb **GitHub Pages**:

👉 https://juatafe.github.io/Odoo-CEFIRE/

No cal instal·lar res.

### Versió llibre (PDF)
El llibre complet en PDF es publica com a **Release** del projecte:

👉 https://github.com/juatafe/Odoo-CEFIRE/releases/latest

---

## 👩‍🏫 Col·laboració

### 🔹 Només consultar els apunts
No cal clonar el repositori ni instal·lar res:
- Consulta la versió web (HTML)
- O descarrega el PDF des de *Releases*

### 🔹 Editar contingut
Per a col·laborar en l’edició dels apunts:

```bash
git clone https://github.com/juatafe/Odoo-CEFIRE.git
cd Odoo-CEFIRE
```

- Edita **només** els fitxers de la carpeta `docs/`
- Fes `git commit` i `git push`
- La web s’actualitza automàticament amb GitHub Actions

👉 **No cal compilar res en local** si no vols.

---

## 🧪 Previsualització local (opcional)

Només recomanat si vols comprovar el resultat abans de pujar canvis.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make html
```

---

Apunts pensats per a **ús docent real**, amb un flux senzill i sense maldecaps:
**escriure → pujar → publicar**.
