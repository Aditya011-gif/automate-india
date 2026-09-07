# AI Agricultural Demand & Price Forecasting Engine: Technical & Process Specification

**Version:** 1.0 (Production-Grade)  
**Target:** Hackathon & Production Deployment  
**Author:** AI Engineering & Agricultural Data Science Team  

---

## 1. Executive Summary & Purpose

Agricultural supply chains across India suffer from severe information asymmetry, volatile price swings, and perishable post-harvest losses (up to 25–30% in perishables like Tomato and Onion).

The **AI Agricultural Demand & Price Forecasting Engine** is an end-to-end, probabilistic machine learning system designed to provide **7 to 14-day forward-looking visibility** into:
1. **Demand Quantity in KG** with probabilistic risk bands:
   - **P10 (Pessimistic Demand):** Downside volume risk.
   - **P50 (Median Expected Demand):** Base forecasting target.
   - **P90 (Optimistic Surge Demand):** Upside spike threshold (festival/institutional demand).
2. **Modal, Minimum, and Maximum Price per KG** in INR for key agricultural corridors.
3. **Actionable Natural Language Advisories** for farmers, Farmer Producer Organizations (FPOs), and aggregators (harvest schedules, dispatch timing, and storage decisions).

---

## 2. System Architecture & High-Level Workflow

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             1. DATA INGESTION LAYER                              │
│                                                                                  │
│  [data.gov.in / Agmarknet API]   [Open-Meteo REST Weather]   [holidays.India]    │
│  • Daily arrivals (tonnes)       • Daily Rain Sum (mm)       • Festival flags    │
│  • Min, Max, Modal Prices        • Temp Max, Temp Min, Range • Proximity metrics │
└─────────────────────────┬────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   2. HIGH-RESILIENCE CACHE & DATA NORMALIZER                     │
│  • Parquet/CSV Local Snapshot (`data/raw/` & `data/processed/`)                   │
│  • Zero-Downtime offline fallback mechanism (hackathon demo protection)          │
└─────────────────────────┬────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                     3. ADVANCED FEATURE ENGINEERING PIPELINE                     │
│  • Temporal & Cyclical (sin/cos of Day/Month/Quarter)                            │
│  • Festival Surges (days_to_holiday, days_since_holiday, is_weekend)             │
│  • Multi-Horizon Lags (t-1, t-2, t-3, t-7, t-14, t-30)                           │
│  • Rolling Window Aggregations (7d & 14d Mean, Std, Min, Max)                    │
│  • Exponential Moving Averages (EMA-7, EMA-14)                                   │
│  • Agrometeorological Interaction (rain shocks, heatwaves, disruption index)     │
│  • Target & Categorical Encoding (Commodity, State, District)                    │
└─────────────────────────┬────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   4. MACHINE LEARNING & QUANTILE MODEL LAYER                     │
│                                                                                  │
│   ┌───────────────────────────────────┐   ┌──────────────────────────────────┐   │
│   │   LightGBM Quantile Regressors    │   │     LightGBM Price Forecaster    │   │
│   │   • Alpha 0.10 -> P10 Demand      │   │   • Objective: L2 Regression     │   │
│   │   • Alpha 0.50 -> P50 Demand      │   │   • Predicts Expected Modal Price│   │
│   │   • Alpha 0.90 -> P90 Demand      │   │   • Spread Regression (Min/Max)  │   │
│   └───────────────────────────────────┘   └──────────────────────────────────┘   │
│                                                                                  │
│   • Time-Series Walk-Forward Cross Validation (Strict Temporal Split)            │
│   • Benchmark Metrics: WAPE < 20%, RMSE, MAE, R² > 0.85                          │
└─────────────────────────┬────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                     5. NLP INSIGHT & ADVISORY GENERATOR                          │
│  • Synthesizes price trends, supply shocks, and festival surges into plain text  │
│  • Actionable farm-gate advisories (e.g. "Harvest on Aug 29 for morning mandi")  │
└─────────────────────────┬────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                      6. PRODUCTION SERVING & API CONTRACT                        │
│  • Standalone Python Module: `predict_demand_and_price(commodity, district, date)`│
│  • FastAPI REST Server (`/forecast`, `/health`, `/supported-corridors`)          │
│  • Serialized Artifact: `models/agritech_forecast_pipeline.joblib`               │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Data Ingestion & Fallback Strategy

### 3.1 Data Sources & Keys
1. **Mandi Prices & Arrivals (`data.gov.in`)**:
   - Resource Endpoint: `/resource/35985678-0d79-46b4-9ed6-6f13308a1d24`
   - Key: Configured in environment variables (`DATA_GOV_API_KEY`).
   - Fields: `State`, `District`, `Market`, `Commodity`, `Variety`, `Arrival_Date`, `Min_Price`, `Max_Price`, `Modal_Price`, `Arrival_Quantity_Tonnes`.
2. **Weather Intelligence (`Open-Meteo`)**:
   - Endpoints: `https://archive-api.open-meteo.com/v1/archive` and `https://api.open-meteo.com/v1/forecast`.
   - Free, zero-auth, high-availability API.
   - Coordinates:
     - Karnal (Haryana): $29.6857^\circ\text{ N}, 76.9905^\circ\text{ E}$
     - Nashik (Maharashtra): $19.9975^\circ\text{ N}, 73.7898^\circ\text{ E}$
     - Azadpur (Delhi): $28.7164^\circ\text{ N}, 77.1772^\circ\text{ E}$
     - Kolar (Karnataka): $13.1367^\circ\text{ N}, 78.1291^\circ\text{ E}$
     - Pune (Maharashtra): $18.5204^\circ\text{ N}, 73.8567^\circ\text{ E}$
3. **Indian Calendar & Holidays (`holidays.India`)**:
   - Covers 2021 to 2026 for national holidays and major festivals (Diwali, Holi, Dussehra, Makar Sankranti, Eid, Independence Day, etc.).

### 3.2 Hackathon Zero-Downtime Guarantee (Caching Layer)
To ensure the demo runs without risk of API rate-limiting or network latency during the hackathon:
- The data loader saves all retrieved and processed datasets locally in `data/processed/`.
- If an API request encounters a timeout or limit, it **gracefully falls back to the high-fidelity local snapshot** without failing the prediction request.

---

## 4. Mathematical Feature Engineering

The feature vector $X_t$ for date $t$ is constructed from 5 feature sub-spaces:

### 4.1 Temporal & Cyclical Features
To preserve continuity across week and annual cycles:
$$\text{sin\_dow} = \sin\left(\frac{2\pi \cdot \text{day\_of\_week}}{7}\right), \quad \text{cos\_dow} = \cos\left(\frac{2\pi \cdot \text{day\_of\_week}}{7}\right)$$
$$\text{sin\_month} = \sin\left(\frac{2\pi \cdot \text{month}}{12}\right), \quad \text{cos\_month} = \cos\left(\frac{2\pi \cdot \text{month}}{12}\right)$$
- `is_weekend` $\in \{0, 1\}$
- `is_holiday` $\in \{0, 1\}$
- `days_to_next_holiday` and `days_since_last_holiday`

### 4.2 Multi-Horizon Lagged Features
Captures autoregressive patterns and weekly institutional cycles:
$$L_k(y_t) = y_{t-k}, \quad k \in \{1, 2, 3, 7, 14, 30\}$$
- Computed for both **Arrival Demand** and **Modal Price**.

### 4.3 Rolling Window & Momentum Indicators
$$EMA_\alpha(y_t) = \alpha y_t + (1 - \alpha) EMA_\alpha(y_{t-1}), \quad \alpha \in \left\{\frac{2}{7+1}, \frac{2}{14+1}\right\}$$
$$\mu_{7}(y_t) = \frac{1}{7}\sum_{i=0}^6 y_{t-i}, \quad \sigma_{7}(y_t) = \sqrt{\frac{1}{7}\sum_{i=0}^6 (y_{t-i} - \mu_{7})^2}$$
- `rolling_min_7d`, `rolling_max_7d`, `rolling_min_14d`, `rolling_max_14d`.
- **Price Momentum:** $\frac{\text{Price}_{t-1} - \text{Price}_{t-7}}{\text{Price}_{t-7}}$.

### 4.4 Agrometeorological Interaction & Disruption Indices
- `temp_range` = $\text{temp\_max} - \text{temp\_min}$
- `rain_sum` (daily precipitation in mm)
- `consecutive_rainy_days`: Cumulative days where $\text{rain\_sum} > 5.0\text{ mm}$
- `supply_disruption_flag`: True if $\text{rain\_sum} > 25\text{ mm}$ (causes mandi arrival drops and price spikes).

---

## 5. Machine Learning Models & Optimization

### 5.1 Probabilistic Demand Forecasting (Quantile Regression)
Traditional regression predicts only the mean, ignoring risk. We train 3 separate LightGBM Quantile Regressors optimizing the **Pinball Loss**:

$$\mathcal{L}_\alpha(y, \hat{y}) = \max(\alpha(y - \hat{y}), (1 - \alpha)(\hat{y} - y))$$

1. **$\alpha = 0.10$ (P10 - Pessimistic):** 90% probability actual demand exceeds this level.
2. **$\alpha = 0.50$ (P50 - Expected Median):** Central demand estimate.
3. **$\alpha = 0.90$ (P90 - Optimistic Surge):** Peak surge capacity requirement.

### 5.2 Modal Price & Spread Regressor
- **Target:** `Modal_Price` (INR/kg).
- **Objective:** LightGBM Gradient Boosting with L2 Loss (RMSE).
- **Spread Estimators:** Predicts expected price variance $\Delta_{\text{min}}$ and $\Delta_{\text{max}}$ based on recent volatility.

### 5.3 Walk-Forward Time-Series Validation
To ensure realistic backtesting without data leakage:
- Split dataset temporally (Train on Day $1 \dots T$, Validate on Day $T+1 \dots T+14$).
- Step window forward across entire historical horizon.

### 5.4 Benchmark Evaluation Metrics
- **Weighted Absolute Percentage Error (WAPE):**
  $$\text{WAPE} = \frac{\sum_{i=1}^N |y_i - \hat{y}_i|}{\sum_{i=1}^N y_i} < 20\%$$
- **Mean Absolute Error (MAE)** & **Root Mean Squared Error (RMSE)**
- **Coefficient of Determination ($R^2$):** Target $> 0.85$.

---

## 6. Actionable Natural Language Insights Engine

The engine converts numerical forecasts into plain-language advisories by analyzing:
1. **Demand Surge Factor:** $S = \frac{\text{P90} - \text{P50}}{\text{P50}}$
2. **Price Trend Direction:** $T = \frac{\hat{P}_{\text{target}} - P_{\text{current}}}{P_{\text{current}}}$
3. **Weather Disruption Risk:** Consecutive rain days or extreme heat.

### Example Insight Generated:
> **Insight:** *"Projected tomato demand in Karnal cluster for 30 August is 2,750–3,200 kg. High demand expected due to weekend institutional orders."*  
> **Recommendation:** *"Harvest 2,800 kg on Aug 29 evening for early morning delivery to maximize price realization."*

---

## 7. Output API Contract (JSON)

```json
{
  "status": "SUCCESS",
  "meta": {
    "commodity": "Tomato",
    "district": "Karnal",
    "state": "Haryana",
    "target_date": "2026-08-30"
  },
  "demand_forecast_kg": {
    "p10_pessimistic": 2750,
    "p50_expected": 2980,
    "p90_optimistic": 3200,
    "confidence_interval": "80%"
  },
  "price_forecast_inr_per_kg": {
    "min_price": 20.00,
    "expected_modal_price": 22.50,
    "max_price": 25.00
  },
  "actionable_insight": "Projected tomato demand in Karnal cluster for 30 August is 2,750–3,200 kg. High demand expected due to weekend institutional orders.",
  "recommendation": "Harvest 2,800 kg on Aug 29 evening for early morning delivery to maximize price realization."
}
```

---

## 8. Hackathon Presentation & Defense Checklist

- [x] Multi-source ingestion (Agmarknet, Open-Meteo, Holidays).
- [x] Multi-quantile LightGBM (P10, P50, P90) + Price Regressor.
- [x] Time-series walk-forward validation (WAPE < 20%, $R^2 > 0.85$).
- [x] Instant offline fallback caching (0% risk of rate-limiting during demo).
- [x] Natural language advice engine for farmers & FPOs.
- [x] FastAPI REST endpoints + Interactive Swagger documentation.
