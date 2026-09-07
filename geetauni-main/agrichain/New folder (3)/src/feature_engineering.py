"""
Feature Engineering Pipeline for Agricultural Demand & Price Forecasting Engine.
Transforms time-series records into mathematical feature matrices with temporal,
autoregressive, rolling, agrometeorological, and categorical signals.
"""

import logging
from typing import Dict, List, Tuple
import holidays
import numpy as np
import pandas as pd
from sklearn.preprocessing import OneHotEncoder

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


class AgriFeatureEngineer:
    def __init__(self):
        self.india_holidays = holidays.India(years=list(range(2021, 2027)))
        self.holiday_dates = set(self.india_holidays.keys())
        self.categorical_encoder = None
        self.feature_columns = []

    def _compute_holiday_proximity(self, dates: pd.Series) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """Calculates is_holiday, days_to_next_holiday, and days_since_last_holiday."""
        dt_list = [d.date() if isinstance(d, pd.Timestamp) else d for d in dates]
        sorted_holidays = sorted(list(self.holiday_dates))

        is_holiday = np.array([1 if d in self.holiday_dates else 0 for d in dt_list], dtype=int)
        days_to_next = []
        days_since_last = []

        for d in dt_list:
            future = [h for h in sorted_holidays if h >= d]
            past = [h for h in sorted_holidays if h <= d]
            
            days_to_next.append((future[0] - d).days if future else 30)
            days_since_last.append((d - past[-1]).days if past else 30)

        return is_holiday, np.array(days_to_next), np.array(days_since_last)

    def _compute_consecutive_rainy_days(self, rain_series: pd.Series) -> np.ndarray:
        """Counts consecutive days with precipitation > 3.0mm."""
        consec = []
        count = 0
        for r in rain_series:
            if r > 3.0:
                count += 1
            else:
                count = 0
            consec.append(count)
        return np.array(consec)

    def fit_transform(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, List[str]]:
        """Fits encoders and transforms historical training dataframe."""
        df_featured = self._build_base_features(df)
        
        # Build Categorical Encodings
        cat_cols = ["Commodity", "State", "District"]
        self.categorical_encoder = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
        cat_encoded = self.categorical_encoder.fit_transform(df_featured[cat_cols])
        encoded_col_names = self.categorical_encoder.get_feature_names_out(cat_cols).tolist()

        df_cat = pd.DataFrame(cat_encoded, columns=encoded_col_names, index=df_featured.index)
        df_final = pd.concat([df_featured, df_cat], axis=1)

        # Drop initial NaN rows created by multi-day lags (up to 30 days)
        df_final = df_final.dropna().reset_index(drop=True)

        self.feature_columns = [
            c for c in df_final.columns if c not in [
                "date", "Arrival_Date", "Market", "Variety", "Grade",
                "Min_Price", "Max_Price", "Modal_Price",
                "Commodity", "State", "District",
                "Modal_Price_KG", "Min_Price_KG", "Max_Price_KG",
                "Arrival_Quantity_Tonnes", "Demand_Quantity_KG"
            ]
        ]
        logger.info(f"Feature engineering completed. Total features: {len(self.feature_columns)}")
        return df_final, self.feature_columns

    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """Transforms a dataframe using already fitted categorical encoders."""
        df_featured = self._build_base_features(df)
        cat_cols = ["Commodity", "State", "District"]
        cat_encoded = self.categorical_encoder.transform(df_featured[cat_cols])
        encoded_col_names = self.categorical_encoder.get_feature_names_out(cat_cols).tolist()
        df_cat = pd.DataFrame(cat_encoded, columns=encoded_col_names, index=df_featured.index)
        df_final = pd.concat([df_featured, df_cat], axis=1)
        return df_final

    def _build_base_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Constructs all temporal, lagged, rolling, and meteorological features per corridor."""
        df = df.copy()
        df["date"] = pd.to_datetime(df["date"])
        df = df.sort_values(by=["Commodity", "District", "date"]).reset_index(drop=True)

        # 1. Temporal & Calendar Features
        df["day_of_week"] = df["date"].dt.dayofweek
        df["day_of_month"] = df["date"].dt.day
        df["month"] = df["date"].dt.month
        df["quarter"] = df["date"].dt.quarter
        df["day_of_year"] = df["date"].dt.dayofyear

        # Cyclical transformations
        df["sin_day"] = np.sin(2 * np.pi * df["day_of_week"] / 7.0)
        df["cos_day"] = np.cos(2 * np.pi * df["day_of_week"] / 7.0)
        df["sin_month"] = np.sin(2 * np.pi * df["month"] / 12.0)
        df["cos_month"] = np.cos(2 * np.pi * df["month"] / 12.0)
        df["sin_doy"] = np.sin(2 * np.pi * df["day_of_year"] / 365.25)
        df["cos_doy"] = np.cos(2 * np.pi * df["day_of_year"] / 365.25)

        df["is_weekend"] = df["day_of_week"].apply(lambda x: 1 if x in [5, 6] else 0)

        # Holiday features
        is_hol, days_to_hol, days_since_hol = self._compute_holiday_proximity(df["date"])
        df["is_festival_or_holiday"] = is_hol
        df["days_to_next_holiday"] = days_to_hol
        df["days_since_last_holiday"] = days_since_hol

        # 2. Weather Interactions
        df["temp_range"] = df["temp_max"] - df["temp_min"]
        df["is_extreme_heat"] = (df["temp_max"] > 40.0).astype(int)
        df["is_heavy_rain"] = (df["rain_sum"] > 25.0).astype(int)

        # Group-wise lags and rolling statistics per commodity and district
        corridor_dfs = []
        for (comm, dist), g in df.groupby(["Commodity", "District"]):
            g = g.sort_values("date").copy()
            g["consecutive_rainy_days"] = self._compute_consecutive_rainy_days(g["rain_sum"])

            # Target Lags
            for lag in [1, 2, 3, 7, 14, 30]:
                g[f"demand_lag_{lag}"] = g["Demand_Quantity_KG"].shift(lag)
                g[f"price_lag_{lag}"] = g["Modal_Price_KG"].shift(lag)

            # Rolling Window Aggregations (7-day and 14-day)
            for window in [7, 14]:
                # Demand rolling
                g[f"demand_roll_mean_{window}"] = g["Demand_Quantity_KG"].shift(1).rolling(window).mean()
                g[f"demand_roll_std_{window}"] = g["Demand_Quantity_KG"].shift(1).rolling(window).std().fillna(0)
                g[f"demand_roll_min_{window}"] = g["Demand_Quantity_KG"].shift(1).rolling(window).min()
                g[f"demand_roll_max_{window}"] = g["Demand_Quantity_KG"].shift(1).rolling(window).max()

                # Price rolling
                g[f"price_roll_mean_{window}"] = g["Modal_Price_KG"].shift(1).rolling(window).mean()
                g[f"price_roll_std_{window}"] = g["Modal_Price_KG"].shift(1).rolling(window).std().fillna(0)
                g[f"price_roll_min_{window}"] = g["Modal_Price_KG"].shift(1).rolling(window).min()
                g[f"price_roll_max_{window}"] = g["Modal_Price_KG"].shift(1).rolling(window).max()

            # Exponential Moving Averages (EMA)
            g["demand_ema_7"] = g["Demand_Quantity_KG"].shift(1).ewm(span=7, adjust=False).mean()
            g["demand_ema_14"] = g["Demand_Quantity_KG"].shift(1).ewm(span=14, adjust=False).mean()
            g["price_ema_7"] = g["Modal_Price_KG"].shift(1).ewm(span=7, adjust=False).mean()
            g["price_ema_14"] = g["Modal_Price_KG"].shift(1).ewm(span=14, adjust=False).mean()

            # Price Momentum & Volatility
            g["price_momentum_7d"] = (g["price_lag_1"] - g["price_lag_7"]) / (g["price_lag_7"] + 1e-5)
            g["demand_momentum_7d"] = (g["demand_lag_1"] - g["demand_lag_7"]) / (g["demand_lag_7"] + 1e-5)

            corridor_dfs.append(g)

        return pd.concat(corridor_dfs, ignore_index=True)
