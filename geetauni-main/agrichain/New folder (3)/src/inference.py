"""
Inference Module for AI Agricultural Demand & Price Forecasting Engine.
Provides standalone Python function and endpoint handler returning the required JSON schema.
"""

import json
import logging
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Optional

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

import joblib
import numpy as np
import pandas as pd

from src.config import COMMODITIES, CORRIDOR_COORDINATES, MODEL_PATH
from src.data_loader import MandiDataLoader
from src.insights_engine import AgriInsightsEngine
from src.train import ModelTrainer

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# Global cached pipeline
_CACHED_PIPELINE = None


def load_pipeline():
    """Loads trained pipeline artifact, automatically training if not yet built."""
    global _CACHED_PIPELINE
    if _CACHED_PIPELINE is not None:
        return _CACHED_PIPELINE

    if not MODEL_PATH.exists():
        logger.info(f"Model artifact not found at {MODEL_PATH}. Training pipeline now...")
        loader = MandiDataLoader()
        df = loader.get_or_load_dataset()
        trainer = ModelTrainer()
        trainer.train_pipeline(df)

    _CACHED_PIPELINE = joblib.load(MODEL_PATH)
    logger.info(f"Loaded ML forecasting pipeline successfully from {MODEL_PATH}")
    return _CACHED_PIPELINE


def predict_demand_and_price(
    commodity: str,
    district: str,
    target_date: str,
    state: Optional[str] = None
) -> Dict[str, Any]:
    """
    Main Production Inference Function.
    
    Parameters:
    - commodity: 'Tomato', 'Onion', or 'Wheat'
    - district: Target district name (e.g. 'Karnal', 'Nashik', 'Azadpur', 'Pune', 'Kolar')
    - target_date: Date string in 'YYYY-MM-DD' format (e.g. '2026-08-30')
    - state: Optional state name (auto-resolved from corridor coordinates if None)
    
    Returns:
    - JSON dictionary matching the specification schema.
    """
    # 1. Resolve State & Corridor Coordinates
    resolved_state = state
    matched_key = None
    for (comm, dist, st), coords in CORRIDOR_COORDINATES.items():
        if comm.lower() == commodity.lower() and dist.lower() == district.lower():
            resolved_state = st
            matched_key = (comm, dist, st)
            break

    if not resolved_state:
        # Default state mappings if district is recognized
        district_state_map = {
            "karnal": "Haryana",
            "nashik": "Maharashtra",
            "azadpur": "Delhi",
            "kolar": "Karnataka",
            "pune": "Maharashtra"
        }
        resolved_state = district_state_map.get(district.lower(), "Maharashtra")
        matched_key = (commodity.capitalize(), district.capitalize(), resolved_state)

    pipeline = load_pipeline()
    feature_engineer = pipeline["feature_engineer"]
    feature_cols = pipeline["feature_cols"]

    # 2. Retrieve Historical Snapshot for Lag/Rolling Construction
    loader = MandiDataLoader()
    df_raw = loader.get_or_load_dataset()

    target_dt = pd.to_datetime(target_date)
    
    # Filter recent history for this corridor
    corridor_hist = df_raw[
        (df_raw["Commodity"].str.lower() == commodity.lower()) &
        (df_raw["District"].str.lower() == district.lower())
    ].sort_values("date").copy()

    if len(corridor_hist) == 0:
        # Fallback to general commodity history
        corridor_hist = df_raw[df_raw["Commodity"].str.lower() == commodity.lower()].sort_values("date").copy()

    # 3. Weather Forecast for Target Date
    coords = CORRIDOR_COORDINATES.get(matched_key, {"lat": 28.6139, "lon": 77.2090, "market": district})
    weather_df = loader.fetch_weather_open_meteo(
        coords["lat"], coords["lon"],
        start_date=target_date,
        end_date=target_date,
        is_forecast=True
    )
    if len(weather_df) > 0:
        temp_max = float(weather_df["temp_max"].iloc[0])
        temp_min = float(weather_df["temp_min"].iloc[0])
        rain_sum = float(weather_df["rain_sum"].iloc[0])
    else:
        temp_max, temp_min, rain_sum = 32.0, 22.0, 0.0

    # 4. Construct Future Row Vector
    last_row = corridor_hist.iloc[-1]
    new_row = {
        "date": target_dt,
        "Arrival_Date": target_dt.strftime("%d/%m/%Y"),
        "Commodity": commodity.capitalize(),
        "State": resolved_state,
        "District": district.capitalize(),
        "Market": coords.get("market", district),
        "Variety": "Local / Hybrid",
        "Grade": "FAQ",
        "Min_Price": last_row["Min_Price"],
        "Max_Price": last_row["Max_Price"],
        "Modal_Price": last_row["Modal_Price"],
        "Modal_Price_KG": last_row["Modal_Price_KG"],
        "Min_Price_KG": last_row["Min_Price_KG"],
        "Max_Price_KG": last_row["Max_Price_KG"],
        "Arrival_Quantity_Tonnes": last_row["Arrival_Quantity_Tonnes"],
        "Demand_Quantity_KG": last_row["Demand_Quantity_KG"],
        "temp_max": temp_max,
        "temp_min": temp_min,
        "rain_sum": rain_sum,
    }

    # Append to recent history and build feature frame
    recent_extended = pd.concat([corridor_hist.tail(45), pd.DataFrame([new_row])], ignore_index=True)
    featured_extended = feature_engineer.transform(recent_extended)
    target_feature_vector = featured_extended.iloc[[-1]][feature_cols]

    # 5. Predict Demand Quantiles & Prices
    p10_demand = float(np.round(pipeline["demand_p10_model"].predict(target_feature_vector)[0], 0))
    p50_demand = float(np.round(pipeline["demand_p50_model"].predict(target_feature_vector)[0], 0))
    p90_demand = float(np.round(pipeline["demand_p90_model"].predict(target_feature_vector)[0], 0))

    # Ensure monotonic quantile consistency: P10 <= P50 <= P90
    p10_demand = max(100.0, p10_demand)
    p50_demand = max(p10_demand, p50_demand)
    p90_demand = max(p50_demand, p90_demand)

    expected_price = float(np.round(pipeline["price_model"].predict(target_feature_vector)[0], 2))
    min_spread = float(pipeline["price_min_spread_model"].predict(target_feature_vector)[0])
    max_spread = float(pipeline["price_max_spread_model"].predict(target_feature_vector)[0])

    min_price = float(np.round(max(5.0, expected_price - max(1.0, min_spread)), 2))
    max_price = float(np.round(expected_price + max(1.5, max_spread), 2))

    # 6. Generate NLP Insights & Recommendation
    insights_engine = AgriInsightsEngine()
    is_weekend = target_dt.dayofweek in [5, 6]
    price_mom = float(featured_extended["price_momentum_7d"].iloc[-1]) if "price_momentum_7d" in featured_extended else 0.0

    insight_text, rec_text = insights_engine.generate_advisory(
        commodity=commodity.capitalize(),
        district=district.capitalize(),
        state=resolved_state,
        target_date=target_date,
        p10=p10_demand,
        p50=p50_demand,
        p90=p90_demand,
        min_price=min_price,
        modal_price=expected_price,
        max_price=max_price,
        price_momentum=price_mom,
        rain_sum=rain_sum,
        is_weekend=is_weekend
    )

    # 7. Formulate Output Schema
    output = {
        "status": "SUCCESS",
        "meta": {
            "commodity": commodity.capitalize(),
            "district": district.capitalize(),
            "state": resolved_state,
            "target_date": target_date
        },
        "demand_forecast_kg": {
            "p10_pessimistic": int(p10_demand),
            "p50_expected": int(p50_demand),
            "p90_optimistic": int(p90_demand),
            "confidence_interval": "80%"
        },
        "price_forecast_inr_per_kg": {
            "min_price": min_price,
            "expected_modal_price": expected_price,
            "max_price": max_price
        },
        "actionable_insight": insight_text,
        "recommendation": rec_text
    }

    return output


if __name__ == "__main__":
    result = predict_demand_and_price("Tomato", "Karnal", "2026-08-30")
    print(json.dumps(result, indent=2))
