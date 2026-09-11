import os
import datetime
import pymupdf
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.graphics.shapes import Drawing, Rect, String, Group, Circle
from reportlab.graphics.barcode import qr

artifact_dir = r"C:\Users\adity\.gemini\antigravity-ide\brain\7d1c9c60-22a3-4ece-ace1-07fd87e477b6"
os.makedirs(artifact_dir, exist_ok=True)
pdf_path = os.path.join(artifact_dir, "esign_options_showcase.pdf")

doc = SimpleDocTemplate(
    pdf_path,
    pagesize=A4,
    leftMargin=12*mm,
    rightMargin=12*mm,
    topMargin=10*mm,
    bottomMargin=10*mm
)

styles = getSampleStyleSheet()

def make_qr(data, size=38):
    qr_code = qr.QrCodeWidget(data)
    d = Drawing(size, size)
    qr_code.barWidth = size
    qr_code.barHeight = size
    qr_code.barBorder = 0
    qr_code.qrVersion = 2
    d.add(qr_code)
    return d

now_str = datetime.datetime.now().strftime("%Y.%m.%d %H:%M:%S +05'30'")

story = []

# Header
story.append(Paragraph("<b>AGRICHAIN • REAL-WORLD e-SIGNATURE OPTIONS COMPARISON</b>", 
                       ParagraphStyle('H1', fontName='Helvetica-Bold', fontSize=13, textColor=colors.HexColor('#0f172a'), alignment=1)))
story.append(Paragraph("Visual demonstration of how real legal & government electronic signature providers render signatures", 
                       ParagraphStyle('H2', fontName='Helvetica', fontSize=8, textColor=colors.HexColor('#64748b'), alignment=1, spaceAfter=8)))

# -------------------------------------------------------------
# OPTION 1: NSDL / PROTEAN e-GOV AADHAAR e-SIGN
# -------------------------------------------------------------
p_opt1_title = Paragraph("<b>OPTION 1: NSDL / Protean e-Gov Official Aadhaar e-Sign Stamp</b>", 
                         ParagraphStyle('O1T', fontName='Helvetica-Bold', fontSize=9, textColor=colors.HexColor('#14532d')))
p_opt1_desc = Paragraph("Used by Income Tax Department, MCA, and Indian stockbrokers. Classic government-standard DSC format.", 
                        ParagraphStyle('O1D', fontName='Helvetica', fontSize=6.5, textColor=colors.HexColor('#475569'), spaceAfter=4))
story.append(p_opt1_title)
story.append(p_opt1_desc)

opt1_farmer_qr = make_qr("https://esign.protean-tin.com/verify?doc=AGRI-RET-48768&cert=PRT-2026-8921")
opt1_buyer_qr = make_qr("https://esign.protean-tin.com/verify?doc=AGRI-RET-48768&cert=PRT-2026-7829")

def build_nsdl_box(signer, aadhaar, role, qr_code, cert_id):
    content = [
        [
            Paragraph("<b>PROTEAN e-GOV TECHNOLOGIES LIMITED • AADHAAR e-SIGN</b>", 
                      ParagraphStyle('NB1', fontName='Helvetica-Bold', fontSize=6, textColor=colors.HexColor('#065f46'))),
            Paragraph("<b>UIDAI OKYC VERIFIED</b>", 
                      ParagraphStyle('NB2', fontName='Helvetica-Bold', fontSize=5.5, textColor=colors.HexColor('#047857'), alignment=2))
        ],
        [
            Paragraph(f"<font size=8 color='#047857'><b>✔ Signature Valid</b></font><br/>"
                      f"<b>Digitally Signed By:</b> {signer}<br/>"
                      f"<b>Signer Role:</b> {role}<br/>"
                      f"<b>Aadhaar Ref:</b> {aadhaar} (UIDAI CIDR OTP Verified)<br/>"
                      f"<b>Signing Time:</b> {now_str}<br/>"
                      f"<b>Certificate Authority:</b> Protean (NSDL) eGov Sub-CA 2026<br/>"
                      f"<b>Certificate ID:</b> {cert_id}<br/>"
                      f"<b>Reason:</b> Legal Assent & Smart Escrow Execution (Sec 10A IT Act)", 
                      ParagraphStyle('NC', fontName='Helvetica', fontSize=5.8, leading=7.5)),
            qr_code
        ]
    ]
    t = Table(content, colWidths=[66*mm, 20*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f0fdf4')),
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#059669')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ALIGN', (1,1), (1,1), 'CENTER'),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 3),
        ('RIGHTPADDING', (0,0), (-1,-1), 3),
    ]))
    return t

t_opt1_row = Table([[
    build_nsdl_box("RAJESH VERMA", "XXXX-XXXX-8921", "Producer / Farmer", opt1_farmer_qr, "PRT-ESIGN-8921-HRY"),
    build_nsdl_box("ADITYA SHARMA", "XXXX-XXXX-7829", "Buyer / Procurement", opt1_buyer_qr, "PRT-ESIGN-7829-DEL")
]], colWidths=[93*mm, 93*mm])
t_opt1_row.setStyle(TableStyle([
    ('PADDING', (0,0), (-1,-1), 0),
    ('VALIGN', (0,0), (-1,-1), 'TOP')
]))
story.append(t_opt1_row)
story.append(Spacer(1, 4*mm))

# -------------------------------------------------------------
# OPTION 2: ZOOP.ONE / LEEGALITY ENTERPRISE LEGAL TECH STAMP
# -------------------------------------------------------------
p_opt2_title = Paragraph("<b>OPTION 2: Zoop.one / Leegality Enterprise LegalTech Audit Seal</b>", 
                         ParagraphStyle('O2T', fontName='Helvetica-Bold', fontSize=9, textColor=colors.HexColor('#1e3a8a')))
p_opt2_desc = Paragraph("Used by top Indian banks (HDFC, ICICI, Tata Capital) & AgriTech enterprises. Includes Document Audit Trail & UDIN.", 
                        ParagraphStyle('O2D', fontName='Helvetica', fontSize=6.5, textColor=colors.HexColor('#475569'), spaceAfter=4))
story.append(p_opt2_title)
story.append(p_opt2_desc)

opt2_farmer_qr = make_qr("https://verify.zoop.one/audit/ZOOPSIGN-AGRI-8921-2026")
opt2_buyer_qr = make_qr("https://verify.zoop.one/audit/ZOOPSIGN-AGRI-7829-2026")

def build_zoop_box(signer, aadhaar, ip_addr, qr_code, audit_id):
    content = [
        [
            Paragraph("<b>ZOOPSIGN LEGALTECH • SECURE AADHAAR e-SIGN</b>", 
                      ParagraphStyle('ZB1', fontName='Helvetica-Bold', fontSize=6, textColor=colors.HexColor('#1e40af'))),
            Paragraph(f"<b>AUDIT: {audit_id}</b>", 
                      ParagraphStyle('ZB2', fontName='Helvetica-Bold', fontSize=5.5, textColor=colors.HexColor('#1d4ed8'), alignment=2))
        ],
        [
            Paragraph(f"<font size=8 color='#1e40af'><b>✔ Digitally Signed & Authenticated</b></font><br/>"
                      f"<b>Signer:</b> {signer}<br/>"
                      f"<b>Auth Mode:</b> Aadhaar OTP (UIDAI e-KYC 2.1)<br/>"
                      f"<b>Aadhaar Ref:</b> {aadhaar} | <b>Signer IP:</b> {ip_addr}<br/>"
                      f"<b>Timestamp:</b> {now_str}<br/>"
                      f"<b>ESP Gateway:</b> Zoop.one Technologies / CCA Licensed ESP<br/>"
                      f"<b>Doc Hash:</b> c447aa21e36207881a1fa73e86c0b991...<br/>"
                      f"<b>Legal Validity:</b> Section 10A IT Act, 2000 & Evidence Act 1872", 
                      ParagraphStyle('ZC', fontName='Helvetica', fontSize=5.8, leading=7.5)),
            qr_code
        ]
    ]
    t = Table(content, colWidths=[66*mm, 20*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#eff6ff')),
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#3b82f6')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ALIGN', (1,1), (1,1), 'CENTER'),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 3),
        ('RIGHTPADDING', (0,0), (-1,-1), 3),
    ]))
    return t

t_opt2_row = Table([[
    build_zoop_box("RAJESH VERMA", "XXXX-XXXX-8921", "103.241.132.14", opt2_farmer_qr, "Z-AGRI-8921"),
    build_zoop_box("ADITYA SHARMA", "XXXX-XXXX-7829", "122.160.180.45", opt2_buyer_qr, "Z-AGRI-7829")
]], colWidths=[93*mm, 93*mm])
t_opt2_row.setStyle(TableStyle([
    ('PADDING', (0,0), (-1,-1), 0),
    ('VALIGN', (0,0), (-1,-1), 'TOP')
]))
story.append(t_opt2_row)
story.append(Spacer(1, 4*mm))

# -------------------------------------------------------------
# OPTION 3: C-DAC e-HASTAKSHAR (GOVERNMENT OF INDIA / MeitY)
# -------------------------------------------------------------
p_opt3_title = Paragraph("<b>OPTION 3: C-DAC e-Hastakshar (Govt of India / MeitY Official Gateway)</b>", 
                         ParagraphStyle('O3T', fontName='Helvetica-Bold', fontSize=9, textColor=colors.HexColor('#9a3412')))
p_opt3_desc = Paragraph("Official Ministry of Electronics & IT (MeitY) national e-Sign portal with Tri-color branding.", 
                        ParagraphStyle('O3D', fontName='Helvetica', fontSize=6.5, textColor=colors.HexColor('#475569'), spaceAfter=4))
story.append(p_opt3_title)
story.append(p_opt3_desc)

opt3_farmer_qr = make_qr("https://ehastakshar.gov.in/verify?txn=CDAC-2026-8921")
opt3_buyer_qr = make_qr("https://ehastakshar.gov.in/verify?txn=CDAC-2026-7829")

def build_cdac_box(signer, aadhaar, role, qr_code, cert_id):
    content = [
        [
            Paragraph("<b>e-HASTAKSHAR • C-DAC / MeitY (GOVERNMENT OF INDIA)</b>", 
                      ParagraphStyle('CB1', fontName='Helvetica-Bold', fontSize=6, textColor=colors.HexColor('#9a3412'))),
            Paragraph("<b>UIDAI CIDR ASSENT</b>", 
                      ParagraphStyle('CB2', fontName='Helvetica-Bold', fontSize=5.5, textColor=colors.HexColor('#ea580c'), alignment=2))
        ],
        [
            Paragraph(f"<font size=8 color='#c2410c'><b>✔ Digital Signature Verified</b></font><br/>"
                      f"<b>Signatory Name:</b> {signer}<br/>"
                      f"<b>Signatory Role:</b> {role}<br/>"
                      f"<b>Aadhaar UID:</b> {aadhaar} (Biometric / OTP Verified)<br/>"
                      f"<b>Timestamp:</b> {now_str}<br/>"
                      f"<b>CA:</b> C-DAC e-Hastakshar CA 2026 (CCA Accredited)<br/>"
                      f"<b>TSA Token:</b> CDAC-TSA-HRY-{cert_id}<br/>"
                      f"<b>Statutory Law:</b> IT Act 2000 Schedule 2 & Model APMC Direct Trade", 
                      ParagraphStyle('CC', fontName='Helvetica', fontSize=5.8, leading=7.5)),
            qr_code
        ]
    ]
    t = Table(content, colWidths=[66*mm, 20*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#fff7ed')),
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#f97316')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ALIGN', (1,1), (1,1), 'CENTER'),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 3),
        ('RIGHTPADDING', (0,0), (-1,-1), 3),
    ]))
    return t

t_opt3_row = Table([[
    build_cdac_box("RAJESH VERMA", "XXXX-XXXX-8921", "Producer / Farmer", opt3_farmer_qr, "CDAC-8921"),
    build_cdac_box("ADITYA SHARMA", "XXXX-XXXX-7829", "Direct Buyer", opt3_buyer_qr, "CDAC-7829")
]], colWidths=[93*mm, 93*mm])
t_opt3_row.setStyle(TableStyle([
    ('PADDING', (0,0), (-1,-1), 0),
    ('VALIGN', (0,0), (-1,-1), 'TOP')
]))
story.append(t_opt3_row)
story.append(Spacer(1, 4*mm))

# -------------------------------------------------------------
# OPTION 4: ADOBE / DOCUSIGN CERTIFICATE OF EXECUTION SEAL
# -------------------------------------------------------------
p_opt4_title = Paragraph("<b>OPTION 4: Adobe Sign / DigiLocker Merit Deed Seal</b>", 
                         ParagraphStyle('O4T', fontName='Helvetica-Bold', fontSize=9, textColor=colors.HexColor('#4c1d95')))
p_opt4_desc = Paragraph("Used in international trade & high-value agricultural B2B procurement contracts.", 
                        ParagraphStyle('O4D', fontName='Helvetica', fontSize=6.5, textColor=colors.HexColor('#475569'), spaceAfter=4))
story.append(p_opt4_title)
story.append(p_opt4_desc)

opt4_farmer_qr = make_qr("https://agrichain.gov.in/vault/cert/8921-ESCROW")
opt4_buyer_qr = make_qr("https://agrichain.gov.in/vault/cert/7829-ESCROW")

def build_adobe_box(signer, aadhaar, org, qr_code, doc_id):
    content = [
        [
            Paragraph("<b>CERTIFIED SECURE DIGITAL SIGNATURE (ISO 32000-1 / PAdES)</b>", 
                      ParagraphStyle('AB1', fontName='Helvetica-Bold', fontSize=6, textColor=colors.HexColor('#5b21b6'))),
            Paragraph(f"<b>SEAL: {doc_id}</b>", 
                      ParagraphStyle('AB2', fontName='Helvetica-Bold', fontSize=5.5, textColor=colors.HexColor('#6d28d9'), alignment=2))
        ],
        [
            Paragraph(f"<font size=8 color='#5b21b6'><b>✔ Adobe Certified Document Service (CDS)</b></font><br/>"
                      f"<b>Signer Name:</b> {signer}<br/>"
                      f"<b>Organization / Entity:</b> {org}<br/>"
                      f"<b>National ID Ref:</b> {aadhaar} (DigiLocker Verified)<br/>"
                      f"<b>Signing Time:</b> {now_str}<br/>"
                      f"<b>Security Profile:</b> RSA 2048-bit • SHA-256 PKCS#7 Incremental<br/>"
                      f"<b>Escrow Binding:</b> Polygon PoS Escrow Vault Contract Anchor<br/>"
                      f"<b>Integrity:</b> Document unaltered since signature was applied", 
                      ParagraphStyle('AC', fontName='Helvetica', fontSize=5.8, leading=7.5)),
            qr_code
        ]
    ]
    t = Table(content, colWidths=[66*mm, 20*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#faf5ff')),
        ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#8b5cf6')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ALIGN', (1,1), (1,1), 'CENTER'),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('LEFTPADDING', (0,0), (-1,-1), 3),
        ('RIGHTPADDING', (0,0), (-1,-1), 3),
    ]))
    return t

t_opt4_row = Table([[
    build_adobe_box("RAJESH VERMA", "XXXX-XXXX-8921", "Karnal FPO Producer Cooperative", opt4_farmer_qr, "FPO-8921"),
    build_adobe_box("ADITYA SHARMA", "XXXX-XXXX-7829", "Institutional Procurement Entity", opt4_buyer_qr, "BUY-7829")
]], colWidths=[93*mm, 93*mm])
t_opt4_row.setStyle(TableStyle([
    ('PADDING', (0,0), (-1,-1), 0),
    ('VALIGN', (0,0), (-1,-1), 'TOP')
]))
story.append(t_opt4_row)

doc.build(story)
print("Showcase PDF built successfully at:", pdf_path)

# Render to high-res PNG image
pdf_doc = pymupdf.open(pdf_path)
pix = pdf_doc[0].get_pixmap(dpi=180)
out_img = os.path.join(artifact_dir, "esign_options_showcase.png")
pix.save(out_img)
print(f"Saved showcase image to: {out_img}")
