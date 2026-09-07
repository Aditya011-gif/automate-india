import json
import sys
import io
from pathlib import Path
from datetime import datetime, timedelta

# Set UTF-8 encoding for standard output
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from src.inference import predict_demand_and_price


def main():
    print("=" * 80)
    print(">> AI AGRICULTURAL DEMAND & PRICE FORECASTING ENGINE - DEMO")
    print("=" * 80)

    # Define test cases across the required corridors
    test_cases = [
        {"commodity": "Tomato", "district": "Karnal", "state": "Haryana", "days_ahead": 7},
        {"commodity": "Onion", "district": "Nashik", "state": "Maharashtra", "days_ahead": 10},
        {"commodity": "Wheat", "district": "Karnal", "state": "Haryana", "days_ahead": 14},
    ]

    base_date = datetime.now()

    for idx, tc in enumerate(test_cases, 1):
        target_dt = (base_date + timedelta(days=tc["days_ahead"])).strftime("%Y-%m-%d")
        print(f"\n[{idx}] Forecasting for {tc['commodity']} @ {tc['district']} ({tc['state']}) on {target_dt} (+{tc['days_ahead']} days ahead):")
        print("-" * 80)

        result = predict_demand_and_price(
            commodity=tc["commodity"],
            district=tc["district"],
            target_date=target_dt,
            state=tc["state"]
        )

        print(json.dumps(result, indent=2))

    print("\n" + "=" * 80)
    print("[OK] All demonstration forecasts generated successfully!")
    print("=" * 80)


if __name__ == "__main__":
    main()
