# 📱 AgriChain: Complete User Profiles & UI/UX Screen Specification Manual

**Comprehensive Software Requirements Specification (SRS), Screen Inventory, UI/UX Wireframes, Field-by-Field Rules, Role-Based Access Control (RBAC), and Frontend Architecture for All 4 User Profiles (100% Loan-Free Production Design)**  
*Smart India Hackathon 2026 | Master Frontend & System Design Document*

---

## 📑 Table of Contents
1. [Executive Overview & Architectural Refinement](#1-executive-overview--architectural-refinement)
2. [Master Screen Inventory & Role-Based Access Control (RBAC)](#2-master-screen-inventory--role-based-access-control-rbac)
3. [Universal Auth & 1-Time KYC Module (5 Screens)](#3-universal-auth--1-time-kyc-module-5-screens)
4. [Profile 1: Individual Farmer (Kisaan) Specification (5 Screens)](#4-profile-1-individual-farmer-kisaan-specification-5-screens)
5. [Profile 2: Bulk Seller (FPO / Cooperative) Specification (5 Screens)](#5-profile-2-bulk-seller-fpo--cooperative-specification-5-screens)
6. [Profile 3: Bulk Institutional Buyer (Mill / FMCG) Specification (6 Screens)](#6-profile-3-bulk-institutional-buyer-mill--fmcg-specification-6-screens)
7. [Profile 4: Retail Consumer / D2C Buyer Specification (4 Screens)](#7-profile-4-retail-consumer--d2c-buyer-specification-4-screens)
8. [Shared Telematics, Legal & Governance Modules (3 Screens)](#8-shared-telematics-legal--governance-modules-3-screens)
9. [Copy-Paste AI Prompts for UI Designers & Figma/Flutter Devs](#9-copy-paste-ai-prompts-for-ui-designers--figmaflutter-devs)
10. [Codebase Gap Analysis & Migration Roadmap](#10-codebase-gap-analysis--migration-roadmap)

---

## 1. Executive Overview & Architectural Refinement

The AgriChain frontend architecture has been completely streamlined into a pure, high-efficiency agricultural commerce, AI quality assaying, multi-carrier freight logistics, and smart contract escrow protocol.

### 🚫 Complete Pruning of Legacy Modules
All loan, uncollateralized lending, credit scoring, and NBFC integration screens have been **100% removed**. 

The platform strictly focuses on:
1. **Direct Farmgate & FPO-to-Buyer Trading** (Elimination of middlemen and exploitative APMC commission agents).
2. **AI Quality Assaying via On-Device Computer Vision (MobileNetV3)**: Instant moisture, foreign matter, and broken grain percentage analysis.
3. **Grassroots Spatial Aggregation via 1,00,000+ Government PACS Godowns**: DBSCAN spatial clustering of smallholder lots.
4. **Multi-Carrier 7-Freight Aggregator Engine**: Parallel real-time quotation across BlackBuck, WheelsEye, Trukky, FR8, LoadShare, Delhivery B2B, Shiprocket Cargo.
5. **Non-Custodial Polygon PoS L2 Smart Contract Escrow (`AgriChainCompliance.sol`)**: Automated multi-split payouts on delivery confirmation.
6. **Automated 9-Act Legally Binding E-Contract PDF Generation**: Tripartite e-stamped legal agreements with SHA-256 integrity checks.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   THE 4 CLEAN USER PROFILES                                      │
├──────────────────────────────────────┬───────────────────────────────────────────────────────────┤
│ 🌾 SUPPLY SIDE (SELLERS)             │ 🏢 DEMAND SIDE (BUYERS)                                   │
├──────────────────────────────────────┼───────────────────────────────────────────────────────────┤
│ 1. 👨‍🌾 Individual Farmer (Kisaan)     │ 3. 🏭 Bulk Institutional Buyer (Mill / FMCG / Exporter)   │
│    (5 to 50 Quintals / 0.5 to 5 MT)  │    (10 to 500+ Metric Tonnes)                             │
│                                      │                                                           │
│ 2. 🏢 Bulk Seller (FPO / FPC)        │ 4. 🛒 Retail Consumer / Store (D2C / Group Buying)        │
│    (50 to 500+ Metric Tonnes)        │    (1 kg to 5 Quintals)                                   │
└──────────────────────────────────────┴───────────────────────────────────────────────────────────┘
```

---

## 2. Master Screen Inventory & Role-Based Access Control (RBAC)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                          COMPLETE 24-SCREEN PRODUCTION INVENTORY                                 │
├────┬───────────────────────────────────────┬────────────────────────────┬────────────────────────┤
│ #  │ Screen File Path                      │ Target User Profile        │ Primary Module         │
├────┼───────────────────────────────────────┼────────────────────────────┼────────────────────────┤
│ 01 │ 01_splash_screen.dart                 │ All Users (Universal)      │ System Initialization  │
│ 02 │ 02_language_selection_screen.dart     │ All Users (Universal)      │ Localization (HI / EN) │
│ 03 │ 03_phone_otp_screen.dart              │ All Users (Universal)      │ Firebase Auth          │
│ 04 │ 04_role_selection_screen.dart         │ All Users (Universal)      │ RBAC Routing           │
│ 05 │ 05_kyc_verification_screen.dart       │ All Users (Role-Specific)  │ DigiLocker / MCA / GST │
├────┼───────────────────────────────────────┼────────────────────────────┼────────────────────────┤
│ 06 │ 06_farmer_home_dashboard.dart         │ 👨‍🌾 Individual Farmer      │ Mandi Ticker & Sales   │
│ 07 │ 07_create_crop_listing_screen.dart    │ 👨‍🌾 Individual Farmer      │ MobileNetV3 AI Camera  │
│ 08 │ 08_my_crops_screen.dart               │ 👨‍🌾 Individual Farmer      │ Active / Pooled Orders │
│ 09 │ 09_crop_nft_card_screen.dart          │ 👨‍🌾 Individual Farmer      │ CropNFT Passport View  │
│ 10 │ 10_farmer_payout_history.dart         │ 👨‍🌾 Individual Farmer      │ Direct UPI Passbook    │
├────┼───────────────────────────────────────┼────────────────────────────┼────────────────────────┤
│ 11 │ 11_fpo_dashboard_screen.dart          │ 🏢 Bulk Seller (FPO)       │ Godown & PO Overview   │
│ 12 │ 12_fpo_batch_pooling_screen.dart      │ 🏢 Bulk Seller (FPO)       │ DBSCAN Multi-Farmer    │
│ 13 │ 13_fpo_bulk_listing_screen.dart       │ 🏢 Bulk Seller (FPO)       │ Multi-Tonne & Lab Cert │
│ 14 │ 14_fpo_rfq_board_screen.dart          │ 🏢 Bulk Seller (FPO)       │ Mill Purchase Orders   │
│ 15 │ 15_fpo_settlement_screen.dart         │ 🏢 Bulk Seller (FPO)       │ Pro-Rata Farmer DBT    │
├────┼───────────────────────────────────────┼────────────────────────────┼────────────────────────┤
│ 16 │ 16_buyer_marketplace_screen.dart      │ 🏭 Bulk B2B Buyer (Mill)   │ Grain Catalog & Filter │
│ 17 │ 17_buyer_lot_detail_screen.dart       │ 🏭 Bulk B2B Buyer (Mill)   │ Variable Qty Slider    │
│ 18 │ 18_post_rfq_screen.dart               │ 🏭 Bulk B2B Buyer (Mill)   │ B2B Procurement Tender │
│ 19 │ 19_escrow_checkout_screen.dart        │ 🏭 Bulk B2B Buyer (Mill)   │ 7-Carrier Comparator   │
│ 20 │ 20_factory_gate_qc_screen.dart        │ 🏭 Bulk B2B Buyer (Mill)   │ 24-hr QC Testing Gate  │
│ 21 │ 21_buyer_invoices_screen.dart         │ 🏭 Bulk B2B Buyer (Mill)   │ GST & Blockchain Audit │
├────┼───────────────────────────────────────┼────────────────────────────┼────────────────────────┤
│ 22 │ 22_retail_marketplace_screen.dart     │ 🛒 Retail Consumer (D2C)   │ Fresh Farm Shop        │
│ 23 │ 23_group_buying_screen.dart           │ 🛒 Retail Consumer (D2C)   │ Panchayat Basket Club  │
│ 24 │ 24_consumer_checkout_orders.dart      │ 🛒 Retail Consumer (D2C)   │ 1-Click UPI & Tracking │
├────┼───────────────────────────────────────┼────────────────────────────┼────────────────────────┤
│ S1 │ live_transit_tracking_screen.dart     │ Shared (Buyer/Seller/Trans)│ ULIP FASTag Live Map   │
│ S2 │ legal_contract_pdf_screen.dart        │ Shared (Buyer/Seller)      │ 9-Act E-Contract PDF   │
│ S3 │ dispute_resolution_screen.dart        │ Shared (DAO / FPO Board)   │ Ballot.sol Governance  │
└────┴───────────────────────────────────────┴────────────────────────────┴────────────────────────┘
```

---

## 3. Universal Auth & 1-Time KYC Module (5 Screens)

### Screen 01: Splash Screen (`01_splash_screen.dart`)
* **Duration & Transition**: 2.5 seconds auto-transition with smooth fade animation.
* **UI Components**:
  * Center: Animated AgriChain Gradient Logo (Lottie JSON, 200x200px).
  * App Version Badge: `AgriChain v2.0 • Smart India Hackathon Grand Finale`.
  * Bottom: Linear Progress Indicator checking offline SQLite cache status.
* **Backend Logic**:
  * Checks Firebase Auth token validity.
  * If valid session exists $\to$ Routes directly to the user's role-specific dashboard.
  * If new user $\to$ Routes to Language Selection.

### Screen 02: Language Selection (`02_language_selection_screen.dart`)
* **UI Components**:
  * Header: "अपनी भाषा चुनें / Choose Your Language".
  * Two High-Contrast Cards (180x120px, Rounded 16px):
    * 🇮🇳 **हिंदी (Hindi)**
    * 🇬🇧 **English (English)**
  * Audio Prompt: Automated Text-to-Speech (TTS) voice prompt in Hindi for accessibility.
* **Logic**: Selection is saved to `SharedPreferences` and dynamically reloads the Material localization context (`Locale('hi')` / `Locale('en')`).

### Screen 03: Phone OTP Login (`03_phone_otp_screen.dart`)
* **UI Components**:
  * Prefix Box: `+91` (Locked to India).
  * TextField: 10-digit mobile number input with auto-formatting (`XXXXX XXXXX`).
  * Button: `[ 🔐 OTP Bhejein / Send OTP ]` (Primary Green `#2E7D32`).
  * Verification Overlay: 6 individual OTP digit boxes with auto-focus advance + 30-second countdown resend timer.
* **Backend Logic**:
  * `FirebaseAuth.instance.verifyPhoneNumber()` with SMS auto-retrieval.
  * On success: Queries Firestore `users/{uid}`. If document exists $\to$ Home Dashboard; else $\to$ Role Selection.

### Screen 04: Role Selection (`04_role_selection_screen.dart`)
* **UI Components**:
  * Header: "Aap Kaun Hain? / Select Your Profile".
  * 4 Interactive Visual Cards (2x2 Grid, Elevation 4, Rounded 16px):
    1. 👨‍🌾 **Individual Farmer (Kisaan)**: *"Main apni fasal bechna chahta hoon (5–50 Quintals)"*
    2. 🏢 **Bulk Seller (FPO / Cooperative)**: *"Hum gaon ke kisaano ka bulk maal bechte hain (50–500 MT)"*
    3. 🏭 **Bulk B2B Buyer (Mill / FMCG / Exporter)**: *"Mujhe processing/export ke liye grain chahiye"*
    4. 🛒 **Retail Consumer (D2C / Store)**: *"Mujhe fresh farm produce ghar mangwana hai"*
* **Action**: On Selection, updates `userRole` field in user profile and routes to role-specific KYC.

### Screen 05: KYC Verification (`05_kyc_verification_screen.dart`)
* **Role-Specific KYC Forms**:
  * **Farmer KYC**: Full Name, Village/District dropdowns (Govt LGD API), Aadhaar/Kisan Card Photo OCR (extracts details in <2s), Bank Account + IFSC (verified via Razorpay ₹1.00 Penny-Drop API).
  * **FPO KYC**: Registered FPC Name, 21-Digit MCA Corporate Identity Number (CIN auto-verified via MCA V3 API), SFAC/NABARD Accreditation ID, Corporate Bank Account.
  * **Buyer KYC**: Company Name, 15-Digit GSTIN (auto-verified via GSTN API), Factory Address, Gate GPS Coordinates, Corporate PAN.
  * **Consumer KYC**: Minimal 1-step profile: Name, Mobile, Delivery Address.

---

## 4. Profile 1: Individual Farmer (Kisaan) Specification (5 Screens)
* **Theme**: High-Contrast Forest Green (`#1B5E20`), Large Action Targets, Voice Navigation Support.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             👨‍🌾 INDIVIDUAL FARMER (KISAAN) PAGE SPECIFICATION                    │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. FARMER HOME DASHBOARD (`06_farmer_home_dashboard.dart`) [Tab 1: Home]                         │
│ • Live Mandi Ticker: Top horizontal auto-scroller fetching Agmarknet live rates.                 │
│ • Primary CTA Button: Huge 64px button "🌾 Fasal Bechein / Sell Your Crop" (Tap to List).       │
│ • Active Orders Card: Shows in-flight shipments with real-time status chips.                     │
│ • Total Season Revenue: Total cash credited to bank via Smart Escrow.                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. AI CAMERA CROP LISTING (`07_create_crop_listing_screen.dart`) [Primary Action]                │
│ • Step 1: Crop Category (Cereals, Pulses, Oilseeds) & Variety (Basmati 1121, PB-1509).          │
│ • Step 2 (MobileNetV3 AI Assaying): Camera captures grain on white paper. In <1 sec, on-device │
│   model predicts Moisture % (e.g. 11.2%), Broken Grain % (2.8%), Foreign Matter % (0.4%).        │
│ • Step 3: Quantity in Quintals + Number of 50 kg Bags.                                           │
│ • Step 4 (AI Price Guide): Displays Live Mandi Modal Rate vs Hardcoded MSP Floor (₹2,275).      │
│   (Bids below MSP are blocked by smart contract).                                                │
│ • Step 5: Pickup Location Selector (Direct Farmgate vs Nearest PACS Godown Dock within 3 km).   │
│ • Submit Action: Mints `CropNFT` ERC-721 token on Polygon L2 with IPFS photo proof.             │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. MY CROPS & ACTIVE ORDERS (`08_my_crops_screen.dart`) [Tab 2: My Crops]                        │
│ • Tab 1 (Active Listings): Unsold listings with live buyer bids & counter-offer tools.           │
│ • Tab 2 (Pooled in PACS): Harvest lots pooled with neighboring farmers awaiting truck loading.   │
│ • Tab 3 (Completed): Delivered orders with instant payment receipts.                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. `CropNFT` DIGITAL PASSPORT (`09_crop_nft_card_screen.dart`) [Tab 3: CropNFT]                  │
│ • High-Tech Digital Card: AGMARK Grade A Seal, Token ID (#88019), IPFS Metadata Hash.            │
│ • Buttons: [ 🔗 View on PolygonScan ] [ 📤 Share Digital Passport via WhatsApp ].                 │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5. FARMER PASSBOOK & PAYOUTS (`10_farmer_payout_history.dart`) [Tab 4: Passbook]                 │
│ • Direct UPI Bank Ledger: Real-time logs of credits from Polygon Smart Escrow.                   │
│ • Downloadable 1-Page Official Tax-Free Agriculture Income Slip (PDF).                           │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Profile 2: Bulk Seller (FPO / Cooperative) Specification (5 Screens)
* **Theme**: Emerald Teal (`#00796B`), Multi-Farmer Batch Aggregation & Enterprise Admin Controls.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             🏢 BULK SELLER (FPO / FPC) PAGE SPECIFICATION                        │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. FPO EXECUTIVE DASHBOARD (`11_fpo_dashboard_screen.dart`) [Tab 1: Dashboard]                   │
│ • Warehouse Inventory Summary: Total tonnage stored in godown (e.g. 280 MT).                     │
│ • Member Farmers: Count of registered farmers in cooperative (e.g. 640 Farmers).                 │
│ • Open Purchase Orders: Active incoming purchase orders from corporate mills.                    │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. MULTI-FARMER BATCH POOLING (`12_fpo_batch_pooling_screen.dart`) [Tab 2: Batch Pool]           │
│ • Interactive Map: Visualizes member farm locations + Nearest PACS Godown Hubs.                  │
│ • DBSCAN Spatial Clustering: Groups 20–50 small farmer lots (10–20 Qtl each) into a single       │
│   unified **10-Tonne / 25-Tonne FTL Container Lot**.                                             │
│ • Schedule Generator: Generates automated SMS/WhatsApp dispatch alerts to all pooled farmers.    │
│ • Output: Generates Master Batch ID + QR Code.                                                   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. BULK LOT LISTING & LAB UPLOAD (`13_fpo_bulk_listing_screen.dart`) [Tab 3: Listings]           │
│ • Multi-Tonne Listing Form: 50 to 500+ Metric Tonnes.                                            │
│ • Mandatory Digital Uploads: Certified Weighbridge Slip + NABL/AGMARK Lab Certificate PDF.       │
│ • Sets Minimum Order Quantity (MOQ: e.g. 10 MT).                                                 │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. FPO DEMAND & RFQ BROADCAST BOARD (`14_fpo_rfq_board_screen.dart`) [Tab 4: RFQ Board]          │
│ • Live Purchase Feed: Large orders from mills (e.g. "Adani Wilmar needs 500 MT Soybean").        │
│ • Action Buttons: [ ✅ Accept Full Order ] [ ⚠ Accept Partial (100 MT) ] [ 💬 Counter-Bid ].     │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5. MULTI-SPLIT SETTLEMENT LEDGER (`15_fpo_settlement_screen.dart`) [Tab 5: Accounts]             │
│ • Pro-Rata Farmer Disbursement: Shows automatic split payouts to all member farmers.             │
│ • FPO Facilitation Commission: Tracks 0.5%–1% operational revenue earned by the FPO.             │
│ • Export: [ 📥 Download Complete Audit Ledger (Excel/PDF) ].                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Profile 3: Bulk Institutional Buyer (Mill / FMCG) Specification (6 Screens)
* **Theme**: Corporate Navy Blue (`#0D47A1`), Enterprise Procurement Tools & 7-Carrier Freight Engine.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             🏭 BULK B2B BUYER (MILL / FMCG) PAGE SPECIFICATION                   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. B2B COMMODITY MARKETPLACE (`16_buyer_marketplace_screen.dart`) [Tab 1: Marketplace]           │
│ • Multi-State Catalog: Basmati Paddy (Haryana), Soybean (MP), Mustard (Rajasthan).               │
│ • Dynamic Filter Panel: Moisture % slider, AGMARK Grade A/B, Origin State, MOQ Range.           │
│ • Listing Badges: [ Verified FPO Hub ] [ Single-Origin Farmgate ] [ CropNFT Certified ].         │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. LOT DETAIL & VARIABLE ORDER SLIDER (`17_buyer_lot_detail_screen.dart`)                        │
│ • Microscopy Gallery: High-resolution grain photos + Lab test parameter tables.                  │
│ • **Interactive Quantity Slider:** Select exact required volume (e.g., 75 MT out of 200 MT Lot).│
│ • Origin Map: Displays pickup dock location (FPO Godown / PACS Hub) and route to factory.        │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. POST REQUIREMENT / B2B RFQ (`18_post_rfq_screen.dart`) [Tab 2: Post RFQ]                      │
│ • Enterprise Procurement Form: Target Commodity, Required Tonnage, Max Moisture %, Target Date.  │
│ • Broadcast Action: Instantly pushes purchase tender to 500+ verified regional FPOs.             │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. SMART ESCROW & FREIGHT CHECKOUT (`19_escrow_checkout_screen.dart`)                            │
│ • **Itemized Bill:** Crop Cost + Freight Fee + 0.2% Transit Insurance + 1.5% AgriChain Fee.      │
│ • **7-Carrier Freight Comparison Engine:** Parallel API query (<400ms) fetches live quotes:      │
│   BlackBuck (FTL), WheelsEye, Trukky, FR8, LoadShare, Delhivery B2B, Shiprocket Cargo.           │
│ • Payment Method: Corporate NetBanking / Virtual Account / RTGS.                                 │
│ • Action: Locks 100% funds into Polygon Smart Contract Escrow (`AgriChainCompliance.sol`).       │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5. FACTORY GATE 24-HR QC INSPECTION (`20_factory_gate_qc_screen.dart`) [Tab 3: My Orders]        │
│ • 24-Hour Statutory Inspection Countdown Timer (Under Sale of Goods Act, 1930).                  │
│ • Physical Testing Entry: Enter Actual Lab Moisture % and Grade vs Claimed CropNFT Metadata.     │
│ • Three Action Buttons:                                                                          │
│   ├── [ ✅ APPROVE 100% ] ➔ Triggers instant multi-split UPI payouts to Farmer & Transporter.    │
│   ├── [ ⚠ PARTIAL ACCEPT ] ➔ Specify accepted MT; releases pro-rata funds to farmer.            │
│   └── [ ❌ FULL DISPUTE ] ➔ Freezes escrow & triggers 0.2% Single-Trip Insurance Claim.          │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 6. B2B GST INVOICES & AUDIT VAULT (`21_buyer_invoices_screen.dart`) [Tab 4: Invoices]            │
│ • Downloadable GSTN-Compliant Tax Invoices with HSN Codes.                                       │
│ • Embedded SHA-256 On-Chain Cryptographic Proof for internal corporate financial audits.         │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Profile 4: Retail Consumer / D2C Buyer Specification (4 Screens)
* **Theme**: Fresh Mint Green (`#2E7D32`), Direct Farm-to-Fork Shopping, Instant 1-Click UPI.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             🛒 RETAIL CONSUMER (D2C) PAGE SPECIFICATION                          │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. RETAIL FRESH MARKETPLACE (`22_retail_marketplace_screen.dart`) [Tab 1: Shop]                  │
│ • Fresh Farm Catalog: Fruits, Vegetables, Atta, Cold-Pressed Mustard Oil, Organic Spices.        │
│ • Farm-to-Fork Badge: Farmer photo, harvest date ("Harvested Today 🟢 "), and origin village.     │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. GROUP BUYING / PANCHAYAT BASKET (`23_group_buying_screen.dart`) [Tab 2: Group Buy]            │
│ • Neighborhood Buying Club: 10 families in an apartment combine orders to get wholesale rates    │
│   (e.g., 1 Quintal Onion sack at ₹25/kg vs ₹40/kg retail).                                       │
│ • Progress Bar: Shows active slots filled (e.g. 7/10 joined).                                    │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. CONSUMER CHECKOUT & UPI PAYMENT (`24_consumer_checkout_orders.dart`)                          │
│ • Delivery Address Picker + Express Time Slot Selection.                                         │
│ • 1-Click UPI Payment via GPay, PhonePe, Paytm into Smart Escrow.                                │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. LIVE DELIVERY TRACKING & FARMER RATING (`24_consumer_checkout_orders.dart`)                   │
│ • Live Rider Tracking Map + Direct 5-Star Rating & Optional ₹20 Digital Tip to the Farmer.       │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Shared Telematics, Legal & Governance Modules (3 Screens)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             SHARED SYSTEM & TELEMATICS SCREENS                                   │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ S1. LIVE TRANSIT & TELEMATICS TRACKING (`live_transit_tracking_screen.dart`)                     │
│ • Full-Screen Map (flutter_map): Real-time highway tracking via Government ULIP FASTag API.      │
│ • Checkpoint Toll Markers: Live logs of toll plaza crossings without requiring driver app.       │
│ • Reefer Telematics: Live temperature sensor graph (+4.2°C normal range) for cold chain.         │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ S2. 9-ACT LEGAL CONTRACT PDF VIEWER (`legal_contract_pdf_screen.dart`)                           │
│ • In-App Document Viewer: Displays auto-generated 60 KB legal tripartite agreement.              │
│ • Enforces 9 Indian Statutory Acts (Sale of Goods Act 1930, IT Act 2000, Contract Act 1872).    │
│ • Embedded with SHA-256 cryptographic hash and digital signatures.                               │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ S3. DISPUTE RESOLUTION & DAO VOTING (`dispute_resolution_screen.dart`)                           │
│ • FPO Governance Interface: 3-member elected committee evaluates inspection disputes.           │
│ • Blockchain Voting: `Ballot.sol` smart contract records immutable resolution decisions.        │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Copy-Paste AI Prompts for UI Designers & Figma/Flutter Devs

### Master Design System Prompt
```
Design a complete mobile UI design system in Flutter for an Agricultural B2B E-Commerce & Freight Platform named "AgriChain". The app strictly has ZERO loan features and is built around 4 role-based user profiles:

1. Farmer Profile (Forest Green #1B5E20):
   - Home Dashboard with Live Mandi Ticker and big "Fasal Bechein" button.
   - AI Camera Assaying Screen with on-device quality detection overlay.
   - My Crops screen with tabs: Active, Pooled in PACS, and Sold.
   - CropNFT Digital Passport view with AGMARK grade stamp and IPFS hash.
   - Direct UPI Passbook with transaction history.

2. FPO Bulk Seller Profile (Emerald #00796B):
   - Executive Godown Dashboard showing total stored tonnage and active POs.
   - DBSCAN Batch Pooling screen to group 50 small farmer lots into 10-Tonne FTL container orders.
   - Bulk Listing screen with Digital Weighbridge & Lab PDF upload.
   - Demand/RFQ Board to accept incoming purchase orders from corporate mills.
   - Multi-split DBT settlement ledger.

3. Bulk B2B Buyer Profile (Navy Blue #0D47A1):
   - Commodity Marketplace with interactive Quantity Sliders (e.g. 50 MT).
   - Post RFQ Requirement screen for large procurement tenders.
   - Smart Escrow Checkout featuring an integrated 7-Carrier Freight Comparison card (BlackBuck, WheelsEye, Trukky, Delhivery).
   - 24-Hour Factory Gate Quality Inspection screen with Accept, Partial-Accept, and Dispute actions.
   - GST Tax Invoice & Blockchain Audit Vault.

4. Retail Consumer Profile (Fresh Mint #2E7D32):
   - Farm-to-Fork grocery shop, Group-Buying Basket, UPI checkout, and live order tracking.

Shared Components:
   - Live Highway Transit Map with FASTag checkpoints.
   - 9-Act Signed Legal PDF Contract Viewer.

Visual Aesthetic: Modern Material 3 UI with dark mode support, crisp typography, clean cards, clear status chips, and zero clutter.
```

---

## 10. Codebase Gap Analysis & Migration Roadmap

### A. Deprecated Modules To Remove:
- `lib/screens/loan_screen.dart` (Legacy loan application)
- `lib/screens/loans_screen.dart` (Legacy loan listing)
- Uncollateralized credit rating widgets and references in `main.dart`, `profile_screen.dart`, and `app_state.dart`.

### B. Core Screen Mapping Matrix:
| Spec # | Feature / Screen | Target Dart File | Status in Codebase |
|---|---|---|---|
| **01** | Splash Screen | `lib/screens/01_splash_screen.dart` | Embedded in `main.dart` loading |
| **02** | Language Selection | `lib/screens/02_language_selection_screen.dart` | In `onboarding_screen.dart` |
| **03** | Phone OTP Login | `lib/screens/03_phone_otp_screen.dart` | In `login_screen.dart` |
| **04** | Role Selection | `lib/screens/04_role_selection_screen.dart` | In `signup_screen.dart` |
| **05** | KYC Verification | `lib/screens/05_kyc_verification_screen.dart` | In `profile_setup_screen.dart` |
| **06** | Farmer Home Dashboard | `lib/screens/farmer/06_farmer_home_dashboard.dart` | Refactored `home_screen.dart` |
| **07** | AI Camera Crop Listing | `lib/screens/farmer/07_create_crop_listing_screen.dart` | Refactored `add_crop_screen.dart` + MobileNetV3 |
| **08** | My Crops & Active Orders | `lib/screens/farmer/08_my_crops_screen.dart` | `my_crops_screen.dart` |
| **09** | CropNFT Digital Passport | `lib/screens/farmer/09_crop_nft_card_screen.dart` | Refactored `mint_crop_nft_screen.dart` |
| **10** | Farmer Passbook & Payouts | `lib/screens/farmer/10_farmer_payout_history.dart` | `transaction_history_screen.dart` |
| **11** | FPO Executive Dashboard | `lib/screens/fpo/11_fpo_dashboard_screen.dart` | `fpo_home_screen.dart` |
| **12** | Multi-Farmer Batch Pooling | `lib/screens/fpo/12_fpo_batch_pooling_screen.dart` | DBSCAN Clustering Screen |
| **13** | Bulk Lot Listing & Lab Upload | `lib/screens/fpo/13_fpo_bulk_listing_screen.dart` | `fpo_add_crop_screen.dart` |
| **14** | FPO Demand & RFQ Board | `lib/screens/fpo/14_fpo_rfq_board_screen.dart` | `fpo_procure_screen.dart` |
| **15** | Multi-Split Settlement Ledger | `lib/screens/fpo/15_fpo_settlement_screen.dart` | FPO Accounts & Payouts |
| **16** | B2B Commodity Marketplace | `lib/screens/bulk_buyer/16_buyer_marketplace_screen.dart` | `bulk_buyer_home_screen.dart` |
| **17** | Lot Detail & Variable Qty Slider | `lib/screens/bulk_buyer/17_buyer_lot_detail_screen.dart` | Lot Detail with dynamic slider |
| **18** | Post Requirement / B2B RFQ | `lib/screens/bulk_buyer/18_post_rfq_screen.dart` | `bulk_buyer_rfqs_screen.dart` |
| **19** | Smart Escrow & 7-Carrier Freight | `lib/screens/bulk_buyer/19_escrow_checkout_screen.dart` | Multi-Carrier Rate Comparator |
| **20** | Factory Gate 24-Hr QC Gate | `lib/screens/bulk_buyer/20_factory_gate_qc_screen.dart` | 24-Hr QC Testing Gate |
| **21** | B2B GST Invoices & Audit Vault | `lib/screens/bulk_buyer/21_buyer_invoices_screen.dart` | GST Invoices Vault |
| **22** | Retail Fresh Marketplace | `lib/screens/retail_buyer/22_retail_marketplace_screen.dart` | `retail_buyer_home_screen.dart` |
| **23** | Group Buying / Panchayat Basket | `lib/screens/retail_buyer/23_group_buying_screen.dart` | Group Buying Screen |
| **24** | Consumer Checkout & Tracking | `lib/screens/retail_buyer/24_consumer_checkout_orders.dart` | `retail_buyer_orders_screen.dart` |
| **S1** | Live FASTag Transit Tracking | `lib/screens/shared/live_transit_tracking_screen.dart` | ULIP FASTag Tracking Map |
| **S2** | 9-Act Legal Contract PDF Viewer | `lib/screens/shared/legal_contract_pdf_screen.dart` | In-App PDF Document Viewer |
| **S3** | Dispute Resolution & DAO Ballot | `lib/screens/shared/dispute_resolution_screen.dart` | Ballot.sol Governance UI |
