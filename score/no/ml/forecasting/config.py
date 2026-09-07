"""
Configuration Module for AI Agricultural Demand & Price Forecasting Engine
"""

import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"
MODEL_DIR = BASE_DIR / "ml" / "models"
MODEL_PATH = MODEL_DIR / "agritech_forecast_pipeline.joblib"

RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
MODEL_DIR.mkdir(parents=True, exist_ok=True)

# API Configurations
DATA_GOV_API_KEY = os.getenv("DATA_GOV_API_KEY", "579b464db66ec23bdd0000015ed0ff4f29884b4c593eaba7878fb2d9")
DATA_GOV_RESOURCE_URL = "https://api.data.gov.in/resource/35985678-0d79-46b4-9ed6-6f13308a1d24"

OPEN_METEO_ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"
OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

# Target Mandi Corridor GPS Coordinates
CORRIDOR_COORDINATES = {
    ("Tomato", "Karnal", "Haryana"): {"lat": 29.6857, "lon": 76.9905, "market": "Karnal"},
    ("Tomato", "Nashik", "Maharashtra"): {"lat": 19.9975, "lon": 73.7898, "market": "Nashik"},
    ("Tomato", "Kolar", "Karnataka"): {"lat": 13.1367, "lon": 78.1291, "market": "Kolar"},
    ("Onion", "Nashik", "Maharashtra"): {"lat": 19.9975, "lon": 73.7898, "market": "Lasalgaon"},
    ("Onion", "Azadpur", "Delhi"): {"lat": 28.7164, "lon": 77.1772, "market": "Azadpur"},
    ("Wheat", "Karnal", "Haryana"): {"lat": 29.6857, "lon": 76.9905, "market": "Karnal"},
    ("Wheat", "Pune", "Maharashtra"): {"lat": 18.5204, "lon": 73.8567, "market": "Pune"},
}

# Supported Commodities and Metadata
COMMODITIES = {
    "Tomato": {
        "category": "Perishable",
        "base_price_range": (15.0, 45.0),
        "base_daily_demand_kg": (2000, 6000),
        "harvest_lag_days": 1,
        "shelf_life_days": 4,
    },
    "Onion": {
        "category": "Semi-Perishable",
        "base_price_range": (18.0, 55.0),
        "base_daily_demand_kg": (4000, 12000),
        "harvest_lag_days": 2,
        "shelf_life_days": 21,
    },
    "Wheat": {
        "category": "Staple Grain",
        "base_price_range": (22.0, 34.0),
        "base_daily_demand_kg": (8000, 25000),
        "harvest_lag_days": 7,
        "shelf_life_days": 180,
    }
}
