# Integration Plan: AgriChain & KRMU Agri-Score

This document serves as a persistent context and implementation plan for integrating the KRMU-main (Agri-Score) logic into the existing AgriChain marketplace application.

## 1. Project Summaries

### AgriChain (Marketplace & DeFi Loans)
AgriChain is a decentralized agricultural marketplace allowing farmers to list crops and buyers to purchase them securely with PDF contract generation. It also features a DeFi loan system where farmers can request micro-loans against their listed crops.
*   **Tech Stack:** Flutter (Dart), Firebase (Auth, Firestore), Provider (State Management), `pdf` / `printing` (Contract Generation).
*   **Key State:** Firebase Storage is currently bypassed due to billing limits. Images and signatures are encoded as Base64 strings directly in Firestore. Wallet section has been fully removed from the buyer view.
*   **Core Flow:** Farmer Adds Crop -> Buyer purchases from Marketplace -> Contract Generated -> Farmer can request Loan.

### KRMU-main (Agri-Score & ML Prediction)
KRMU-main is an AI-powered rural agricultural land intelligence and credit risk assessment platform. It calculates an "Agri-Trust Score" based on satellite and environmental data.
*   **Tech Stack (Frontend):** Flutter Web, Riverpod, Supabase.
*   **Tech Stack (Backend):** Python FastAPI, scikit-learn (ML), Pandas.
*   **Core Logic:**
    *   **Score Engine:** Client-side Dart engine weighting NDVI (35%), Soil Quality (25%), Land Class (15%), Weather (15%), Market Risk (10%) to output a 0-1000 score.
    *   **External APIs:** AgroMonitoring API (NDVI), OpenWeatherMap (Weather).
    *   **ML Pipeline:** Python backend serving pre-trained models (`.joblib`) predicting Crop Quality, Health Score, Risk Level, and NDVI Trends.

---

## 2. Integration Objectives

The goal is to merge the intelligent risk assessment of KRMU-main into the marketplace ecosystem of AgriChain to build trust between farmers and buyers.

1.  **Farmer Land Analysis:** Allow farmers to run a land analysis on their listed crops to generate an Agri-Score.
2.  **Buyer Transparency:** Display the Agri-Score as a trust badge on marketplace crop cards.
3.  **Detailed Profiles:** Show comprehensive land analysis and ML predictions on the farmer's profile for buyers and loan providers to review.

---

## 3. Step-by-Step Implementation Flow

### Phase 1: Core Logic Porting (Client-Side)
*   [x] Copy `score_engine.dart` from KRMU to AgriChain's `services/` directory.
*   [x] Create an `agri_score_service.dart` in AgriChain to handle external API fetching (AgroMonitoring NDVI, Weather fallbacks) using `dio` or `http`.
*   [x] Define the `AnalysisModel` in AgriChain's `firestore_models.dart` to match the KRMU structure but tailored for Firestore.

### Phase 2: UI Implementation (Farmer Side)
*   [x] Build a `LandAnalysisScreen` where a farmer can initiate a scan for a specific crop/land.
*   [x] Integrate the scanning process to save the resulting Agri-Score, NDVI value, Risk Tier, and Weather data into the farmer's `Crop` document in Firestore.

### Phase 3: Marketplace Visibility (Buyer Side)
*   [x] Update `CropCard` in the Marketplace to display a visual badge indicating the crop's Agri-Score (e.g., Platinum, Gold, Silver, Bronze) and raw score.
*   [x] Update the `FarmerProfileScreen` to display the full Land Analysis dashboard, including gauges, soil data, and NDVI trends.

### Phase 4: ML Backend Connectivity (Optional but Recommended)
*   [ ] Run the KRMU Python FastAPI backend locally (`uvicorn main:app --reload` on port 8000).
*   [x] Add an HTTP call in `agri_score_service.dart` to hit `http://localhost:8000/api/predict` with the crop features.
*   [x] Display ML predictions (Crop Quality, Crop Health, Risk Level) in the AgriChain UI alongside the base Agri-Score.

---

## 4. Modified Data Structures (Firestore)

The existing `Crop` model in AgriChain needs to be expanded to hold analysis data:

```dart
// Proposed Additions to FirestoreCrop
double? agriScore;           // 0-1000
String? riskTier;            // Platinum, Gold, Silver, Bronze
double? ndviValue;           // Satellite vegetation index
String? soilType;
Map<String, dynamic>? mlPredictions; // Crop Quality, NDVI Trend, etc.
```

## 5. Next Actions for AI
All core integration tasks are complete! The KRMU Python backend can be run locally using `uvicorn main:app --reload` inside the `KRMU-main` backend directory.
