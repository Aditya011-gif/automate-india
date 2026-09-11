import os
import datetime
import pymupdf
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image as RLImage, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.graphics.shapes import Drawing, Rect, String, Group
from reportlab.graphics.barcode import qr
import subprocess

# Paths
artifact_dir = r"C:\Users\adity\.gemini\antigravity-ide\brain\7d1c9c60-22a3-4ece-ace1-07fd87e477b6"
os.makedirs(artifact_dir, exist_ok=True)
pdf_path = os.path.join(artifact_dir, "real_esign_contract_sample.pdf")
png_page1_path = os.path.join(artifact_dir, "contract_preview_page1.png")
png_page2_path = os.path.join(artifact_dir, "contract_preview_page2.png")

doc = SimpleDocTemplate(
    pdf_path,
    pagesize=A4,
    leftMargin=14*mm,
    rightMargin=14*mm,
    topMargin=14*mm,
    bottomMargin=14*mm
)

styles = getSampleStyleSheet()

title_style = ParagraphStyle(
    'DocTitle',
    fontName='Helvetica-Bold',
    fontSize=11,
    textColor=colors.white,
    alignment=1,
    spaceAfter=2
)
subtitle_style = ParagraphStyle(
    'DocSubTitle',
    fontName='Helvetica',
    fontSize=7,
    textColor=colors.HexColor('#dcfce7'),
    alignment=1
)
sec_heading = ParagraphStyle(
    'SecHeading',
    fontName='Helvetica-Bold',
    fontSize=8.5,
    textColor=colors.HexColor('#14532d'),
    spaceBefore=8,
    spaceAfter=4
)
body_small = ParagraphStyle(
    'BodySmall',
    fontName='Helvetica',
    fontSize=7,
    textColor=colors.HexColor('#1f2937'),
    leading=9
)
body_bold = ParagraphStyle(
    'BodyBold',
    fontName='Helvetica-Bold',
    fontSize=7,
    textColor=colors.HexColor('#111827'),
    leading=9
)
clause_title = ParagraphStyle(
    'ClauseTitle',
    fontName='Helvetica-Bold',
    fontSize=7,
    textColor=colors.HexColor('#15803d'),
    leading=9
)
clause_body = ParagraphStyle(
    'ClauseBody',
    fontName='Helvetica',
    fontSize=6.5,
    textColor=colors.HexColor('#374151'),
    leading=8.5
)

# DSC Signature Text Styles
sig_valid_title = ParagraphStyle(
    'SigValidTitle',
    fontName='Helvetica-Bold',
    fontSize=9,
    textColor=colors.HexColor('#15803d'),
    leading=11
)
sig_meta_label = ParagraphStyle(
    'SigMetaLabel',
    fontName='Helvetica-Bold',
    fontSize=6,
    textColor=colors.HexColor('#4b5563'),
    leading=8
)
sig_meta_val = ParagraphStyle(
    'SigMetaVal',
    fontName='Helvetica',
    fontSize=6,
    textColor=colors.HexColor('#111827'),
    leading=8
)
sig_meta_val_bold = ParagraphStyle(
    'SigMetaValBold',
    fontName='Helvetica-Bold',
    fontSize=6.5,
    textColor=colors.HexColor('#14532d'),
    leading=8.5
)

story = []

# --- TOP PROTOCOL HEADER ---
header_data = [
    [
        Paragraph("<b>AGRICHAIN DECENTRALIZED PROTOCOL</b><br/><font size=6 color='#4b5563'>Direct-from-Farmer Trade & Smart Escrow Engine</font>", body_bold),
        Paragraph("<b>ORDER REF:</b> RET-48768<br/><b>CONTRACT:</b> CONTRACT_1789115846760", ParagraphStyle('RightH', parent=body_small, alignment=2))
    ]
]
t_header = Table(header_data, colWidths=[110*mm, 72*mm])
t_header.setStyle(TableStyle([
    ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ('LINEBELOW', (0,0), (-1,-1), 1, colors.HexColor('#15803d'))
]))
story.append(t_header)
story.append(Spacer(1, 3*mm))

# --- TITLE BANNER ---
banner_data = [[
    Paragraph("AGRICULTURAL ELECTRONIC TRADE & SMART ESCROW CONTRACT", title_style),
    Paragraph("Legally Binding under Indian Contract Act 1872 (Sec 10) & Information Technology Act 2000 (Sec 4, 5, 10A)", subtitle_style)
]]
t_banner = Table([[banner_data[0][0]], [banner_data[0][1]]], colWidths=[182*mm])
t_banner.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#15803d')),
    ('ALIGN', (0,0), (-1,-1), 'CENTER'),
    ('TOPPADDING', (0,0), (-1,-1), 4),
    ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ('LEFTPADDING', (0,0), (-1,-1), 6),
    ('RIGHTPADDING', (0,0), (-1,-1), 6),
]))
story.append(t_banner)
story.append(Spacer(1, 3*mm))

# --- BLOCKCHAIN & ESCROW LEDGER SUMMARY ---
ledger_data = [
    [
        Paragraph("<b>POLYGON PoS SMART ESCROW STATE (ERC-173)</b>", ParagraphStyle('P1', fontName='Helvetica-Bold', fontSize=7, textColor=colors.HexColor('#14532d'))),
        Paragraph("<b>STATUS: ESCROW_LOCKED (100% INR)</b>", ParagraphStyle('P2', fontName='Helvetica-Bold', fontSize=7, textColor=colors.HexColor('#15803d'), alignment=2))
    ],
    [
        Paragraph("<b>Contract Address:</b> 0x71C8A56E38F14E1825B3E7A3E2f9a2D8B9238e12<br/>"
                  "<b>Polygon TxHash:</b> 0x9b4c27f3e82910dc8172039abed9102c847192bc7291a8e72<br/>"
                  "<b>Block Number:</b> #6428921 (Polygon PoS Mainnet Anchor)", ParagraphStyle('Ledg1', parent=body_small, fontSize=6, leading=7.5)),
        Paragraph("<b>Cryptographic Deal Hash:</b> 8f7e21a08b9c...e4318c2b<br/>"
                  "<b>Delivery Verification OTP:</b> [Generated On Escrow Lock: 482915]<br/>"
                  "<b>Gasless Relayer:</b> EIP-2771 Gas Sponsored by AgriChain", ParagraphStyle('Ledg2', parent=body_small, fontSize=6, leading=7.5))
    ]
]
t_ledger = Table(ledger_data, colWidths=[96*mm, 86*mm])
t_ledger.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f0fdf4')),
    ('BOX', (0,0), (-1,-1), 0.8, colors.HexColor('#86efac')),
    ('TOPPADDING', (0,0), (-1,-1), 3),
    ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ('LEFTPADDING', (0,0), (-1,-1), 5),
    ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ('LINEBELOW', (0,0), (-1,0), 0.5, colors.HexColor('#bbf7d0')),
]))
story.append(t_ledger)
story.append(Spacer(1, 2*mm))

# --- SECTION 1: PARTIES ---
story.append(Paragraph("1. CONTRACTING PARTIES & STATUTORY DETAILS", sec_heading))
parties_data = [
    [
        Paragraph("<b>PARTY A: SELLER / PRODUCER</b><br/>"
                  "<b>Name:</b> Rajesh Verma (Verified Farmer)<br/>"
                  "<b>Identity Ref:</b> Aadhaar UIDAI e-KYC Verified<br/>"
                  "<b>Cluster / Hub:</b> Karnal Agricultural Cluster, Haryana<br/>"
                  "<b>Wallet:</b> 0xFarmer_Rajesh_Verma", ParagraphStyle('P_A', parent=body_small, fontSize=6.5, leading=8)),
        Paragraph("<b>PARTY B: BUYER / PROCUREMENT ENTITY</b><br/>"
                  "<b>Name:</b> Aditya Sharma<br/>"
                  "<b>Identity Ref:</b> Aadhaar e-Sign Verified (DigiLocker / MeriPehchaan)<br/>"
                  "<b>Delivery Address:</b> Sector 14, Urban Estate, Karnal, Haryana<br/>"
                  "<b>Wallet:</b> 0xBuyer_9876543210", ParagraphStyle('P_B', parent=body_small, fontSize=6.5, leading=8))
    ]
]
t_parties = Table(parties_data, colWidths=[91*mm, 91*mm])
t_parties.setStyle(TableStyle([
    ('BOX', (0,0), (0,0), 0.5, colors.HexColor('#cbd5e1')),
    ('BOX', (1,0), (1,0), 0.5, colors.HexColor('#cbd5e1')),
    ('BACKGROUND', (0,0), (0,0), colors.HexColor('#f8fafc')),
    ('BACKGROUND', (1,0), (1,0), colors.HexColor('#f8fafc')),
    ('PADDING', (0,0), (-1,-1), 4),
]))
story.append(t_parties)
story.append(Spacer(1, 2*mm))

# --- SECTION 2: COMMODITY & SETTLEMENT PARTICULARS ---
story.append(Paragraph("2. COMMODITY & FINANCIAL ESCROW PARTICULARS", sec_heading))
comm_data = [
    [Paragraph("<b>Item Description</b>", body_bold), Paragraph("<b>Grade / Specification</b>", body_bold), Paragraph("<b>Quantity</b>", body_bold), Paragraph("<b>Rate (INR)</b>", body_bold), Paragraph("<b>Total Consideration</b>", body_bold)],
    [Paragraph("Certified Sharbati Wheat", body_small), Paragraph("Grade A (Moisture < 11.2%)", body_small), Paragraph("100.00 Quintals", body_small), Paragraph("Rs 2,850.00 / Qtl", body_small), Paragraph("Rs 2,85,000.00", body_bold)],
    [Paragraph("Direct Express Farm-to-Dock Freight", body_small), Paragraph("Dedicated GPS Monitored FTL", body_small), Paragraph("1 Consignment", body_small), Paragraph("Standard Rate", body_small), Paragraph("FREE (Direct Route)", body_small)],
    [Paragraph("<b>TOTAL ESCROW CAPITAL</b>", body_bold), Paragraph("<b>100% Fiat INR via Instant UPI Escrow</b>", body_small), Paragraph("<b>100 Qtl</b>", body_bold), Paragraph("-", body_small), Paragraph("<b>Rs 2,85,000.00</b>", ParagraphStyle('Tot', fontName='Helvetica-Bold', fontSize=7.5, textColor=colors.HexColor('#14532d')))],
]
t_comm = Table(comm_data, colWidths=[48*mm, 44*mm, 26*mm, 28*mm, 36*mm])
t_comm.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#f1f5f9')),
    ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#e2e8f0')),
    ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor('#f0fdf4')),
    ('PADDING', (0,0), (-1,-1), 3),
]))
story.append(t_comm)
story.append(Spacer(1, 2*mm))

# --- SECTION 3: LEGAL CLAUSES ---
story.append(Paragraph("3. STATUTORY COVENANTS (IT ACT 2000 & INDIAN CONTRACT ACT 1872)", sec_heading))
clause_text = (
    "<b>Clause 1 (Section 10A IT Act 2000 Electronic Validity):</b> The parties agree that this contract is formed, agreed, and executed in electronic form. Contracts formed through electronic records and digital signatures are legally enforceable under Section 10A of the Information Technology Act, 2000.<br/>"
    "<b>Clause 2 (Aadhaar e-Sign & DSC Recognition):</b> Electronic signatures affixed below comply with the Digital Signature Rules, 2000 and Section 3A of the IT Act, backed by identity verification through UIDAI / DigiLocker (MeriPehchaan).<br/>"
    "<b>Clause 3 (Smart Escrow Security):</b> Consideration of ₹2,85,000 is cryptographically locked in smart contract 0x71C8... Disbursal occurs automatically upon physical delivery OTP verification."
)
t_clauses = Table([[Paragraph(clause_text, clause_body)]], colWidths=[182*mm])
t_clauses.setStyle(TableStyle([
    ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#cbd5e1')),
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f8fafc')),
    ('PADDING', (0,0), (-1,-1), 4),
]))
story.append(t_clauses)
story.append(Spacer(1, 3*mm))

# --- SECTION 4: REAL GOVERNMENT STANDARD DIGITAL SIGNATURES ---
story.append(Paragraph("4. OFFICIAL CCA-COMPLIANT DIGITAL SIGNATURE CERTIFICATES (DSC)", sec_heading))

# Helper to generate a QR barcode flowable
def make_qr(data):
    qr_code = qr.QrCodeWidget(data)
    d = Drawing(42, 42)
    qr_code.barWidth = 42
    qr_code.barHeight = 42
    qr_code.barBorder = 0
    qr_code.qrVersion = 2
    d.add(qr_code)
    return d

now_str = datetime.datetime.now().strftime("%Y.%m.%d %H:%M:%S +05'30'")

# 1. Farmer QR: Live Polygonscan Smart Contract Explorer (opens immediately in phone browser)
farmer_qr = make_qr("https://amoy.polygonscan.com/address/0x71C8A56E38F14E1825B3E7A3E2f9a2D8B9238e12")

# 2. Buyer QR: Official UIDAI Offline Cryptographic Certificate Card (pops up directly on phone camera)
buyer_qr_text = (
    "✔ AADHAAR e-SIGN VERIFIED\n"
    "Signer: ADITYA SHARMA\n"
    "Role: Buyer / Procurement\n"
    "Aadhaar Ref: XXXX-XXXX-7829\n"
    "Cert ID: PRT-ESIGN-7829-DEL\n"
    "Status: UIDAI CIDR VERIFIED\n"
    "Law: Sec 3A & 10A IT Act 2000\n"
    "Escrow: 0x71C8A56E38F14E1825B3E7A3E2f9a2D8B9238e12\n"
    "Explorer: https://amoy.polygonscan.com/address/0x71C8A56E38F14E1825B3E7A3E2f9a2D8B9238e12"
)
buyer_qr = make_qr(buyer_qr_text)

# Real Indian Standard DSC appearance block for Farmer
farmer_dsc_content = [
    # Top banner of DSC box
    [
        Paragraph("<b>✔ Signature Valid</b>", sig_valid_title),
        Paragraph("<font size=5.5 color='#15803d'><b>UIDAI e-KYC VERIFIED</b></font>", ParagraphStyle('TopR1', alignment=2))
    ],
    [
        Paragraph("<b>Digitally signed by:</b> RAJESH VERMA<br/>"
                  "<b>Date:</b> " + now_str + "<br/>"
                  "<b>Reason:</b> AgriChain Agricultural Sale Execution (Sec 10A IT Act)<br/>"
                  "<b>Location:</b> Karnal Agri-Cluster, Haryana, India<br/>"
                  "<b>Signer ID:</b> XXXX-XXXX-8921 (UIDAI CIDR Verified)<br/>"
                  "<b>Certificate Authority:</b> Controller of Certifying Authorities (CCA) / C-DAC e-Hastakshar CA<br/>"
                  "<b>SHA-256 Digest:</b> c447aa21e36207881a1fa73e86c0b991...<br/>"
                  "<b>Compliance:</b> Legally valid under Section 3A & 10A, IT Act 2000", sig_meta_val),
        farmer_qr
    ]
]
t_farmer_dsc = Table(farmer_dsc_content, colWidths=[66*mm, 21*mm])
t_farmer_dsc.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f0fdf4')),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('ALIGN', (1,1), (1,1), 'CENTER'),
    ('BOTTOMPADDING', (0,0), (-1,-1), 2),
    ('TOPPADDING', (0,0), (-1,-1), 2),
    ('LEFTPADDING', (0,0), (-1,-1), 3),
    ('RIGHTPADDING', (0,0), (-1,-1), 3),
]))

# Real Indian Standard DSC appearance block for Buyer
buyer_dsc_content = [
    # Top banner of DSC box
    [
        Paragraph("<b>✔ Signature Valid</b>", sig_valid_title),
        Paragraph("<font size=5.5 color='#15803d'><b>MERIPEHCHAAN e-SIGN</b></font>", ParagraphStyle('TopR2', alignment=2))
    ],
    [
        Paragraph("<b>Digitally signed by:</b> ADITYA SHARMA<br/>"
                  "<b>Date:</b> " + now_str + "<br/>"
                  "<b>Reason:</b> Mutual Assent & 100% Escrow Capital Allocation<br/>"
                  "<b>Location:</b> New Delhi / Haryana, India<br/>"
                  "<b>Signer ID:</b> XXXX-XXXX-7829 (DigiLocker Verified)<br/>"
                  "<b>Certificate Authority:</b> Controller of Certifying Authorities (CCA) / eMudhra Sub-CA<br/>"
                  "<b>SHA-256 Digest:</b> c36d718804c2aa83100ba031d4592e62...<br/>"
                  "<b>Compliance:</b> Legally valid under Section 3A & 10A, IT Act 2000", sig_meta_val),
        buyer_qr
    ]
]
t_buyer_dsc = Table(buyer_dsc_content, colWidths=[66*mm, 21*mm])
t_buyer_dsc.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f0fdf4')),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('ALIGN', (1,1), (1,1), 'CENTER'),
    ('BOTTOMPADDING', (0,0), (-1,-1), 2),
    ('TOPPADDING', (0,0), (-1,-1), 2),
    ('LEFTPADDING', (0,0), (-1,-1), 3),
    ('RIGHTPADDING', (0,0), (-1,-1), 3),
]))

# Wrap in side-by-side outer boxes
signatures_row = [
    [
        Table([
            [Paragraph("<b>PARTY A (SELLER / PRODUCER e-SIGN)</b>", ParagraphStyle('SH1', fontName='Helvetica-Bold', fontSize=6.5, textColor=colors.HexColor('#14532d')))],
            [t_farmer_dsc]
        ], colWidths=[89*mm]),
        Table([
            [Paragraph("<b>PARTY B (BUYER / PROCUREMENT ENTITY e-SIGN)</b>", ParagraphStyle('SH2', fontName='Helvetica-Bold', fontSize=6.5, textColor=colors.HexColor('#14532d')))],
            [t_buyer_dsc]
        ], colWidths=[89*mm])
    ]
]
t_signatures = Table(signatures_row, colWidths=[91*mm, 91*mm])
t_signatures.setStyle(TableStyle([
    ('BOX', (0,0), (0,0), 1, colors.HexColor('#15803d')),
    ('BOX', (1,0), (1,0), 1, colors.HexColor('#15803d')),
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f0fdf4')),
    ('TOPPADDING', (0,0), (-1,-1), 3),
    ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ('LEFTPADDING', (0,0), (-1,-1), 3),
    ('RIGHTPADDING', (0,0), (-1,-1), 3),
]))
story.append(t_signatures)
story.append(Spacer(1, 3*mm))

# --- BOTTOM GOVERNMENT & BLOCKCHAIN LEDGER FOOTER ---
footer_data = [[
    Paragraph("AgriChain Decentralized Ledger • Tamper-Evident Electronic Record • Amoy Testnet & Mainnet Anchor • Legally Binding Electronic Contract", 
              ParagraphStyle('Foot', fontName='Helvetica-Bold', fontSize=6, textColor=colors.HexColor('#4b5563'), alignment=1))
]]
t_foot = Table(footer_data, colWidths=[182*mm])
t_foot.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f1f5f9')),
    ('ALIGN', (0,0), (-1,-1), 'CENTER'),
    ('PADDING', (0,0), (-1,-1), 3),
    ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#cbd5e1'))
]))
story.append(t_foot)

doc.build(story)
print("PDF built successfully at:", pdf_path)

# Render PDF page to PNG with PyMuPDF
pdf_doc = pymupdf.open(pdf_path)
print(f"Total pages: {len(pdf_doc)}")
for i, page in enumerate(pdf_doc):
    pix = page.get_pixmap(dpi=180)
    out_img = os.path.join(artifact_dir, f"real_esign_preview_page_{i+1}.png")
    pix.save(out_img)
    print(f"Saved page {i+1} preview image to: {out_img}")

