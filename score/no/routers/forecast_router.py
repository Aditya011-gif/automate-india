"""Forecast Router — Agricultural Demand (P10/P50/P90) & Price Forecasting endpoints."""

import logging
from datetime import datetime, date
from typing import Dict, List, Optional
from fastapi import APIRouter, HTTPException, Query, Request
from pydantic import BaseModel, Field

from ml.forecasting.config import COMMODITIES, CORRIDOR_COORDINATES
from ml.forecasting.inference import load_pipeline, predict_demand_and_price
from utils.rate_limiter import limiter

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/forecast", tags=["Demand & Price Forecasting"])


class ForecastRequest(BaseModel):
    commodity: str = Field(..., example="Tomato", description="Commodity: Tomato, Onion, or Wheat")
    district: str = Field(..., example="Karnal", description="District or Mandi cluster (e.g. Karnal, Nashik, Azadpur, Pune, Kolar)")
    target_date: str = Field(..., example="2026-08-30", description="Target forecast date (YYYY-MM-DD), 7-14 days ahead")
    state: Optional[str] = Field(None, example="Haryana", description="Optional state name")


class DemandForecast(BaseModel):
    p10_pessimistic: int
    p50_expected: int
    p90_optimistic: int
    confidence_interval: str


class PriceForecast(BaseModel):
    min_price: float
    expected_modal_price: float
    max_price: float


class ForecastMeta(BaseModel):
    commodity: str
    district: str
    state: str
    target_date: str


class ForecastResponse(BaseModel):
    status: str
    meta: ForecastMeta
    demand_forecast_kg: DemandForecast
    price_forecast_inr_per_kg: PriceForecast
    actionable_insight: str
    recommendation: str


@router.get("/health")
def forecasting_health():
    """Health check for forecasting engine."""
    try:
        pipeline = load_pipeline()
        return {
            "status": "HEALTHY",
            "forecasting_engine": "KrishiDrishti AI (LightGBM Quantile)",
            "model_loaded": pipeline is not None,
        }
    except Exception as e:
        return {
            "status": "DEGRADED",
            "model_loaded": False,
            "error": str(e)
        }


@router.get("/supported-corridors")
def get_supported_corridors():
    """Returns list of supported agricultural corridors and coordinates."""
    corridors = []
    for (commodity, district, state), coords in CORRIDOR_COORDINATES.items():
        meta = COMMODITIES.get(commodity, {})
        corridors.append({
            "commodity": commodity,
            "category": meta.get("category", "General"),
            "state": state,
            "district": district,
            "market": coords.get("market", district),
            "coordinates": {
                "latitude": coords["lat"],
                "longitude": coords["lon"]
            }
        })
    return {"status": "SUCCESS", "corridors": corridors}


@router.post("", response_model=ForecastResponse)
@router.post("/", response_model=ForecastResponse)
def create_forecast_post(payload: ForecastRequest):
    """Generates demand and price forecast via POST request."""
    try:
        result = predict_demand_and_price(
            commodity=payload.commodity,
            district=payload.district,
            target_date=payload.target_date,
            state=payload.state
        )
        return result
    except Exception as e:
        logger.error(f"Forecasting error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Forecasting calculation failed: {str(e)}")


@router.get("", response_model=ForecastResponse)
@router.get("/", response_model=ForecastResponse)
def create_forecast_get(
    commodity: str = Query(..., example="Tomato"),
    district: str = Query(..., example="Karnal"),
    target_date: str = Query(..., example="2026-08-30"),
    state: Optional[str] = Query(None, example="Haryana")
):
    """Generates demand and price forecast via GET query parameters."""
    try:
        result = predict_demand_and_price(
            commodity=commodity,
            district=district,
            target_date=target_date,
            state=state
        )
        return result
    except Exception as e:
        logger.error(f"Forecasting error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Forecasting calculation failed: {str(e)}")
