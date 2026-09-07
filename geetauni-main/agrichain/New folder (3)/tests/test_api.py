"""
FastAPI Server Endpoint Integration Tests
"""

import sys
import unittest
from pathlib import Path
from fastapi.testclient import TestClient

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from src.app import app


class TestAgriFastAPIServer(unittest.TestCase):

    def setUp(self):
        self.client = TestClient(app)

    def test_health_endpoint(self):
        resp = self.client.get("/health")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "HEALTHY")
        self.assertTrue(data["model_loaded"])
        self.assertIn("benchmarks", data)

    def test_supported_corridors_endpoint(self):
        resp = self.client.get("/supported-corridors")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "SUCCESS")
        self.assertGreater(len(data["corridors"]), 3)

    def test_forecast_post_endpoint(self):
        payload = {
            "commodity": "Tomato",
            "district": "Karnal",
            "state": "Haryana",
            "target_date": "2026-09-05"
        }
        resp = self.client.post("/forecast", json=payload)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "SUCCESS")
        self.assertIn("demand_forecast_kg", data)
        self.assertIn("price_forecast_inr_per_kg", data)
        self.assertIn("actionable_insight", data)
        self.assertIn("recommendation", data)


if __name__ == "__main__":
    unittest.main()
