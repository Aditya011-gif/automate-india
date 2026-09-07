"""
FastAPI REST API Server for Agricultural Demand & Price Forecasting Engine.
Provides high-performance endpoints for frontend dashboard integration and real-time inference.
"""

from datetime import datetime, date
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from src.config import COMMODITIES, CORRIDOR_COORDINATES
from src.inference import load_pipeline, predict_demand_and_price

app = FastAPI(
    title="AI Agricultural Demand & Price Forecasting Engine",
    description="Probabilistic Demand (P10/P50/P90) & Price Forecasting API for Farmers, FPOs, and Mandi Aggregators.",
    version="1.0.0"
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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


@app.on_event("startup")
def startup_event():
    """Pre-load model pipeline into memory upon startup."""
    try:
        load_pipeline()
    except Exception as e:
        print(f"Warning during startup pipeline load: {e}")


@app.get("/health", tags=["System"])
def health_check():
    """Health check endpoint returning model status and benchmark metrics."""
    try:
        pipeline = load_pipeline()
        return {
            "status": "HEALTHY",
            "model_loaded": True,
            "benchmarks": pipeline.get("metrics", {}),
            "last_training_date": pipeline.get("last_training_date", "N/A"),
        }
    except Exception as e:
        return {
            "status": "DEGRADED",
            "model_loaded": False,
            "error": str(e)
        }


@app.get("/supported-corridors", tags=["Metadata"])
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


@app.post("/forecast", response_model=ForecastResponse, tags=["Forecasting"])
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
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/forecast", response_model=ForecastResponse, tags=["Forecasting"])
def create_forecast_get(
    commodity: str = Query(..., example="Tomato", description="Commodity: Tomato, Onion, Wheat"),
    district: str = Query(..., example="Karnal", description="District/Mandi: Karnal, Nashik, Azadpur, etc."),
    target_date: str = Query(..., example="2026-08-30", description="Target forecast date (YYYY-MM-DD)"),
    state: Optional[str] = Query(None, example="Haryana", description="Optional State")
):
    """Generates demand and price forecast via GET request."""
    try:
        result = predict_demand_and_price(
            commodity=commodity,
            district=district,
            target_date=target_date,
            state=state
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("src.app:app", host="0.0.0.0", port=8000, reload=True)
