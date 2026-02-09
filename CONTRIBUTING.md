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

---

## 🔧 Com actualitzar un tag de Git

Si un tag existent apunta al commit incorrecte, pots reassignar-lo al commit actual amb aquests passos. Aquesta operació sincronitza tant l'etiqueta local com la remota (GitHub).

### Passos (amb explicació breu)

1. Preparar els canvis per al commit:
  - `git add .` — Afig tots els canvis del directori a l'índex (preparats per confirmar). És l'“arreplega-ho tot”.
2. Crear el commit amb un missatge clar:
  - `git commit -m "portada i contra"` — Guarda els canvis en un commit; el missatge descriu què s'ha tocat (portada i contraportada). Foto fixa del moment.
3. Pujar el commit a la branca principal:
  - `git push origin main` — Envia el commit a `main` del remot. Ja està en GitHub.
4. Esborrar el tag local que estava mal apuntat:
  - `git tag -d v0.1.6` — Elimina el tag `v0.1.6` en local.
5. Esborrar el mateix tag en el remot (GitHub):
  - `git push origin :refs/tags/v0.1.6` — Elimina el tag al repositori remot (clau perquè GitHub no el conserve).
6. Tornar a crear el tag correctament, apuntant al commit actual:
  - `git tag v0.1.6` — Crea de nou el tag sobre l’últim commit (el correcte).
7. Pujar el tag corregit al remot:
  - `git push origin v0.1.6` — Publica el tag en GitHub. La release queda arreglada i ben apuntada.

### Comandes juntes per copiar/enganxar

```bash
git add .
git commit -m "portada i contra"
git push origin main
git tag -d v0.1.6
git push origin :refs/tags/v0.1.6
git tag v0.1.6
git push origin v0.1.6
```

Nota: substitueix `v0.1.6` pel número de versió que corresponga en el teu cas.

**Gràcies per contribuir i mantenir el projecte actualitzat!**