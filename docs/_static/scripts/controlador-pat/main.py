from odoo import http
from odoo.http import request
from datetime import date
import base64
import io
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from pypdf import PdfReader, PdfWriter
from PIL import Image
from reportlab.lib.units import cm
from datetime import datetime

class PatinatgeInscripcioController(http.Controller):

    @http.route('/inscripcio', type='http', auth='public', website=True)
    def formulari_inscripcio(self, **kw):
        return request.render(
            'patinatge_inscripcio.formulari_inscripcio',
            {}
        )
    @http.route('/verificar/<string:csv>', type='http', auth='public', website=True)
    def verificar_document(self, csv, **kw):
        inscripcio = request.env['patinatge.inscripcio'].sudo().search(
            [('csv', '=', csv)],
            limit=1
        )

        if not inscripcio:
            return request.render('patinatge_inscripcio.verificacio_error')

        return request.render(
            'patinatge_inscripcio.verificacio_ok',
            {'inscripcio': inscripcio}
        )

    @http.route('/inscripcio/enviar', type='http', auth='public', methods=['POST'], website=True)
    def enviar_inscripcio(self, **post):

        data_naix = post.get('data_naixement')
        edat = (date.today() - date.fromisoformat(data_naix)).days // 365

        # 🔎 Validació DNI
        if edat < 18:
            dni = post.get('dni_tutor')
            if not validar_dni_nie(dni):
                return request.render(
                    'patinatge_inscripcio.formulari_inscripcio',
                    {'error': 'El DNI/NIE del tutor no és vàlid', 'data': post}
                )
        else:
            dni = post.get('dni_contacte')
            if not validar_dni_nie(dni):
                return request.render(
                    'patinatge_inscripcio.formulari_inscripcio',
                    {'error': 'El teu DNI/NIE no és vàlid', 'data': post}
                )

        # 📝 Crear inscripció
        vals = {
            'nom_patinadora': post.get('nom_patinadora'),
            'cognoms_patinadora': post.get('cognoms_patinadora'),
            'data_naixement': data_naix,
            'categoria': post.get('categoria'),
            'estat': 'pendent_signatura',
        }

        if edat < 18:
            vals.update({
                'nom_tutor': post.get('nom_tutor'),
                'cognoms_tutor': post.get('cognoms_tutor'),
                'dni_tutor': post.get('dni_tutor'),
                'email_tutor': post.get('email_tutor'),
                'telefon_tutor': post.get('telefon_tutor'),
            })
        else:
            vals.update({
                'dni_patinadora': post.get('dni_contacte'),
                'email_patinadora': post.get('email_contacte'),
                'telefon_patinadora': post.get('telefon_contacte'),
            })

        inscripcio = request.env['patinatge.inscripcio'].sudo().create(vals)

        # 📄 Generar PDF
        report = request.env.ref('patinatge_inscripcio.action_report_inscripcio').sudo()
        pdf_content, _ = request.env['ir.actions.report'].sudo()._render_qweb_pdf(
            'patinatge_inscripcio.report_inscripcio',
            [inscripcio.id]
        )


        inscripcio.write({
            'pdf_original': base64.b64encode(pdf_content),
        })

        return request.render(
            'patinatge_inscripcio.inscripcio_signar',
            {'inscripcio': inscripcio}
        )

    @http.route('/signatura/pdf/<string:token>',
                type='http',
                auth='public',
                csrf=False)
    def signatura_pdf(self, token):
        inscripcio = validar_token(token)

        pdf_bytes = inscripcio.generar_pdf()

        return request.make_response(
            pdf_bytes,
            headers=[
                ('Content-Type', 'application/pdf'),
                ('Content-Disposition', 'inline; filename="inscripcio.pdf"'),
                ('Content-Length', str(len(pdf_bytes))),
            ]
        )

    @http.route('/signatura/retorn',
                type='http', auth='user', methods=['POST'])
    def signatura_retorn(self, **post):
        pdf_signat_b64 = post.get('data')

        pdf_signat = base64.b64decode(pdf_signat_b64)

        inscripcio = recuperar_inscripcio()

        inscripcio.write({
            'pdf_signat': base64.b64encode(pdf_signat),
            'estat': 'signat'
        })

        return request.redirect('/inscripcio/confirmada')


    # 🔹 Ruta per a VORE el PDF (iframe / justificant)
    @http.route('/inscripcio/pdf/<int:inscripcio_id>', type='http', auth='public', website=True)
    def veure_pdf_inscripcio(self, inscripcio_id, **kw):
        inscripcio = request.env['patinatge.inscripcio'].sudo().browse(inscripcio_id)

        if not inscripcio:
            return request.not_found()

        # 👉 PRIORITAT: PDF SIGNAT
        pdf_bin = inscripcio.pdf_signat or inscripcio.pdf_original

        if not pdf_bin:
            return request.not_found()

        pdf = base64.b64decode(pdf_bin)

        headers = [
            ('Content-Type', 'application/pdf'),
            ('Content-Disposition', 'inline; filename="inscripcio.pdf"'),
            ('Content-Length', str(len(pdf))),
        ]
        return request.make_response(pdf, headers=headers)

 
    @http.route('/inscripcio/pujar_signat', type='http', auth='public', methods=['POST'], website=True)
    def pujar_pdf_signat(self, **post):
        inscripcio = request.env['patinatge.inscripcio'].sudo().browse(
            int(post.get('inscripcio_id'))
        )

        if not inscripcio:
            return request.not_found()

        pdf = post.get('pdf_signat')
        signature_data = post.get('signature_data')

        vals = {}
        if not inscripcio.csv:
            inscripcio.write({'csv': inscripcio.generar_csv()})

        # 🔐 OPCIÓ 1: PDF signat amb AutoFirma
        if pdf and hasattr(pdf, 'read'):
            vals.update({
                'pdf_signat': base64.b64encode(pdf.read()),
                'estat': 'signada',
            })
            

        # 🖊️ OPCIÓ 2: Signatura manual (ratolí)
        elif signature_data:
            try:
                header, encoded = signature_data.split(',', 1)
                if encoded:
                    # 1. PDF provisional
                    pdf_signat_temp = aplicar_signatura_al_pdf(
                        inscripcio.pdf_original,
                        encoded,
                        inscripcio.reference,
                        "TEMP",
                        inscripcio.csv
                    )

                    # 2. hash
                    hash_pdf = inscripcio.calcular_hash_pdf(pdf_signat_temp)

                    # 3. PDF definitiu amb hash imprés
                    pdf_signat = aplicar_signatura_al_pdf(
                        inscripcio.pdf_original,
                        encoded,
                        inscripcio.reference,
                        hash_pdf,
                        inscripcio.csv
                    )

                    vals.update({
                        'signature_manual': encoded,
                        'pdf_signat': pdf_signat,
                        'estat': 'signada_manual',
                        'hash_signat': hash_pdf,
                    })

            except Exception as e:
                raise  # MENTRE PROVES, QUE PETE I ES VEJA
      

        # ❌ CAS ÚNIC QUE NO AVANÇA
        if not vals:
            return request.render(
                'patinatge_inscripcio.inscripcio_signar',
                {
                    'inscripcio': inscripcio,
                    'error': 'Cal signar el document o pujar-lo signat per continuar.'
                }
            )

        # ✅ EN TOTS ELS ALTRES CASOS → AVANCEM
    
        inscripcio.write(vals)

        return request.render(
            'patinatge_inscripcio.inscripcio_ok',
            {'inscripcio': inscripcio}
        )


def validar_dni_nie(dni):
    if not dni:
        return False
    dni = dni.upper().strip()
    lletres = "TRWAGMYFPDXBNJZSQVHLCKE"
    if len(dni) != 9:
        return False
    if dni[0] in "XYZ":
        dni = dni.replace('X', '0').replace('Y', '1').replace('Z', '2')
    num = dni[:-1]
    return num.isdigit() and dni[-1] == lletres[int(num) % 23]

def aplicar_signatura_al_pdf(pdf_base64, signatura_base64, referencia, hash_pdf,csv):
    """
    Incrusta una signatura (PNG base64) al PDF original (base64)
    i retorna el PDF signat en base64
    """

    # 🔹 1. Decode PDF original
    pdf_bytes = base64.b64decode(pdf_base64)
    pdf_reader = PdfReader(io.BytesIO(pdf_bytes))
    pdf_writer = PdfWriter()
    
    # 🔹 2. Decode signatura PNG
    signatura_bytes = base64.b64decode(signatura_base64)
    #signatura_img = Image.open(io.BytesIO(signatura_bytes))
    img = Image.open(io.BytesIO(signatura_bytes))
    if img.mode in ("RGBA", "LA"):
        fondo = Image.new("RGB", img.size, (255, 255, 255))
        fondo.paste(img, mask=img.split()[-1])
        signatura_img = fondo
    else:
        signatura_img = img

    signatura_img = signatura_img.convert("RGBA")
    base_url = request.env['ir.config_parameter'].sudo().get_param('web.base.url')
    url_verificacio = f"{base_url}/verificar/{csv}"


    # pixels = signatura_img.load()
    # for y in range(signatura_img.height):
    #     for x in range(signatura_img.width):
    #         r, g, b, a = pixels[x, y]
    #         if a > 0:  # només on hi ha traç
    #             pixels[x, y] = (31, 79, 216, a)  # blau institucional

    # 🔹 3. Crear PDF temporal amb la signatura
    packet = io.BytesIO()
    c = canvas.Canvas(packet, pagesize=A4)
    

  
    # 📍 POSICIÓ DE LA SIGNATURA (ajustable)
    #x = 100      # des de l’esquerra
    #y = 120      # des de baix
    #width = 200  # amplada firma
    #height = 80  # altura firma

    #c.drawInlineImage(signatura_img, x, y, width, height)
    c.saveState()
    # 🧱 Línia vertical separadora
    c.setStrokeColorRGB(0.12, 0.31, 0.85)
    c.setLineWidth(1)

    # línia vertical del marge
    c.line(
        2.2 * cm,   # just on acaba el marge
        4 * cm,    # comença prop de la firma
        2.2 * cm,
        26  * cm     # quasi tota la pàgina
    )
    # 🏛️ Franja superior esquerra
    c.translate(1 * cm, 18* cm)
    c.rotate(90)

    # 🟦 Text institucional
    c.setFont("Helvetica", 7)
    c.setFillColorRGB(0.12, 0.31, 0.85)
    c.drawString(0, 5, "Signat manualment")
    c.drawString(0, -5, datetime.now().strftime("%d/%m/%Y %H:%M"))
    c.drawString(0, -15, f"Ref: {referencia}")


    # 🖊️ Firma → A LA DRETA DEL TEXT
    c.drawInlineImage(
        signatura_img,
        70,          # ← DESPLAÇAMENT A LA DRETA (CLAU)
        -25,         # alineada amb el text
        width=4 * cm,
        height=1.4 * cm
    )

    c.restoreState()
    # 🔹 TEXT LEGAL I VERIFICACIÓ (BAIX DE TOT)
    c.setFont("Helvetica", 7)
    c.setFillColorRGB(0.4, 0.4, 0.4)  # gris elegant

    y_base = 1.4 * cm  # marge inferior base

    c.drawString(
        3 * cm,
        y_base + 36,
        "Document signat manualment. La integritat del document està garantida mitjançant hash criptogràfic."
    )

    c.drawString(
        3 * cm,
        y_base + 24,
        f"Referència: {referencia} · Data: {datetime.now().strftime('%d/%m/%Y %H:%M')}"
    )

    c.setFont("Helvetica", 6)
    c.drawString(
        3 * cm,
        y_base + 12,
        f"Hash SHA-256: {hash_pdf}"
    )

    # 🔗 Enllaç de verificació
    c.setFont("Helvetica", 7)
    c.setFillColorRGB(0.12, 0.31, 0.85)  # blau enllaç

    c.drawString(
        3 * cm,
        y_base,
        url_verificacio
    )

    c.linkURL(
        url_verificacio,
        (
            3 * cm,
            y_base - 2,
            18 * cm,
            y_base + 8
        ),
        relative=0
    )

    c.save()
    packet.seek(0)
    signatura_pdf = PdfReader(packet)

    # 🔹 4. Superposar la signatura a la primera pàgina
    base_page = pdf_reader.pages[0]
    base_page.merge_page(signatura_pdf.pages[0])

    pdf_writer.add_page(base_page)

    # 🔹 5. Afegir la resta de pàgines (si n’hi ha)
    for page in pdf_reader.pages[1:]:
        pdf_writer.add_page(page)

    # 🔹 6. Retornar PDF final en base64
    output = io.BytesIO()
    pdf_writer.write(output)

    return base64.b64encode(output.getvalue())
