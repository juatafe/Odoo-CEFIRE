# Contribució als Apunts Odoo – CEFIRE

Gràcies per col·laborar en aquest projecte 🙌  
Aquest document explica **com treballar en el repositori** i **com es publiquen les versions**.

---

## ✏️ Edició del contingut

- El contingut editable està dins de la carpeta `docs/`
- Els fitxers són en format Markdown / MyST
- No cal compilar res en local per a col·laborar

Flux habitual:
1. Editar fitxers de `docs/`
2. `git commit`
3. `git push`

La versió web (HTML) s’actualitza automàticament.

---

## 🌍 Publicació web (HTML)

- Cada *push* a la branca `main`:
  - compila la documentació HTML
  - la publica a GitHub Pages

Aquest procés és automàtic i no requereix cap acció addicional.

---

## 📘 Versions del llibre (PDF)

El PDF del llibre **no es publica amb cada canvi**.

Només es genera una nova versió del PDF quan es crea un **tag de versió**.

### 🔖 Crear una nova versió del llibre

Quan el contingut està llest i revisat:

```bash
git tag v1.0
git push origin v1.0
```

A partir d’això, GitHub Actions:
- compila el PDF
- crea una *Release*
- publica el PDF com a fitxer descarregable

La versió més recent del llibre està sempre disponible ací:
https://github.com/juatafe/Odoo-CEFIRE/releases/latest

---

## ⚠️ Notes importants

- No edites mai la carpeta `_build/`
- No cal tocar `.github/workflows/`
- Els tags de versió només s’han de crear quan el contingut està estable

En cas de dubte, consulta amb la persona responsable del repositori.
