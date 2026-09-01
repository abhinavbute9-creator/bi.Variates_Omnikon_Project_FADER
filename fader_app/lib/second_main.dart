import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'services/api_service.dart';

void main() => runApp(const FaderApp());

const Color faderCyan = Color(0xFF56D4DA);
const Color faderDeepBlue = Color(0xFF0754AA);
const Color eyeCyan = Color(0xFF159BD4);
const Color alertRed = Color(0xFFFF5A58);
const Color ink = Color(0xFF10253D);

const LinearGradient faderGradient = LinearGradient(
  colors: [faderCyan, faderDeepBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Coordinate seeds for the five supported demo cities. The backend performs
// route calculation between these points; arbitrary-text geocoding is future work.
const Map<String, LatLng> cityCoordinates = {
  'nagpur': LatLng(21.1458, 79.0882),
  'pune': LatLng(18.5204, 73.8567),
  'mumbai': LatLng(19.0760, 72.8777),
  'hyderabad': LatLng(17.3850, 78.4867),
  'delhi': LatLng(28.6139, 77.2090),
};

class FaderApp extends StatelessWidget {
  const FaderApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FADER',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: faderDeepBlue),
          // Uses a standard monospace face in a fresh Flutter project while
          // remaining compatible with a future bundled Roboto Mono font.
          fontFamily: 'monospace',
          appBarTheme: const AppBarTheme(
            backgroundColor: faderDeepBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF4F8FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: eyeCyan, width: 2),
            ),
          ),
        ),
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: .92,
    upperBound: 1.08,
  );
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    // A blink begins every three seconds and closes then opens the eyelids.
    _blinkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _blink.forward(from: 0).then((_) => _blink.reverse());
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _pulse.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _openConfiguration() {
    _pulse.forward(from: .92).then((_) => _pulse.reverse());
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConfigurationScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: faderGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _Logo(
                    pulse: _pulse,
                    blink: _blink,
                    onPupilTap: _openConfiguration,
                  ),
                  const Spacer(),
                  const Text(
                    'TAP THE PUPIL TO BEGIN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Logo extends StatelessWidget {
  const _Logo({required this.pulse, required this.blink, required this.onPupilTap});

  final Animation<double> pulse;
  final Animation<double> blink;
  final VoidCallback onPupilTap;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            width: 280,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: blink,
                  builder: (_, __) => CustomPaint(
                    size: const Size(280, 150),
                    painter: _EyePainter(blink: blink.value),
                  ),
                ),
                // Kept above the eyelid painter so it stays visible and
                // tappable during the closing phase of the animation.
                ScaleTransition(
                  scale: pulse,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPupilTap,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'FADER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 72,
              height: .92,
              fontWeight: FontWeight.w900,
              letterSpacing: -3,
            ),
          ),
        ],
      );
}

class _EyePainter extends CustomPainter {
  const _EyePainter({required this.blink});

  final double blink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final topControl = -8 + (center.dy - 4) * blink;
    final bottomControl = size.height + 8 - (center.dy - 4) * blink;
    final eyePath = Path()
      ..moveTo(12, center.dy)
      ..quadraticBezierTo(center.dx, topControl, size.width - 12, center.dy)
      ..quadraticBezierTo(center.dx, bottomControl, 12, center.dy)
      ..close();
    final fill = Paint()..color = const Color(0xFF177CB5);
    canvas.drawPath(eyePath, fill);
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = const Color(0xFF075D99)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 100, height: 100),
      Paint()
        ..color = const Color(0xFF0B6EA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final dashPaint = Paint()
      ..color = alertRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    final dashed = Path()
      ..moveTo(26, center.dy)
      ..quadraticBezierTo(center.dx, 10 + (center.dy - 10) * blink, size.width - 26, center.dy)
      ..quadraticBezierTo(center.dx, size.height - 10 - (center.dy - 10) * blink, 26, center.dy);
    for (final metric in dashed.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 18) {
        canvas.drawPath(metric.extractPath(distance, distance + 10), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EyePainter oldDelegate) => oldDelegate.blink != blink;
}

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _source = TextEditingController(text: 'Nagpur');
  final _destination = TextEditingController(text: 'Hyderabad');
  final ApiService _api = ApiService();
  Timer? _clock;
  DateTime _now = DateTime.now();
  int _drivers = 1;
  bool _hadMeal = true;
  bool _loading = false;
  String? _error;

  String _cityKey(String value) => value.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _source.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final sourceName = _source.text.trim();
    final destinationName = _destination.text.trim();
    final start = cityCoordinates[_cityKey(sourceName)];
    final destination = cityCoordinates[_cityKey(destinationName)];

    if (start == null || destination == null) {
      setState(() => _error = 'Supported demo cities: Nagpur, Pune, Mumbai, Hyderabad, and Delhi.');
      return;
    }
    if (sourceName.toLowerCase() == destinationName.toLowerCase()) {
      setState(() => _error = 'Choose two different cities for the journey.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final driver = await _api.createDriver(
        name: 'FADER Demo Driver',
        vehicleId: 'FADER-${DateTime.now().millisecondsSinceEpoch}',
      );
      final trip = await _api.createTrip(
        driverId: driver.id,
        start: Coordinates(latitude: start.latitude, longitude: start.longitude),
        destination: Coordinates(latitude: destination.latitude, longitude: destination.longitude),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            source: sourceName,
            destination: destinationName,
            start: start,
            destinationPoint: destination,
            driverId: driver.id,
            tripId: trip.id,
            backupDrivers: _drivers,
            hadMeal: _hadMeal,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Backend connection failed: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pre-trip check')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
          children: [
            const Text('READY THE ROUTE', style: _EyebrowStyle()),
            const SizedBox(height: 8),
            const Text(
              'A clear plan keeps every driver alert.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink),
            ),
            const SizedBox(height: 10),
            Text(
              'This screen now creates a real backend driver and trip before opening the dashboard.',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 24),
            _FieldLabel(label: 'SOURCE', child: TextField(controller: _source)),
            const SizedBox(height: 16),
            _FieldLabel(label: 'DESTINATION', child: TextField(controller: _destination)),
            const SizedBox(height: 22),
            _FieldLabel(
              label: 'CORRESPONDENTS AVAILABLE',
              child: Row(
                children: [
                  IconButton(
                    onPressed: _loading ? null : () => setState(() => _drivers = math.max(0, _drivers - 1)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_drivers', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: _loading ? null : () => setState(() => _drivers++),
                    icon: const Icon(Icons.add_circle_outline, color: faderDeepBlue),
                  ),
                  const Expanded(child: Text(' drivers can swap', style: TextStyle(color: Colors.black54))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FieldLabel(
              label: 'NOURISHMENT CHECK',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: eyeCyan,
                title: const Text('Meal in the last 2 hours?'),
                value: _hadMeal,
                onChanged: _loading ? null : (value) => setState(() => _hadMeal = value),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFEAF8FA),
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.schedule, color: faderDeepBlue),
                title: const Text('CURRENT SYSTEM TIME'),
                subtitle: Text(
                  _formatTime(_now),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alertRed.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: alertRed, fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _loading ? null : _initialize,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.route),
              label: Text(_loading ? 'CREATING LIVE TRIP...' : 'INITIALIZE ROUTING'),
              style: FilledButton.styleFrom(
                backgroundColor: faderDeepBlue,
                minimumSize: const Size.fromHeight(56),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
}

String _formatMinutes(double minutes) {
  final total = math.max(0, minutes.round());
  final hours = total ~/ 60;
  final mins = total % 60;
  return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.source,
    required this.destination,
    required this.start,
    required this.destinationPoint,
    required this.driverId,
    required this.tripId,
    required this.backupDrivers,
    required this.hadMeal,
  });

  final String source;
  final String destination;
  final LatLng start;
  final LatLng destinationPoint;
  final int driverId;
  final int tripId;
  final int backupDrivers;
  final bool hadMeal;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  final List<String> _fallbackPrompts = const [
    'What color was the last passing truck?',
    'Name three road signs you saw recently.',
    'What is your next planned rest stop?',
  ];

  RouteResult? _route;
  WeatherResult? _weather;
  RiskResult? _risk;
  Co2Result? _co2;
  TripSocket? _socket;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  bool _loading = true;
  bool _simulating = false;
  bool _ending = false;
  String? _error;
  String _socketStatus = 'Connecting';
  double _brightness = .58;
  int _strikes = 0;
  double _demoMinutes = 0;
  double _speed = 62;
  double _currentEar = .28;
  String _fatigueLevel = 'LOW';
  int _telemetryFrames = 0;
  int _fallbackPromptIndex = 0;

  List<LatLng> get _routePoints {
    final route = _route;
    if (route == null || route.coordinates.isEmpty) {
      return [widget.start, widget.destinationPoint];
    }
    return route.coordinates.map((pair) => LatLng(pair[1], pair[0])).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadJourney();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _loadJourney() async {
    try {
      final results = await Future.wait<Object>([
        _api.calculateRoute(
          startLat: widget.start.latitude,
          startLng: widget.start.longitude,
          destinationLat: widget.destinationPoint.latitude,
          destinationLng: widget.destinationPoint.longitude,
        ),
        _api.getWeather(latitude: widget.start.latitude, longitude: widget.start.longitude),
      ]);
      _route = results[0] as RouteResult;
      _weather = results[1] as WeatherResult;
      await _refreshModels();
      _connectSocket();
    } catch (error) {
      _error = 'Could not load live journey data: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshModels({double? ear}) async {
    final weather = _weather;
    final currentEar = ear ?? _currentEar;
    final results = await Future.wait<Object>([
      _api.calculateRisk(
        tripId: widget.tripId,
        currentEar: currentEar,
        recentFatigueEvents: _strikes,
        tripDurationMinutes: _demoMinutes,
        weatherCondition: weather?.condition ?? 'Clear',
        rainIntensity: weather?.rainIntensity ?? 0,
      ),
      _api.predictCo2(
        tripId: widget.tripId,
        durationMinutes: _demoMinutes,
        ventilationFactor: 1,
      ),
    ]);
    _risk = results[0] as RiskResult;
    _co2 = results[1] as Co2Result;
    _fatigueLevel = _risk!.level;
    _brightness = (0.55 + (_risk!.score / 100) * 0.45).clamp(0.55, 1.0).toDouble();
    if (mounted) setState(() {});
  }

  void _connectSocket() {
    try {
      _socket = TripSocket.connect(widget.tripId);
      _socketSubscription = _socket!.updates.listen(
        (message) {
          if (!mounted) return;
          if (message['type'] == 'pong') {
            setState(() => _socketStatus = 'Connected');
            return;
          }
          if (message['type'] == 'trip_update') {
            final telemetry = message['telemetry'] as Map<String, dynamic>?;
            final fatigue = message['fatigue'] as Map<String, dynamic>?;
            setState(() {
              _socketStatus = 'Live';
              _speed = (telemetry?['speed'] as num?)?.toDouble() ?? _speed;
              _currentEar = (telemetry?['ear'] as num?)?.toDouble() ?? _currentEar;
              _fatigueLevel = fatigue?['level']?.toString() ?? _fatigueLevel;
            });
          }
        },
        onError: (_) {
          if (mounted) setState(() => _socketStatus = 'Unavailable');
        },
        onDone: () {
          if (mounted) setState(() => _socketStatus = 'Closed');
        },
      );
      _socket!.ping();
    } catch (_) {
      if (mounted) setState(() => _socketStatus = 'Unavailable');
    }
  }

  Future<void> _sendTelemetry({double? ear, String? fatigueLevel}) async {
    final sendEar = ear ?? _currentEar;
    final sendFatigue = fatigueLevel ?? _fatigueLevel;
    final speed = 58 + (_telemetryFrames % 7).toDouble();
    try {
      _socket?.sendTelemetry(
        speed: speed,
        ear: sendEar,
        fatigueLevel: sendFatigue,
        latitude: widget.start.latitude,
        longitude: widget.start.longitude,
      );
      await _api.recordTelemetry(
        tripId: widget.tripId,
        latitude: widget.start.latitude,
        longitude: widget.start.longitude,
        speed: speed,
        ear: sendEar,
        fatigueLevel: sendFatigue,
      );
      if (mounted) {
        setState(() {
          _telemetryFrames++;
          _speed = speed;
          _currentEar = sendEar;
        });
      }
    } catch (error) {
      _showSnack('Telemetry failed: $error');
    }
  }

  Future<void> _simulateFatigue() async {
    if (_simulating) return;
    setState(() => _simulating = true);
    try {
      final event = await _api.recordFatigueEvent(
        tripId: widget.tripId,
        eventType: 'MICROSLEEP',
        severity: 'HIGH',
        ear: .17,
        blinkDurationMs: 1100,
        headPose: 'DOWN',
        latitude: widget.start.latitude,
        longitude: widget.start.longitude,
      );
      _strikes = math.min(3, _strikes + 1);
      _demoMinutes = math.min(240.0, _demoMinutes + 60.0);
      _currentEar = .17;
      await _refreshModels(ear: .17);
      await _sendTelemetry(ear: .17, fatigueLevel: _risk?.level ?? 'HIGH');
      _showSnack('Simulated event #${event.id}: risk ${_risk?.score ?? 0}/100 ${_risk?.level ?? ''}.');
    } catch (error) {
      _showSnack('Fatigue simulation failed: $error');
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  Future<void> _showEngagement() async {
    String prompt;
    String source;
    try {
      final trivia = await _api.getEngagementTrivia(location: widget.source);
      prompt = trivia.factOrQuestion;
      source = '${trivia.location} · ${trivia.source}';
    } catch (_) {
      _fallbackPromptIndex = (_fallbackPromptIndex + 1) % _fallbackPrompts.length;
      prompt = _fallbackPrompts[_fallbackPromptIndex];
      source = 'Local UI fallback';
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ENGAGEMENT CHECK', style: _EyebrowStyle()),
            const SizedBox(height: 10),
            Text(prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 8),
            Text(source, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('I AM READY')),
          ],
        ),
      ),
    );
  }

  Future<void> _endTrip() async {
    if (_ending) return;
    setState(() => _ending = true);
    try {
      final trip = await _api.endTrip(widget.tripId);
      _socketSubscription?.cancel();
      _socket?.dispose();
      if (!mounted) return;
      _showSnack('Trip #${trip.id} ended and persisted.');
      Navigator.of(context).pop();
    } catch (error) {
      _showSnack('Could not end trip: $error');
      if (mounted) setState(() => _ending = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMap() => SizedBox(
        height: MediaQuery.sizeOf(context).height * .46,
        child: FlutterMap(
          options: MapOptions(initialCenter: widget.start, initialZoom: 5.5),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fader.prototype',
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: _routePoints, color: alertRed, strokeWidth: 5),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.start,
                  width: 120,
                  height: 58,
                  child: _MapMarker(label: widget.source),
                ),
                Marker(
                  point: widget.destinationPoint,
                  width: 120,
                  height: 58,
                  child: _MapMarker(label: widget.destination),
                ),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final weather = _weather;
    final risk = _risk;
    final co2 = _co2;
    final warning = risk == null || risk.level == 'LOW'
        ? 'No elevated risk signal in the current backend assessment.'
        : '${risk.level} risk detected. Prepare a safe intervention or driver swap.';

    return Scaffold(
      appBar: AppBar(
        title: Text('Active journey · Trip #${widget.tripId}'),
        actions: [
          IconButton(
            onPressed: _ending ? null : _endTrip,
            tooltip: 'End trip',
            icon: _ending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadJourney,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  _buildMap(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ROUTE IN PROGRESS', style: _EyebrowStyle()),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: eyeCyan.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _socketStatus.toUpperCase(),
                                style: const TextStyle(color: faderDeepBlue, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.source}  →  ${widget.destination}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
                        ),
                        Text(
                          'Backend trip #${widget.tripId} · driver #${widget.driverId} · ${widget.backupDrivers} backup driver(s) · meal: ${widget.hadMeal ? 'yes' : 'no'}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: alertRed, fontWeight: FontWeight.w700)),
                        ],
                        const SizedBox(height: 18),
                        Card(
                          elevation: 0,
                          color: const Color(0xFFF2F8FC),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('BACKEND ROUTE', style: _EyebrowStyle()),
                                    Text(
                                      route?.source ?? 'loading',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: faderDeepBlue),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  route == null
                                      ? 'Route unavailable'
                                      : '${route.distanceKm.toStringAsFixed(1)} km · ${_formatMinutes(route.durationMinutes)} expected drive time',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Demo fatigue scenario elapsed profile: ${_demoMinutes.round()} min. This only advances when the explicit simulation control is used.',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.access_time_filled,
                                label: 'ROUTE DURATION',
                                value: route == null ? '—' : _formatMinutes(route.durationMinutes),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Metric(
                                icon: Icons.cloud_queue,
                                label: 'WEATHER',
                                value: weather == null ? '—' : '${weather.temperature.toStringAsFixed(1)}°C  ${weather.condition}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('LIVE BACKEND ANALYSIS', style: _EyebrowStyle()),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.shield_outlined,
                                label: 'RISK SCORE',
                                value: risk == null ? '—' : '${risk.score}/100 ${risk.level}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Metric(
                                icon: Icons.air,
                                label: 'CABIN CO₂ MODEL',
                                value: co2 == null ? '—' : '${co2.estimatedCo2Ppm} ppm ${co2.airQualityLevel}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (risk != null)
                          Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('RISK FACTOR BREAKDOWN', style: _EyebrowStyle()),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _FactorChip(label: 'Fatigue', value: risk.factors.fatigueFactor),
                                      _FactorChip(label: 'Duration', value: risk.factors.durationFactor),
                                      _FactorChip(label: 'Weather', value: risk.factors.weatherFactor),
                                      _FactorChip(label: 'Circadian', value: risk.factors.circadianFactor),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (co2 != null) ...[
                          const SizedBox(height: 10),
                          Card(
                            elevation: 0,
                            child: ListTile(
                              leading: const Icon(Icons.air, color: eyeCyan),
                              title: Text('${co2.airQualityLevel} · ${co2.estimatedCo2Ppm} ppm', style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('${co2.actionPrompt}\nPrototype estimate — not a physical CO₂ sensor.'),
                              isThreeLine: true,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text('DRIVER SAFETY SYSTEMS', style: _EyebrowStyle()),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.science_outlined, color: eyeCyan),
                                  title: Text('Sensor simulation ready', style: TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text('Live camera / MediaPipe EAR inference is the next integration milestone.'),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (risk?.level == 'LOW' ? eyeCyan : alertRed).withAlpha(18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        risk?.level == 'LOW' ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                        color: risk?.level == 'LOW' ? faderDeepBlue : alertRed,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          warning,
                                          style: TextStyle(
                                            color: risk?.level == 'LOW' ? faderDeepBlue : alertRed,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.brightness_6, color: faderDeepBlue),
                                    const SizedBox(width: 10),
                                    const Text('Risk-Based Brightness', style: TextStyle(fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Text('${(_brightness * 100).round()}%'),
                                  ],
                                ),
                                Slider(value: _brightness, activeColor: eyeCyan, onChanged: null),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          child: ListTile(
                            leading: const Icon(Icons.notifications_active, color: alertRed),
                            title: const Text('3-Strike intervention demo', style: TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('$_strikes of 3 simulated fatigue strikes used · EAR ${_currentEar.toStringAsFixed(2)}'),
                            trailing: FilledButton(
                              onPressed: _simulating ? null : _simulateFatigue,
                              style: FilledButton.styleFrom(backgroundColor: alertRed),
                              child: Text(_simulating ? 'WAIT' : 'SIMULATE'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          child: ListTile(
                            leading: const Icon(Icons.sensors, color: faderDeepBlue),
                            title: Text('Live telemetry · $_telemetryFrames persisted frame(s)', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${_speed.toStringAsFixed(0)} km/h · EAR ${_currentEar.toStringAsFixed(2)} · $_fatigueLevel · WebSocket $_socketStatus'),
                            trailing: IconButton(
                              tooltip: 'Send telemetry',
                              onPressed: _sendTelemetry,
                              icon: const Icon(Icons.send),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('DEMO POINTS OF INTEREST', style: _EyebrowStyle()),
                        const SizedBox(height: 8),
                        const _Poi(icon: Icons.local_cafe, name: 'Highway Bean Coffee', detail: 'Demo POI · 18 km · Coffee shop'),
                        const _Poi(icon: Icons.local_parking, name: 'Wardha Rest Area', detail: 'Demo POI · 31 km · Restrooms + parking'),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _showEngagement,
                          icon: const Icon(Icons.mic_none),
                          label: const Text('BACKEND ENGAGEMENT CHECK'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            color: faderDeepBlue,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.location_on, color: alertRed, size: 28),
        ],
      );
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$label ${value.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: faderDeepBlue),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
            ],
          ),
        ),
      );
}

class _Poi extends StatelessWidget {
  const _Poi({required this.icon, required this.name, required this.detail});
  final IconData icon;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF8FA),
          child: Icon(icon, color: faderDeepBlue),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(detail),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const _EyebrowStyle()),
          const SizedBox(height: 7),
          child,
        ],
      );
}

class _EyebrowStyle extends TextStyle {
  const _EyebrowStyle()
      : super(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: faderDeepBlue,
          letterSpacing: 1.3,
        );
}
