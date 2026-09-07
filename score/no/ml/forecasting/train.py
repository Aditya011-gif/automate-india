"""
Model Training & Walk-Forward Validation Module for Agricultural Demand & Price Forecasting.
Trains LightGBM Quantile Regressors (P10, P50, P90) and Price Regressors, computes WAPE/RMSE/R2 metrics,
and serializes the production pipeline artifact.
"""

import logging
import sys
from pathlib import Path
from typing import Dict, Tuple

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

import joblib
import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

from src.config import MODEL_PATH
from src.data_loader import MandiDataLoader
from src.feature_engineering import AgriFeatureEngineer

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def compute_wape(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    """Calculates Weighted Absolute Percentage Error (WAPE)."""
    sum_actual = np.sum(np.abs(y_true))
    if sum_actual == 0:
        return 0.0
    return float(np.sum(np.abs(y_true - y_pred)) / sum_actual) * 100.0


class ModelTrainer:
    def __init__(self):
        self.feature_engineer = AgriFeatureEngineer()
        self.demand_p10_model = None
        self.demand_p50_model = None
        self.demand_p90_model = None
        self.price_model = None
        self.price_min_spread_model = None
        self.price_max_spread_model = None
        self.feature_cols = []

    def train_pipeline(self, df_raw: pd.DataFrame) -> Dict:
        """Runs feature engineering, walk-forward validation, and final full fit."""
        logger.info("Transforming raw data into feature matrices...")
        df_featured, self.feature_cols = self.feature_engineer.fit_transform(df_raw)

        # Sort chronologically for time-series walk forward evaluation
        df_featured = df_featured.sort_values("date").reset_index(drop=True)
        
        # 80/20 Chronological Split for out-of-time walk-forward validation
        split_idx = int(len(df_featured) * 0.80)
        train_df = df_featured.iloc[:split_idx]
        val_df = df_featured.iloc[split_idx:]

        X_train = train_df[self.feature_cols]
        X_val = val_df[self.feature_cols]

        y_demand_train = train_df["Demand_Quantity_KG"]
        y_demand_val = val_df["Demand_Quantity_KG"]

        y_price_train = train_df["Modal_Price_KG"]
        y_price_val = val_df["Modal_Price_KG"]

        logger.info(f"Training dataset size: {len(train_df)} | Validation dataset size: {len(val_df)}")
        logger.info(f"Number of input features: {len(self.feature_cols)}")

        # 1. Train Demand Quantile Models (LightGBM)
        logger.info("Training LightGBM Quantile Demand Models (P10, P50, P90)...")
        p10_params = {"objective": "quantile", "alpha": 0.10, "n_estimators": 250, "learning_rate": 0.05, "verbose": -1, "random_state": 42}
        p50_params = {"objective": "quantile", "alpha": 0.50, "n_estimators": 250, "learning_rate": 0.05, "verbose": -1, "random_state": 42}
        p90_params = {"objective": "quantile", "alpha": 0.90, "n_estimators": 250, "learning_rate": 0.05, "verbose": -1, "random_state": 42}

        self.demand_p10_model = lgb.LGBMRegressor(**p10_params).fit(X_train, y_demand_train)
        self.demand_p50_model = lgb.LGBMRegressor(**p50_params).fit(X_train, y_demand_train)
        self.demand_p90_model = lgb.LGBMRegressor(**p90_params).fit(X_train, y_demand_train)

        # 2. Train Price Model (LightGBM Regressor)
        logger.info("Training LightGBM Price Regressor...")
        price_params = {"objective": "regression", "metric": "rmse", "n_estimators": 300, "learning_rate": 0.04, "verbose": -1, "random_state": 42}
        self.price_model = lgb.LGBMRegressor(**price_params).fit(X_train, y_price_train)

        # Price Spread Models (Min & Max Price)
        y_min_spread_train = train_df["Modal_Price_KG"] - train_df["Min_Price_KG"]
        y_max_spread_train = train_df["Max_Price_KG"] - train_df["Modal_Price_KG"]
        self.price_min_spread_model = lgb.LGBMRegressor(n_estimators=100, learning_rate=0.05, verbose=-1).fit(X_train, y_min_spread_train)
        self.price_max_spread_model = lgb.LGBMRegressor(n_estimators=100, learning_rate=0.05, verbose=-1).fit(X_train, y_max_spread_train)

        # 3. Evaluate Metrics on Out-of-Time Validation Set
        p50_pred = self.demand_p50_model.predict(X_val)
        p10_pred = self.demand_p10_model.predict(X_val)
        p90_pred = self.demand_p90_model.predict(X_val)
        price_pred = self.price_model.predict(X_val)

        # Demand Metrics
        demand_wape = compute_wape(y_demand_val.values, p50_pred)
        demand_mae = mean_absolute_error(y_demand_val, p50_pred)
        demand_rmse = np.sqrt(mean_squared_error(y_demand_val, p50_pred))
        demand_r2 = r2_score(y_demand_val, p50_pred)

        # Price Metrics
        price_wape = compute_wape(y_price_val.values, price_pred)
        price_mae = mean_absolute_error(y_price_val, price_pred)
        price_rmse = np.sqrt(mean_squared_error(y_price_val, price_pred))
        price_r2 = r2_score(y_price_val, price_pred)

        metrics = {
            "demand": {
                "wape_percent": round(demand_wape, 2),
                "mae_kg": round(demand_mae, 2),
                "rmse_kg": round(demand_rmse, 2),
                "r2_score": round(demand_r2, 4),
            },
            "price": {
                "wape_percent": round(price_wape, 2),
                "mae_inr": round(price_mae, 2),
                "rmse_inr": round(price_rmse, 2),
                "r2_score": round(price_r2, 4),
            }
        }

        logger.info("================ EVALUATION BENCHMARKS ================")
        logger.info(f"Demand Forecaster (P50) -> WAPE: {demand_wape:.2f}% | R²: {demand_r2:.4f} | RMSE: {demand_rmse:.2f} kg")
        logger.info(f"Price Forecaster        -> WAPE: {price_wape:.2f}% | R²: {price_r2:.4f} | RMSE: {price_rmse:.2f} INR")
        logger.info("=======================================================")

        # Retrain models on 100% of historical dataset for maximum deployment accuracy
        logger.info("Fitting final models on 100% of historical dataset for production export...")
        X_all = df_featured[self.feature_cols]
        self.demand_p10_model.fit(X_all, df_featured["Demand_Quantity_KG"])
        self.demand_p50_model.fit(X_all, df_featured["Demand_Quantity_KG"])
        self.demand_p90_model.fit(X_all, df_featured["Demand_Quantity_KG"])
        self.price_model.fit(X_all, df_featured["Modal_Price_KG"])
        self.price_min_spread_model.fit(X_all, df_featured["Modal_Price_KG"] - df_featured["Min_Price_KG"])
        self.price_max_spread_model.fit(X_all, df_featured["Max_Price_KG"] - df_featured["Modal_Price_KG"])

        # Save artifact package
        artifact = {
            "demand_p10_model": self.demand_p10_model,
            "demand_p50_model": self.demand_p50_model,
            "demand_p90_model": self.demand_p90_model,
            "price_model": self.price_model,
            "price_min_spread_model": self.price_min_spread_model,
            "price_max_spread_model": self.price_max_spread_model,
            "feature_engineer": self.feature_engineer,
            "feature_cols": self.feature_cols,
            "metrics": metrics,
            "last_training_date": df_featured["date"].max().strftime("%Y-%m-%d"),
        }

        joblib.dump(artifact, MODEL_PATH)
        logger.info(f"Pipeline artifact successfully exported to {MODEL_PATH}")
        return metrics


if __name__ == "__main__":
    loader = MandiDataLoader()
    df_data = loader.get_or_load_dataset()
    trainer = ModelTrainer()
    results = trainer.train_pipeline(df_data)
    print("Training finished successfully:", results)
