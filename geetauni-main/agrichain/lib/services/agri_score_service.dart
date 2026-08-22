import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'score_engine.dart';

class AgriScoreService {
  final Dio _dio = Dio();

  static const String agroMonitoringApiKey = '5df44b52d07775cc34d87de06faedafe';
  static const String openWeatherApiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: 'YOUR_OPENWEATHER_API_KEY');
  // Use 10.0.2.2 for Android emulator to reach localhost, or localhost for web/iOS
  static const String apiBaseUrl = kIsWeb
      ? 'http://localhost:8000/api'
      : 'http://10.143.90.102:8000/api';

  AgriScoreService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<Map<String, dynamic>> analyzeLand({
    required double latitude,
    required double longitude,
  }) async {
    debugPrint('AgriScoreService: Starting analysis for $latitude, $longitude');
    try {
      final results = await Future.wait([
        _fetchNdvi(latitude, longitude),
        _fetchSoil(latitude, longitude),
        _fetchWeather(latitude, longitude),
        _fetchMarket(latitude, longitude),
      ]);

      final ndviData = results[0];
      final soilData = results[1];
      final weatherData = results[2];
      final marketData = results[3];

      final scoreResult = ScoreEngine.calculateAgriScore(
        ndvi: (ndviData['ndvi'] as num).toDouble(),
        soilType: soilData['soil_type'] as String,
        landClass: soilData['land_class'] as String,
        weatherIndex: (weatherData['weather_index'] as num).toDouble(),
        marketIndex: (marketData['market_index'] as num).toDouble(),
      );

      final ndviVal = (ndviData['ndvi'] as num).toDouble();

      // Attempt to fetch ML predictions
      Map<String, dynamic>? mlPredictions;
      try {
        final double tempC = (weatherData['temp'] as num?)?.toDouble() ?? 28.0;
        final double rainMm =
            (weatherData['rainfall'] as num?)?.toDouble() ?? 50.0;

        mlPredictions = await fetchMLPredictions(
          ndviCurrent: ndviVal,
          soilType: soilData['soil_type'] as String? ?? 'Mixed Soil',
          rainfallMm: rainMm,
          avgTempC: tempC,
        );
      } catch (e) {
        debugPrint('AgriScoreService: ML predictions failed: $e');
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
        'ndvi_value': ndviVal,
        'soil_type': soilData['soil_type'],
        'land_class': soilData['land_class'],
        'weather_index': weatherData['weather_index'],
        'market_index': marketData['market_index'],
        'agri_score': scoreResult['agri_score'],
        'risk_category': scoreResult['risk_category'],
        'score_breakdown': scoreResult['score_breakdown'],
        'weather_details': weatherData,
        if (mlPredictions != null) 'ml_predictions': mlPredictions,
      };
    } catch (e) {
      debugPrint('Analysis Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchMLPredictions({
    required double ndviCurrent,
    required String soilType,
    double rainfallMm = 50.0,
    double avgTempC = 28.0,
    String cropType = 'Rice',
    String season = 'Kharif',
    double landAreaHectares = 5.0,
  }) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/predict',
        data: {
          'crop_type': cropType,
          'season': season,
          'land_area_hectares': landAreaHectares,
          'soil_type': soilType,
          'ndvi_current': ndviCurrent,
          'ndvi_30day_avg': ndviCurrent * 0.95,
          'rainfall_mm': rainfallMm,
          'avg_temperature_c': avgTempC,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('ML API error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchNdvi(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/gee/ndvi-score',
        queryParameters: {
          'lat': lat,
          'lng': lng,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('ndvi')) {
          final ndvi = (data['ndvi'] as num).toDouble();
          return {
            'ndvi': ndvi.clamp(0.0, 1.0),
            'source': data['source'] ?? 'Google Earth Engine'
          };
        }
      }
    } catch (e) {
      debugPrint('GEE backend failed or not authenticated: $e');
    }

    // Fallback to generated if GEE backend fails (e.g., service account not set up)
    return _generateEstimatedNdvi(lat, lng);
  }

  // Agromonitoring cleanup removed

  Future<Map<String, dynamic>> _fetchSoil(double lat, double lng) async {
    // Determine if urban via OSM
    bool isUrban = false;
    try {
      final osmResp = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'AgriChainApp/1.0'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (osmResp.statusCode == 200 && osmResp.data != null) {
        final address = osmResp.data['address'] as Map<String, dynamic>? ?? {};
        if (address.containsKey('city') ||
            address.containsKey('suburb') ||
            address.containsKey('town') ||
            address.containsKey('residential') ||
            address.containsKey('commercial') ||
            address.containsKey('industrial') ||
            address.containsKey('neighbourhood')) {
          isUrban = true;
        }
      }
    } catch (e) {
      debugPrint('OSM reverse geocoding failed: $e');
      // If OSM fails, assume it's not urban (allows testing agricultural lands)
    }

    if (isUrban) {
      return {'soil_type': 'Concrete / Degraded', 'land_class': 'Urban / Industrial Area'};
    }

    // Return an estimated/dummy value for agricultural areas
    await Future.delayed(const Duration(milliseconds: 600));
    String soil = "Mixed Soil";
    String land = "Agricultural Land";

    if (lat >= 16 && lat <= 24 && lng >= 72 && lng <= 82) {
      soil = "Black Cotton Soil";
      land = "Prime Agricultural Land";
    } else if (lat >= 24 && lat <= 30) {
      soil = "Alluvial Soil";
      land = "Fertile Agricultural Land";
    }

    return {'soil_type': soil, 'land_class': land};
  }

  Future<Map<String, dynamic>> _fetchWeather(double lat, double lng) async {
    if (kIsWeb) {
      return _estimateWeather(lat, lng);
    }

    try {
      final response = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'appid': openWeatherApiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final temp = (data['main']['temp'] as num).toDouble();
        final humidity = (data['main']['humidity'] as num).toDouble();

        double index = 0.5;
        if (temp > 20 && temp < 35 && humidity > 40)
          index = 0.9;
        else if (temp > 10 && temp < 40)
          index = 0.7;
        else
          index = 0.4;

        double rain = 0.0;
        if (data['rain'] != null) {
          rain = (data['rain']['1h'] as num?)?.toDouble() ?? 0.0;
        }

        return {
          'weather_index': index,
          'summary': 'Temp: $temp°C, Hum: $humidity%',
          'temp': temp,
          'rainfall': rain,
          'humidity': humidity,
        };
      }
      return _estimateWeather(lat, lng);
    } catch (e) {
      return _estimateWeather(lat, lng);
    }
  }

  Future<Map<String, dynamic>> _fetchMarket(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {'market_index': 0.70, 'summary': 'Stable market prices'};
  }

  Future<Map<String, dynamic>> _generateEstimatedNdvi(double lat, double lng) async {
    bool isUrban = false;
    try {
      final osmResp = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'AgriChainApp/1.0'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (osmResp.statusCode == 200 && osmResp.data != null) {
        final address = osmResp.data['address'] as Map<String, dynamic>? ?? {};
        if (address.containsKey('city') || address.containsKey('suburb') || address.containsKey('town') || address.containsKey('residential')) {
          isUrban = true;
        }
      }
    } catch (e) {
      debugPrint('OSM reverse geocoding failed: $e');
      // If OSM fails, assume it's not urban
    }

    double baseNdvi;
    if (isUrban) {
      baseNdvi = 0.15; // Very low for concrete/buildings
    } else {
      if (lat >= 24 && lat <= 30 && lng >= 75 && lng <= 88)
        baseNdvi = 0.72;
      else if ((lat >= 8 && lat <= 15 && lng >= 74 && lng <= 80) ||
          (lat >= 15 && lat <= 22 && lng >= 72 && lng <= 78))
        baseNdvi = 0.60;
      else if (lat >= 15 && lat <= 24 && lng >= 73 && lng <= 82)
        baseNdvi = 0.55;
      else if (lat >= 8 && lat <= 35 && lng >= 68 && lng <= 97)
        baseNdvi = 0.50;
      else if (lat >= 24 && lat <= 30 && lng >= 68 && lng <= 75)
        baseNdvi = 0.25;
      else
        baseNdvi = 0.35;
    }

    final variation1 = sin(lat * 13.7 + lng * 7.3) * 0.12;
    final variation2 = cos(lat * 23.1 - lng * 11.9) * 0.08;
    final variation3 = sin((lat + lng) * 5.3) * 0.05;

    double ndvi = baseNdvi + (isUrban ? 0 : variation1 + variation2 + variation3);
    return {'ndvi': ndvi.clamp(0.05, 0.95), 'source': 'estimated'};
  }

  Map<String, dynamic> _estimateWeather(double lat, double lng) {
    final seed = (lat * 1000 + lng * 1000).toInt();
    final random = Random(seed);

    final temp = 20 + random.nextDouble() * 15;
    final rainfall = random.nextDouble() * 200;
    final humidity = 30 + random.nextDouble() * 60;

    String summary;
    if (rainfall > 100)
      summary = 'Heavy Rain, ${temp.toStringAsFixed(1)}°C';
    else if (rainfall > 20)
      summary = 'Light Rain, ${temp.toStringAsFixed(1)}°C';
    else if (temp > 30)
      summary = 'Sunny & Hot, ${temp.toStringAsFixed(1)}°C';
    else
      summary = 'Clear Sky, ${temp.toStringAsFixed(1)}°C';

    return {
      'weather_index': 0.6 + (random.nextDouble() * 0.3),
      'summary': summary,
      'temp': temp,
      'rainfall': rainfall,
      'humidity': humidity,
    };
  }
}
