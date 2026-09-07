import json
import requests

test_scenarios = [
    {"commodity": "Tomato", "district": "Karnal", "target_date": "2026-09-06", "state": "Haryana"},
    {"commodity": "Onion", "district": "Nashik", "target_date": "2026-09-08", "state": "Maharashtra"},
    {"commodity": "Wheat", "district": "Pune", "target_date": "2026-09-12", "state": "Maharashtra"},
    {"commodity": "Rice", "district": "Taraori", "target_date": "2026-09-10", "state": "Haryana"},
]

print("=" * 80)
print("  KRISHIDRISHTI AI — 7-14 DAY FORWARD DEMAND & PRICE INFERENCE EXECUTION")
print("=" * 80)

for scenario in test_scenarios:
    res = requests.post("http://localhost:8000/api/forecast", json=scenario)
    data = res.json()
    meta = data["meta"]
    demand = data["demand_forecast_kg"]
    price = data["price_forecast_inr_per_kg"]
    
    print(f"\n[Crop: {meta['commodity']}] | Mandi Cluster: {meta['district']} ({meta['state']}) | Date: {meta['target_date']}")
    print(f"   -> Demand Quantiles : P10 = {demand['p10_pessimistic']} kg | P50 (Expected) = {demand['p50_expected']} kg | P90 = {demand['p90_optimistic']} kg (CI: {demand['confidence_interval']})")
    print(f"   -> Price Forecast   : Expected Modal = Rs {price['expected_modal_price']:.2f}/kg | Min-Max = Rs {price['min_price']:.2f} - Rs {price['max_price']:.2f}/kg")
    rec = data['recommendation'].replace('\u20b9', 'Rs ')
    print(f"   -> NLP Advisory     : {rec}")
    print("-" * 80)
