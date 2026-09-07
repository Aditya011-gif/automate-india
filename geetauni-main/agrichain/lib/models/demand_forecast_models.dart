/// Models for KrishiDrishti AI Demand & Price Forecasting Engine

class DemandForecastResponse {
  final String status;
  final ForecastMeta meta;
  final DemandForecastData demandForecastKg;
  final PriceForecastData priceForecastInrPerKg;
  final String actionableInsight;
  final String recommendation;

  const DemandForecastResponse({
    required this.status,
    required this.meta,
    required this.demandForecastKg,
    required this.priceForecastInrPerKg,
    required this.actionableInsight,
    required this.recommendation,
  });

  factory DemandForecastResponse.fromJson(Map<String, dynamic> json) {
    return DemandForecastResponse(
      status: json['status'] as String? ?? 'SUCCESS',
      meta: ForecastMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
      demandForecastKg: DemandForecastData.fromJson(
        json['demand_forecast_kg'] as Map<String, dynamic>? ?? {},
      ),
      priceForecastInrPerKg: PriceForecastData.fromJson(
        json['price_forecast_inr_per_kg'] as Map<String, dynamic>? ?? {},
      ),
      actionableInsight: json['actionable_insight'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'meta': meta.toJson(),
    'demand_forecast_kg': demandForecastKg.toJson(),
    'price_forecast_inr_per_kg': priceForecastInrPerKg.toJson(),
    'actionable_insight': actionableInsight,
    'recommendation': recommendation,
  };
}

class ForecastMeta {
  final String commodity;
  final String district;
  final String state;
  final String targetDate;

  const ForecastMeta({
    required this.commodity,
    required this.district,
    required this.state,
    required this.targetDate,
  });

  factory ForecastMeta.fromJson(Map<String, dynamic> json) {
    return ForecastMeta(
      commodity: json['commodity'] as String? ?? 'Tomato',
      district: json['district'] as String? ?? 'Karnal',
      state: json['state'] as String? ?? 'Haryana',
      targetDate: json['target_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'commodity': commodity,
    'district': district,
    'state': state,
    'target_date': targetDate,
  };
}

class DemandForecastData {
  final int p10Pessimistic;
  final int p50Expected;
  final int p90Optimistic;
  final String confidenceInterval;

  const DemandForecastData({
    required this.p10Pessimistic,
    required this.p50Expected,
    required this.p90Optimistic,
    required this.confidenceInterval,
  });

  factory DemandForecastData.fromJson(Map<String, dynamic> json) {
    return DemandForecastData(
      p10Pessimistic: (json['p10_pessimistic'] as num?)?.toInt() ?? 3000,
      p50Expected: (json['p50_expected'] as num?)?.toInt() ?? 4500,
      p90Optimistic: (json['p90_optimistic'] as num?)?.toInt() ?? 6200,
      confidenceInterval: json['confidence_interval'] as String? ?? '80%',
    );
  }

  Map<String, dynamic> toJson() => {
    'p10_pessimistic': p10Pessimistic,
    'p50_expected': p50Expected,
    'p90_optimistic': p90Optimistic,
    'confidence_interval': confidenceInterval,
  };
}

class PriceForecastData {
  final double minPrice;
  final double expectedModalPrice;
  final double maxPrice;

  const PriceForecastData({
    required this.minPrice,
    required this.expectedModalPrice,
    required this.maxPrice,
  });

  factory PriceForecastData.fromJson(Map<String, dynamic> json) {
    return PriceForecastData(
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 18.0,
      expectedModalPrice: (json['expected_modal_price'] as num?)?.toDouble() ?? 28.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 38.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'min_price': minPrice,
    'expected_modal_price': expectedModalPrice,
    'max_price': maxPrice,
  };
}

class SupportedCorridor {
  final String commodity;
  final String category;
  final String state;
  final String district;
  final String market;
  final double latitude;
  final double longitude;

  const SupportedCorridor({
    required this.commodity,
    required this.category,
    required this.state,
    required this.district,
    required this.market,
    required this.latitude,
    required this.longitude,
  });

  factory SupportedCorridor.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>? ?? {};
    return SupportedCorridor(
      commodity: json['commodity'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      state: json['state'] as String? ?? '',
      district: json['district'] as String? ?? '',
      market: json['market'] as String? ?? '',
      latitude: (coords['latitude'] as num?)?.toDouble() ?? 28.6139,
      longitude: (coords['longitude'] as num?)?.toDouble() ?? 77.2090,
    );
  }
}
