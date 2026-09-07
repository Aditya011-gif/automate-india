import sys
import unittest
from pathlib import Path
from datetime import datetime, timedelta

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from src.data_loader import MandiDataLoader
from src.feature_engineering import AgriFeatureEngineer
from src.inference import predict_demand_and_price


class TestAgriForecastingPipeline(unittest.TestCase):

    def setUp(self):
        self.loader = MandiDataLoader()
        self.feature_engineer = AgriFeatureEngineer()

    def test_data_loader(self):
        df = self.loader.get_or_load_dataset()
        self.assertGreater(len(df), 500)
        self.assertIn("Demand_Quantity_KG", df.columns)
        self.assertIn("Modal_Price_KG", df.columns)

    def test_feature_engineering(self):
        df = self.loader.get_or_load_dataset()
        df_feat, cols = self.feature_engineer.fit_transform(df)
        self.assertGreater(len(cols), 10)
        self.assertIn("sin_day", df_feat.columns)
        self.assertIn("cos_day", df_feat.columns)
        self.assertIn("days_to_next_holiday", df_feat.columns)
        self.assertIn("demand_lag_1", df_feat.columns)
        self.assertIn("price_lag_7", df_feat.columns)

    def test_inference_output_contract(self):
        target_date = (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d")
        result = predict_demand_and_price("Tomato", "Karnal", target_date)

        # Verify exact JSON schema
        self.assertEqual(result["status"], "SUCCESS")
        self.assertIn("meta", result)
        self.assertIn("demand_forecast_kg", result)
        self.assertIn("price_forecast_inr_per_kg", result)
        self.assertIn("actionable_insight", result)
        self.assertIn("recommendation", result)

        demand = result["demand_forecast_kg"]
        self.assertGreater(demand["p10_pessimistic"], 0)
        self.assertGreaterEqual(demand["p50_expected"], demand["p10_pessimistic"])
        self.assertGreaterEqual(demand["p90_optimistic"], demand["p50_expected"])

        price = result["price_forecast_inr_per_kg"]
        self.assertGreater(price["min_price"], 0)
        self.assertGreaterEqual(price["expected_modal_price"], price["min_price"])
        self.assertGreaterEqual(price["max_price"], price["expected_modal_price"])


if __name__ == "__main__":
    unittest.main()
