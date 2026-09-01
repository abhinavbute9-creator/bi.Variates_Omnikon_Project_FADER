// lib/services/api_service.dart
//
// Talks to the FADER FastAPI backend (backend/app/...).
// Field names below match app/schemas/*.py exactly.
//
// Setup (run once from your Flutter project root):
//   flutter pub add http web_socket_channel
//
// Usage:
//   final api = ApiService();
//   final driver = await api.createDriver(name: 'Abhinav', vehicleId: 'MH-31-AB-1234');
//   final trip = await api.createTrip(driverId: driver.id, start: Coordinates(latitude: 21.1458, longitude: 79.0882), destination: Coordinates(latitude: 17.3850, longitude: 78.4867));
//   final socket = TripSocket.connect(trip.id);
//   socket.updates.listen((data) => print(data));
//   socket.sendTelemetry(speed: 62, ear: 0.24, fatigueLevel: 'HIGH', latitude: 21.2, longitude: 79.1);

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

// ---------------------------------------------------------------------------
// CONFIG — where your backend lives
// ---------------------------------------------------------------------------

class ApiConfig {
  // Override at build/run time without editing source:
  // flutter run -d chrome -t lib/second_main.dart \
  //   --dart-define=FADER_API_URL=http://127.0.0.1:8000
  // For a deployed backend use its HTTPS URL. FADER_WS_URL is optional; when
  // omitted it is derived automatically from FADER_API_URL.
  static const String _configuredHttp = String.fromEnvironment('FADER_API_URL');
  static const String _configuredWs = String.fromEnvironment('FADER_WS_URL');

  static String get baseUrl {
    if (_configuredHttp.isNotEmpty) return _configuredHttp.replaceAll(RegExp(r'/$'), '');
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String get wsBaseUrl {
    if (_configuredWs.isNotEmpty) return _configuredWs.replaceAll(RegExp(r'/$'), '');
    final httpBase = baseUrl;
    if (httpBase.startsWith('https://')) return 'wss://${httpBase.substring(8)}';
    if (httpBase.startsWith('http://')) return 'ws://${httpBase.substring(7)}';
    return httpBase;
  }

  /// Matches settings.API_V1_STR in app/core/config.py
  static const String apiPrefix = '/api/v1';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// MODELS — mirror app/schemas/*.py field-for-field
// ---------------------------------------------------------------------------

class Coordinates {
  final double latitude;
  final double longitude;
  const Coordinates({required this.latitude, required this.longitude});
  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude};
}

class Driver {
  final int id;
  final String name;
  final String? phone;
  final String vehicleId;
  final DateTime? createdAt;

  Driver({required this.id, required this.name, this.phone, required this.vehicleId, this.createdAt});

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        vehicleId: j['vehicle_id'] as String,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      );
}

class Trip {
  final int id;
  final int driverId;
  final String status;
  final double startLat, startLng, destLat, destLng;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Trip({
    required this.id,
    required this.driverId,
    required this.status,
    required this.startLat,
    required this.startLng,
    required this.destLat,
    required this.destLng,
    this.startedAt,
    this.endedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as int,
        driverId: j['driver_id'] as int,
        status: j['status'] as String,
        startLat: (j['start_lat'] as num).toDouble(),
        startLng: (j['start_lng'] as num).toDouble(),
        destLat: (j['dest_lat'] as num).toDouble(),
        destLng: (j['dest_lng'] as num).toDouble(),
        startedAt: j['started_at'] != null ? DateTime.tryParse(j['started_at']) : null,
        endedAt: j['ended_at'] != null ? DateTime.tryParse(j['ended_at']) : null,
      );
}

class RouteResult {
  final double distanceKm;
  final double durationMinutes;
  final List<List<double>> coordinates; // [lng, lat] pairs, GeoJSON order
  final String source; // "mapbox" or "fallback_simulated"

  RouteResult({required this.distanceKm, required this.durationMinutes, required this.coordinates, required this.source});

  factory RouteResult.fromJson(Map<String, dynamic> j) => RouteResult(
        distanceKm: (j['distance_km'] as num).toDouble(),
        durationMinutes: (j['duration_minutes'] as num).toDouble(),
        coordinates: (j['geometry']['coordinates'] as List)
            .map<List<double>>((p) => (p as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
        source: j['source'] as String,
      );
}

class WeatherResult {
  final double temperature, humidity, windSpeed, rainIntensity;
  final String condition, source;

  WeatherResult({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.rainIntensity,
    required this.condition,
    required this.source,
  });

  factory WeatherResult.fromJson(Map<String, dynamic> j) => WeatherResult(
        temperature: (j['temperature'] as num).toDouble(),
        humidity: (j['humidity'] as num).toDouble(),
        windSpeed: (j['wind_speed'] as num).toDouble(),
        rainIntensity: (j['rain_intensity'] as num).toDouble(),
        condition: j['condition'] as String,
        source: j['source'] as String,
      );
}

class FatigueEventResult {
  final int id, tripId;
  final String eventType, severity;
  final double? ear;
  final int? blinkDurationMs;
  final String? headPose;
  final double? latitude, longitude;
  final DateTime timestamp;

  FatigueEventResult({
    required this.id,
    required this.tripId,
    required this.eventType,
    required this.severity,
    this.ear,
    this.blinkDurationMs,
    this.headPose,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  factory FatigueEventResult.fromJson(Map<String, dynamic> j) => FatigueEventResult(
        id: j['id'] as int,
        tripId: j['trip_id'] as int,
        eventType: j['event_type'] as String,
        severity: j['severity'] as String,
        ear: j['ear'] != null ? (j['ear'] as num).toDouble() : null,
        blinkDurationMs: j['blink_duration_ms'] as int?,
        headPose: j['head_pose'] as String?,
        latitude: j['latitude'] != null ? (j['latitude'] as num).toDouble() : null,
        longitude: j['longitude'] != null ? (j['longitude'] as num).toDouble() : null,
        timestamp: DateTime.parse(j['timestamp']),
      );
}

class FatigueSummary {
  final int tripId, totalEvents, criticalEvents, highEvents;
  final List<FatigueEventResult> events;

  FatigueSummary({
    required this.tripId,
    required this.totalEvents,
    required this.criticalEvents,
    required this.highEvents,
    required this.events,
  });

  factory FatigueSummary.fromJson(Map<String, dynamic> j) => FatigueSummary(
        tripId: j['trip_id'] as int,
        totalEvents: j['total_events'] as int,
        criticalEvents: j['critical_events'] as int,
        highEvents: j['high_events'] as int,
        events: (j['events'] as List)
            .map((event) => FatigueEventResult.fromJson(event as Map<String, dynamic>))
            .toList(),
      );
}

class TelemetryResult {
  final int id, tripId;
  final double latitude, longitude, speed;
  final double? ear;
  final String fatigueLevel;
  final DateTime timestamp;

  TelemetryResult({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    this.ear,
    required this.fatigueLevel,
    required this.timestamp,
  });

  factory TelemetryResult.fromJson(Map<String, dynamic> j) => TelemetryResult(
        id: j['id'] as int,
        tripId: j['trip_id'] as int,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        speed: (j['speed'] as num).toDouble(),
        ear: j['ear'] != null ? (j['ear'] as num).toDouble() : null,
        fatigueLevel: j['fatigue_level'] as String,
        timestamp: DateTime.parse(j['timestamp']),
      );
}

class RiskFactors {
  final double fatigueFactor, durationFactor, weatherFactor, circadianFactor;
  RiskFactors({required this.fatigueFactor, required this.durationFactor, required this.weatherFactor, required this.circadianFactor});

  factory RiskFactors.fromJson(Map<String, dynamic> j) => RiskFactors(
        fatigueFactor: (j['fatigue_factor'] as num).toDouble(),
        durationFactor: (j['duration_factor'] as num).toDouble(),
        weatherFactor: (j['weather_factor'] as num).toDouble(),
        circadianFactor: (j['circadian_factor'] as num).toDouble(),
      );
}

class RiskResult {
  final int score; // 0-100
  final String level; // LOW, MODERATE, HIGH, CRITICAL
  final RiskFactors factors;

  RiskResult({required this.score, required this.level, required this.factors});

  factory RiskResult.fromJson(Map<String, dynamic> j) => RiskResult(
        score: j['score'] as int,
        level: j['level'] as String,
        factors: RiskFactors.fromJson(j['factors'] as Map<String, dynamic>),
      );
}

class Co2Result {
  final int tripId, estimatedCo2Ppm;
  final String airQualityLevel; // OPTIMAL, MODERATE, ELEVATED, HAZARDOUS
  final bool breakRecommended;
  final String actionPrompt;

  Co2Result({
    required this.tripId,
    required this.estimatedCo2Ppm,
    required this.airQualityLevel,
    required this.breakRecommended,
    required this.actionPrompt,
  });

  factory Co2Result.fromJson(Map<String, dynamic> j) => Co2Result(
        tripId: j['trip_id'] as int,
        estimatedCo2Ppm: j['estimated_co2_ppm'] as int,
        airQualityLevel: j['air_quality_level'] as String,
        breakRecommended: j['break_recommended'] as bool,
        actionPrompt: j['action_prompt'] as String,
      );
}

class TriviaResult {
  final String location, factOrQuestion, category, source;
  TriviaResult({required this.location, required this.factOrQuestion, required this.category, required this.source});

  factory TriviaResult.fromJson(Map<String, dynamic> j) => TriviaResult(
        location: j['location'] as String,
        factOrQuestion: j['fact_or_question'] as String,
        category: j['category'] as String,
        source: j['source'] as String,
      );
}

// ---------------------------------------------------------------------------
// SERVICE — one method per backend route
// ---------------------------------------------------------------------------

class ApiService {
  final String baseUrl;
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Uri _u(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('$baseUrl${ApiConfig.apiPrefix}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
      );

  static const _headers = {'Content-Type': 'application/json'};

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = res.body;
    try {
      final parsed = jsonDecode(res.body);
      message = parsed['detail']?.toString() ?? res.body;
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }

  // --- Drivers ---------------------------------------------------------

  Future<Driver> createDriver({required String name, String? phone, required String vehicleId}) async {
    final res = await http.post(_u('/drivers'),
        headers: _headers, body: jsonEncode({'name': name, 'phone': phone, 'vehicle_id': vehicleId}));
    return Driver.fromJson(_decode(res));
  }

  Future<Driver> getDriver(int driverId) async {
    final res = await http.get(_u('/drivers/$driverId'));
    return Driver.fromJson(_decode(res));
  }

  Future<Driver> updateDriver(
    int driverId, {
    String? name,
    String? phone,
    String? vehicleId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (vehicleId != null) body['vehicle_id'] = vehicleId;
    final res = await http.put(_u('/drivers/$driverId'), headers: _headers, body: jsonEncode(body));
    return Driver.fromJson(_decode(res));
  }

  // --- Trips -------------------------------------------------------------

  Future<Trip> createTrip({required int driverId, required Coordinates start, required Coordinates destination}) async {
    final res = await http.post(_u('/trips'),
        headers: _headers,
        body: jsonEncode({'driver_id': driverId, 'start': start.toJson(), 'destination': destination.toJson()}));
    return Trip.fromJson(_decode(res));
  }

  Future<Trip> getTrip(int tripId) async {
    final res = await http.get(_u('/trips/$tripId'));
    return Trip.fromJson(_decode(res));
  }

  Future<Trip> endTrip(int tripId) async {
    final res = await http.post(_u('/trips/$tripId/end'));
    return Trip.fromJson(_decode(res));
  }

  Future<List<Trip>> getDriverTrips(int driverId) async {
    final res = await http.get(_u('/trips/driver/$driverId'));
    return (_decode(res) as List).map((j) => Trip.fromJson(j)).toList();
  }

  // --- Routing (Mapbox, with automatic backend fallback) ------------------

  Future<RouteResult> calculateRoute({
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final res = await http.post(_u('/routes/calculate'),
        headers: _headers,
        body: jsonEncode({
          'start_lat': startLat,
          'start_lng': startLng,
          'destination_lat': destinationLat,
          'destination_lng': destinationLng,
        }));
    return RouteResult.fromJson(_decode(res));
  }

  // --- Weather (Tomorrow.io, with automatic backend fallback) -------------

  Future<WeatherResult> getWeather({required double latitude, required double longitude}) async {
    final res = await http.get(_u('/weather', {'latitude': latitude, 'longitude': longitude}));
    return WeatherResult.fromJson(_decode(res));
  }

  // --- Fatigue events -------------------------------------------------

  Future<FatigueEventResult> recordFatigueEvent({
    required int tripId,
    required String eventType, // MICROSLEEP, YAWN, DISTRACTION, HEAD_NOD
    required String severity, // LOW, MEDIUM, HIGH, CRITICAL
    double? ear,
    int? blinkDurationMs,
    String? headPose, // FORWARD, LEFT, RIGHT, DOWN, UP
    double? latitude,
    double? longitude,
  }) async {
    final res = await http.post(_u('/fatigue/events'),
        headers: _headers,
        body: jsonEncode({
          'trip_id': tripId,
          'event_type': eventType,
          'severity': severity,
          'ear': ear,
          'blink_duration_ms': blinkDurationMs,
          'head_pose': headPose,
          'latitude': latitude,
          'longitude': longitude,
        }));
    return FatigueEventResult.fromJson(_decode(res));
  }

  Future<FatigueSummary> getFatigueSummary(int tripId) async {
    final res = await http.get(_u('/fatigue/trips/$tripId'));
    return FatigueSummary.fromJson(_decode(res));
  }

  // --- Telemetry -----------------------------------------------------

  Future<TelemetryResult> recordTelemetry({
    required int tripId,
    required double latitude,
    required double longitude,
    required double speed,
    double? ear,
    String fatigueLevel = 'LOW',
  }) async {
    final res = await http.post(_u('/telemetry'),
        headers: _headers,
        body: jsonEncode({
          'trip_id': tripId,
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
          'ear': ear,
          'fatigue_level': fatigueLevel,
        }));
    return TelemetryResult.fromJson(_decode(res));
  }

  Future<List<TelemetryResult>> getTripTelemetry(int tripId, {int limit = 50}) async {
    final res = await http.get(_u('/telemetry/trips/$tripId', {'limit': limit}));
    return (_decode(res) as List).map((j) => TelemetryResult.fromJson(j)).toList();
  }

  // --- Risk engine -----------------------------------------------------

  Future<RiskResult> calculateRisk({
    required int tripId,
    double currentEar = 0.28,
    int recentFatigueEvents = 0,
    double tripDurationMinutes = 0.0,
    String weatherCondition = 'Clear',
    double rainIntensity = 0.0,
  }) async {
    final res = await http.post(_u('/risk/calculate'),
        headers: _headers,
        body: jsonEncode({
          'trip_id': tripId,
          'current_ear': currentEar,
          'recent_fatigue_events': recentFatigueEvents,
          'trip_duration_minutes': tripDurationMinutes,
          'weather_condition': weatherCondition,
          'rain_intensity': rainIntensity,
        }));
    return RiskResult.fromJson(_decode(res));
  }

  // --- CO2 forecasting -----------------------------------------------------

  Future<Co2Result> predictCo2({
    required int tripId,
    required double durationMinutes,
    double ventilationFactor = 1.0,
  }) async {
    final res = await http.post(_u('/co2/predict'),
        headers: _headers,
        body: jsonEncode({
          'trip_id': tripId,
          'duration_minutes': durationMinutes,
          'ventilation_factor': ventilationFactor,
        }));
    return Co2Result.fromJson(_decode(res));
  }

  // --- Driver engagement (location trivia) --------------------------------

  Future<TriviaResult> getEngagementTrivia({String? location}) async {
    final res = await http.get(_u('/engagement/trivia', location != null ? {'location': location} : null));
    return TriviaResult.fromJson(_decode(res));
  }
}

// ---------------------------------------------------------------------------
// REAL-TIME — wraps the /ws/trips/{trip_id} WebSocket from app/websocket/manager.py
// ---------------------------------------------------------------------------

class TripSocket {
  final WebSocketChannel _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _disposed = false;

  TripSocket._(this._channel) {
    _channel.stream.listen(
      (raw) {
        if (_disposed || _controller.isClosed) return;
        try {
          _controller.add(jsonDecode(raw as String) as Map<String, dynamic>);
        } catch (_) {
          // Ignore malformed frames; valid backend frames are JSON objects.
        }
      },
      onError: (e) {
        if (!_disposed && !_controller.isClosed) _controller.addError(e);
      },
      onDone: () {
        if (!_controller.isClosed) _controller.close();
      },
    );
  }

  /// Opens a connection to ws://<host>/api/v1/ws/trips/{tripId}
  factory TripSocket.connect(int tripId, {String? baseUrl}) {
    final base = baseUrl ?? ApiConfig.wsBaseUrl;
    final uri = Uri.parse('$base${ApiConfig.apiPrefix}/ws/trips/$tripId');
    return TripSocket._(WebSocketChannel.connect(uri));
  }

  /// Stream of decoded messages from the server — each is a Map like:
  /// { "type": "trip_update", "trip_id": ..., "location": {...}, "telemetry": {...}, "fatigue": {...} }
  Stream<Map<String, dynamic>> get updates => _controller.stream;

  /// Sends one telemetry frame, matching what app/api/v1/realtime.py expects.
  void sendTelemetry({
    required double speed,
    required double ear,
    required String fatigueLevel,
    required double latitude,
    required double longitude,
  }) {
    _channel.sink.add(jsonEncode({
      'type': 'telemetry',
      'speed': speed,
      'ear': ear,
      'fatigue_level': fatigueLevel,
      'latitude': latitude,
      'longitude': longitude,
    }));
  }

  void ping() => _channel.sink.add(jsonEncode({'type': 'ping'}));

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _channel.sink.close();
    if (!_controller.isClosed) _controller.close();
  }
}
