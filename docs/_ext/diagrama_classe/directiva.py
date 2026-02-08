from docutils.parsers.rst import Directive
from docutils.parsers.rst.directives import unchanged
from docutils import nodes
from PIL import Image, ImageDraw, ImageFont
import os

class ClasseDiagramDirective(Directive):
    has_content = True
    option_spec = {
        "class": unchanged,
        "attributes": unchanged,
        "methods": unchanged
    }

    def run(self):
        classe = self.options.get("class", "Classe")
        attrs_raw = self.options.get("attributes", "")
        methods_raw = self.options.get("methods", "")

        attrs = [l.strip() for l in attrs_raw.split(",") if l.strip()]
        methods = [l.strip() for l in methods_raw.split(",") if l.strip()]

        static_dir = os.path.join(
            self.state.document.settings.env.app.srcdir,
            "_static/diagrames"
        )
        os.makedirs(static_dir, exist_ok=True)

        filename = f"diagrama_{classe}.png"
        filepath = os.path.join(static_dir, filename)

        self._crear_diagrama(classe, attrs, methods, filepath)

        image_node = nodes.image(uri=f"/_static/diagrames/{filename}")
        return [image_node]


    def _crear_diagrama(self, classe, attrs, methods, filepath):
        # Colors
        BG = "#DDE3FF"
        BOX = "#BFD0FF"
        TEXT = "#000000"

        # Canvas
        img = Image.new("RGB", (900, 600), BG)
        d = ImageDraw.Draw(img)

        # Fonts (fallback si no troba)
        try:
            font_title = ImageFont.truetype("arial.ttf", 24)
            font_text = ImageFont.truetype("arial.ttf", 20)
        except:
            font_title = font_text = None

        # Caixa principal
        margin = 120
        d.rectangle([margin, 80, 900 - margin, 520],
                    fill=BOX, outline="#000000", width=3)

        # Títol
        d.text((margin + 20, 95), classe, fill=TEXT, font=font_title)

        # Separadors
        y_attrs = 160
        d.line([margin, y_attrs, 900 - margin, y_attrs], fill="black", width=2)

        y_methods = 330
        d.line([margin, y_methods, 900 - margin, y_methods], fill="black", width=2)

        # Atributs
        y = y_attrs + 10
        for a in attrs:
            d.text((margin + 20, y), a, fill=TEXT, font=font_text)
            y += 30

        # Mètodes
        y = y_methods + 10
        for m in methods:
            d.text((margin + 20, y), m, fill=TEXT, font=font_text)
            y += 30

        img.save(filepath)
