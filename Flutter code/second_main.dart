import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

// Coordinates are intentionally local mock data. A geocoder/routing service
// can replace this lookup when the FastAPI WebSocket session is connected.
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
  Timer? _clock;
  DateTime _now = DateTime.now();
  int _drivers = 1;
  bool _hadMeal = true;

  @override
  void initState() {
    super.initState();
    // Replace this local clock with the authoritative FastAPI/WebSocket time.
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

  void _initialize() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          source: _source.text.trim(),
          destination: _destination.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pre-trip check')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
          children: [
            const Text('READY THE ROUTE', style: _EyebrowStyle()),
            const SizedBox(height: 8),
            const Text('A clear plan keeps every driver alert.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 28),
            _FieldLabel(label: 'SOURCE', child: TextField(controller: _source)),
            const SizedBox(height: 16),
            _FieldLabel(label: 'DESTINATION', child: TextField(controller: _destination)),
            const SizedBox(height: 22),
            _FieldLabel(
              label: 'CORRESPONDENTS AVAILABLE',
              child: Row(children: [
                IconButton(onPressed: () => setState(() => _drivers = math.max(0, _drivers - 1)), icon: const Icon(Icons.remove_circle_outline)),
                Text('$_drivers', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                IconButton(onPressed: () => setState(() => _drivers++), icon: const Icon(Icons.add_circle_outline, color: faderDeepBlue)),
                const Expanded(child: Text(' drivers can swap', style: TextStyle(color: Colors.black54))),
              ]),
            ),
            const SizedBox(height: 18),
            _FieldLabel(
              label: 'NOURISHMENT CHECK',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: eyeCyan,
                title: const Text('Meal in the last 2 hours?'),
                value: _hadMeal,
                onChanged: (value) => setState(() => _hadMeal = value),
              ),
            ),
            const SizedBox(height: 12),
            Card(color: const Color(0xFFEAF8FA), elevation: 0, child: ListTile(leading: const Icon(Icons.schedule, color: faderDeepBlue), title: const Text('CURRENT SYSTEM TIME'), subtitle: Text(_formatTime(_now), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)))),
            const SizedBox(height: 30),
            FilledButton.icon(onPressed: _initialize, icon: const Icon(Icons.route), label: const Text('INITIALIZE ROUTING'), style: FilledButton.styleFrom(backgroundColor: faderDeepBlue, minimumSize: const Size.fromHeight(56), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.source, required this.destination});

  final String source;
  final String destination;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _brightness = .86;
  int _quizIndex = 0;
  final _quizzes = const ['What color was the last passing truck?', 'Name three road signs you saw recently.', 'What is your next planned rest stop?'];

  String _cityKey(String value) => value.trim().toLowerCase();

  List<LatLng> get _routePoints => [
        cityCoordinates[_cityKey(widget.source)],
        cityCoordinates[_cityKey(widget.destination)],
      ].whereType<LatLng>().toList();

  LatLng get _mapCenter => _routePoints.isNotEmpty ? _routePoints.first : const LatLng(20.5, 78.9);

  void _showQuiz() {
    // A FastAPI WebSocket can push prompts and receive voice responses here.
    setState(() => _quizIndex = (_quizIndex + 1) % _quizzes.length);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ENGAGEMENT CHECK', style: _EyebrowStyle()),
          const SizedBox(height: 10),
          Text(_quizzes[_quizIndex], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('I AM READY')),
        ]),
      ),
    );
  }

  Widget _buildMap() => SizedBox(
        height: MediaQuery.sizeOf(context).height * .46,
        child: FlutterMap(
          options: MapOptions(initialCenter: _mapCenter, initialZoom: _routePoints.length > 1 ? 5.5 : 5),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fader.prototype',
            ),
            if (_routePoints.length > 1)
              PolylineLayer(polylines: [Polyline(points: _routePoints, color: alertRed, strokeWidth: 5)]),
            MarkerLayer(
              markers: _routePoints.map((point) => Marker(
                    point: point,
                    width: 116,
                    height: 58,
                    child: Column(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), color: faderDeepBlue, child: Text(point == _routePoints.first ? widget.source : widget.destination, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                      const Icon(Icons.location_on, color: alertRed, size: 28),
                    ]),
                  )).toList(),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Active journey'), actions: [IconButton(onPressed: () {}, tooltip: 'Notifications', icon: const Icon(Icons.notifications_none))]),
        body: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          _buildMap(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('ROUTE IN PROGRESS', style: _EyebrowStyle()), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: alertRed.withAlpha(25), borderRadius: BorderRadius.circular(20)), child: const Text('LIVE', style: TextStyle(color: alertRed, fontWeight: FontWeight.w800)))]),
              const SizedBox(height: 8),
              Text('${widget.source}  ->  ${widget.destination}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)),
              if (_routePoints.length < 2) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Map markers support Nagpur, Pune, Mumbai, Hyderabad, and Delhi.', style: TextStyle(color: Colors.black54, fontSize: 12))),
              const SizedBox(height: 18),
              Card(elevation: 0, color: const Color(0xFFF2F8FC), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TRAVEL ROUTE STATUS', style: _EyebrowStyle()), const Text('42%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: faderDeepBlue))]), const SizedBox(height: 14), LinearProgressIndicator(value: .42, minHeight: 10, borderRadius: BorderRadius.circular(8), color: eyeCyan, backgroundColor: Colors.white), const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Departed 06:40'), Text('ETA 14:20', style: TextStyle(fontWeight: FontWeight.w800, color: ink))])]))),
              const SizedBox(height: 12),
              Row(children: [const Expanded(child: _Metric(icon: Icons.access_time_filled, label: 'ETA', value: '2h 48m')), const SizedBox(width: 10), const Expanded(child: _Metric(icon: Icons.cloud_queue, label: 'WEATHER', value: '28C  Clear'))]),
              const SizedBox(height: 24),
              const Text('ROUTE ANALYSIS', style: _EyebrowStyle()),
              const SizedBox(height: 10),
              const _Timeline(),
              const SizedBox(height: 24),
              const Text('DRIVER SAFETY SYSTEMS', style: _EyebrowStyle()),
              const SizedBox(height: 10),
              Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.visibility, color: eyeCyan), title: Text('Camera Active', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Tracking Eye Aspect Ratio (EAR)')), Container(padding: const EdgeInsets.all(12), color: alertRed.withAlpha(18), child: const Row(children: [Icon(Icons.warning_amber_rounded, color: alertRed), SizedBox(width: 8), Expanded(child: Text('Fatigue signal detected. Prepare driver swap.', style: TextStyle(color: alertRed, fontWeight: FontWeight.w700)))])), const SizedBox(height: 12), Row(children: [const Icon(Icons.brightness_6, color: faderDeepBlue), const SizedBox(width: 10), const Text('Risk-Based Brightness', style: TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('${(_brightness * 100).round()}%')]), Slider(value: _brightness, activeColor: eyeCyan, onChanged: (value) => setState(() => _brightness = value)), const Align(alignment: Alignment.centerLeft, child: Text('Brightness rises to maximum inside high fatigue zones.', style: TextStyle(fontSize: 12, color: Colors.black54)))]))),
              const SizedBox(height: 10),
              const Card(elevation: 0, child: ListTile(leading: Icon(Icons.notifications_active, color: alertRed), title: Text('3-Strike buzzer system', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Active  -  0 of 3 strikes used'))),
              const SizedBox(height: 24),
              const Text('UPCOMING POINTS OF INTEREST', style: _EyebrowStyle()),
              const SizedBox(height: 8),
              const _Poi(icon: Icons.local_cafe, name: 'Highway Bean Coffee', detail: '18 km  -  Coffee shop'),
              const _Poi(icon: Icons.local_parking, name: 'Wardha Rest Area', detail: '31 km  -  Restrooms + parking'),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _showQuiz, icon: const Icon(Icons.mic_none), label: const Text('VOICE ENGAGEMENT CHECK')),
            ]),
          ),
        ],
      );
}

class _Timeline extends StatelessWidget {
  const _Timeline();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 100, child: Row(children: [Expanded(flex: 2, child: _Zone(label: 'LOW FATIGUE', color: eyeCyan, icon: Icons.check_circle)), Expanded(flex: 3, child: _Zone(label: 'HIGH FATIGUE', color: alertRed, icon: Icons.warning_rounded)), Expanded(child: _Zone(label: 'LOW', color: eyeCyan, icon: Icons.check_circle))]));
}

class _Zone extends StatelessWidget {
  const _Zone({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(right: 3), padding: const EdgeInsets.all(8), color: color.withAlpha(35), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))]));
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: faderDeepBlue), const SizedBox(height: 10), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: ink))])));
}

class _Poi extends StatelessWidget {
  const _Poi({required this.icon, required this.name, required this.detail});
  final IconData icon;
  final String name;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFFEAF8FA), child: Icon(icon, color: faderDeepBlue)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(detail));
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const _EyebrowStyle()), const SizedBox(height: 7), child]);
}

class _EyebrowStyle extends TextStyle {
  const _EyebrowStyle() : super(fontSize: 11, fontWeight: FontWeight.w900, color: faderDeepBlue, letterSpacing: 1.3);
}