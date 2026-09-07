"""
Natural Language Insights & Advisory Engine for Agricultural Stakeholders.
Generates domain-specific, actionable advisories on harvest schedules, storage holding,
and optimal mandi dispatch timing for farmers and FPOs.
"""

from datetime import datetime, timedelta
from typing import Dict, Tuple
import holidays


class AgriInsightsEngine:
    def __init__(self):
        self.india_holidays = holidays.India(years=list(range(2021, 2027)))

    def generate_advisory(
        self,
        commodity: str,
        district: str,
        state: str,
        target_date: str,
        p10: float,
        p50: float,
        p90: float,
        min_price: float,
        modal_price: float,
        max_price: float,
        price_momentum: float = 0.0,
        rain_sum: float = 0.0,
        is_weekend: bool = False,
    ) -> Tuple[str, str]:
        """
        Generates actionable natural language insight and recommendation.
        Returns (actionable_insight, recommendation).
        """
        dt = datetime.strptime(target_date, "%Y-%m-%d")
        formatted_date = dt.strftime("%d %B %Y")
        
        # 1. Demand Surge & Volume Analysis
        spread = p90 - p10
        surge_ratio = (p90 - p50) / (p50 + 1e-5)
        
        holiday_name = self.india_holidays.get(dt.date(), None)
        
        reasons = []
        if holiday_name:
            reasons.append(f"festive demand spike ahead of {holiday_name}")
        elif is_weekend:
            reasons.append("weekend institutional and hotel/restaurant order spikes")
        elif rain_sum > 20.0:
            reasons.append("monsoon-driven transit delays tightening local arrivals")
        elif price_momentum > 0.05:
            reasons.append("bullish price momentum driven by regional wholesale buyers")
        else:
            reasons.append("steady retail consumption across urban corridors")

        reason_str = ", ".join(reasons)

        insight = (
            f"Projected {commodity.lower()} demand in {district} cluster ({state}) for {formatted_date} "
            f"is {p10:,.0f}–{p90:,.0f} kg (Median Expected: {p50:,.0f} kg). "
            f"Expected modal price is ₹{modal_price:.2f}/kg (range ₹{min_price:.2f}–₹{max_price:.2f}/kg). "
            f"Key driver: {reason_str}."
        )

        # 2. Actionable Recommendation Strategy for Farmers/FPOs
        if commodity == "Tomato":
            if modal_price > 25.0:
                rec = (
                    f"Harvest ~{round(p50 * 0.95):,.0f} kg on the evening of {((dt - timedelta(days=1)).strftime('%d %b'))} "
                    f"for 4:00 AM auction delivery at {district} Mandi to capture peak modal price realization of ₹{modal_price:.2f}/kg."
                )
            else:
                rec = (
                    f"Market prices currently stable around ₹{modal_price:.2f}/kg. "
                    f"Grade tomatoes into 'A-Grade' crates to secure higher-band rates (up to ₹{max_price:.2f}/kg) or stagger dispatch."
                )
        elif commodity == "Onion":
            if price_momentum > 0.08:
                rec = (
                    f"Price trajectory is upward (+{price_momentum*100:.1f}% 7-day trend). "
                    f"If equipped with ventilated storage/chawl, hold 30% of stock and liquidate {round(p50 * 0.7):,.0f} kg on {formatted_date}."
                )
            else:
                rec = (
                    f"Expected arrivals indicate steady volume. "
                    f"Dispatch {round(p50):,.0f} kg cured onion to {district} market; avoid damp handling if rain forecast exceeds 5mm."
                )
        else:  # Wheat
            if modal_price > 24.0:
                rec = (
                    f"Grain price is favorable (₹{modal_price:.2f}/kg). "
                    f"FPOs should aggregate lot sizes > 15 Tonnes to negotiate directly with millers and avoid mandi intermediary fees."
                )
            else:
                rec = (
                    f"Store moisture-tested grain in dry warehouses; hold for target realization band of ₹{max_price:.2f}/kg within 14 days."
                )

        return insight, rec
