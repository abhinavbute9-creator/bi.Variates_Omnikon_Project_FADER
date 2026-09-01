import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const FaderApp());
}

// Sampled from the supplied logo raster: left cyan, right deep blue, eye cyan,
// and the warm red used by the inner dashed line and risk states.
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

class FaderApp extends StatelessWidget {
  const FaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FADER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: faderDeepBlue),
        fontFamily: 'Arial',
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
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.92,
    upperBound: 1.08,
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openConfiguration() {
    _pulse.forward(from: 0.92).then((_) => _pulse.reverse());
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConfigurationScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: faderGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _Logo(pulse: _pulse, onPupilTap: _openConfiguration),
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
}

class _Logo extends StatelessWidget {
  const _Logo({required this.pulse, required this.onPupilTap});

  final Animation<double> pulse;
  final VoidCallback onPupilTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 280,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: const Size(280, 150), painter: _EyePainter()),
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
}

class _EyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eyePath = Path()
      ..moveTo(12, center.dy)
      ..quadraticBezierTo(center.dx, -8, size.width - 12, center.dy)
      ..quadraticBezierTo(center.dx, size.height + 8, 12, center.dy)
      ..close();
    canvas.drawPath(eyePath, Paint()..color = const Color(0xFF177CB5));
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
      ..quadraticBezierTo(center.dx, 10, size.width - 26, center.dy)
      ..quadraticBezierTo(center.dx, size.height - 10, 26, center.dy);
    for (final metric in dashed.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 18) {
        canvas.drawPath(metric.extractPath(distance, distance + 10), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _source = TextEditingController(text: 'Nagpur');
  final _destination = TextEditingController();
  Timer? _clock;
  DateTime _now = DateTime.now();
  int _drivers = 1;
  bool _hadMeal = true;

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

  void _initialize() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-trip check'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
        children: [
          const Text('READY THE ROUTE', style: _EyebrowStyle()),
          const SizedBox(height: 8),
          const Text('A clear plan keeps every driver alert.', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 28),
          _FieldLabel(label: 'SOURCE', child: TextField(controller: _source)),
          const SizedBox(height: 16),
          _FieldLabel(label: 'DESTINATION', child: TextField(controller: _destination, decoration: const InputDecoration(hintText: 'Where are you headed?'))),
          const SizedBox(height: 22),
          _FieldLabel(
            label: 'CORRESPONDENTS AVAILABLE',
            child: Row(children: [
              IconButton(onPressed: () => setState(() => _drivers = math.max(0, _drivers - 1)), icon: const Icon(Icons.remove_circle_outline)),
              Text('$_drivers', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => setState(() => _drivers++), icon: const Icon(Icons.add_circle_outline, color: faderDeepBlue)),
              const Text(' drivers can swap', style: TextStyle(color: Colors.black54)),
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
          Card(color: const Color(0xFFEAF8FA), elevation: 0, child: ListTile(leading: const Icon(Icons.schedule, color: faderDeepBlue), title: const Text('CURRENT SYSTEM TIME'), subtitle: Text(_formatTime(_now), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink)))),
          const SizedBox(height: 30),
          FilledButton.icon(onPressed: _initialize, icon: const Icon(Icons.route), label: const Text('INITIALIZE ROUTING'), style: FilledButton.styleFrom(backgroundColor: faderDeepBlue, minimumSize: const Size.fromHeight(56), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second ${time.hour >= 12 ? 'PM' : 'AM'}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _brightness = .86;
  int _quizIndex = 0;
  final _quizzes = const ['What color was the last passing truck?', 'Name three road signs you saw recently.', 'What is your next planned rest stop?'];

  void _showQuiz() {
    setState(() => _quizIndex = (_quizIndex + 1) % _quizzes.length);
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(24, 4, 24, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ENGAGEMENT CHECK', style: _EyebrowStyle()), const SizedBox(height: 10), Text(_quizzes[_quizIndex], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 18), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('I’M READY'))])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active journey'), actions: [IconButton(onPressed: () {}, tooltip: 'Notifications', icon: const Icon(Icons.notifications_none))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 28), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('ROUTE IN PROGRESS', style: _EyebrowStyle()), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: alertRed.withAlpha(25), borderRadius: BorderRadius.circular(20)), child: const Text('LIVE', style: TextStyle(color: alertRed, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 8),
        const Text('Nagpur  →  Hyderabad', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 18),
        Card(elevation: 0, color: const Color(0xFFF2F8FC), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TRAVEL ROUTE STATUS', style: _EyebrowStyle()), Text('42%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: faderDeepBlue))]), const SizedBox(height: 14), LinearProgressIndicator(value: .42, minHeight: 10, borderRadius: BorderRadius.circular(8), color: eyeCyan, backgroundColor: Colors.white), const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Departed 06:40'), Text('ETA 14:20', style: TextStyle(fontWeight: FontWeight.w800, color: ink))])]))),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _Metric(icon: Icons.access_time_filled, label: 'ETA', value: '2h 48m')), const SizedBox(width: 10), Expanded(child: _Metric(icon: Icons.cloud_queue, label: 'WEATHER', value: '28°C  Clear'))]),
        const SizedBox(height: 24),
        const Text('ROUTE ANALYSIS', style: _EyebrowStyle()),
        const SizedBox(height: 10),
        _Timeline(),
        const SizedBox(height: 24),
        const Text('DRIVER SAFETY SYSTEMS', style: _EyebrowStyle()),
        const SizedBox(height: 10),
        Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.visibility, color: eyeCyan), title: Text('Camera Active', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Tracking Eye Aspect Ratio (EAR)')), Container(padding: const EdgeInsets.all(12), color: alertRed.withAlpha(18), child: const Row(children: [Icon(Icons.warning_amber_rounded, color: alertRed), SizedBox(width: 8), Expanded(child: Text('Fatigue signal detected. Prepare driver swap.', style: TextStyle(color: alertRed, fontWeight: FontWeight.w700)))])), const SizedBox(height: 12), Row(children: [const Icon(Icons.brightness_6, color: faderDeepBlue), const SizedBox(width: 10), const Text('Risk-Based Brightness', style: TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('${(_brightness * 100).round()}%')]), Slider(value: _brightness, activeColor: eyeCyan, onChanged: (value) => setState(() => _brightness = value)), const Align(alignment: Alignment.centerLeft, child: Text('Brightness rises to maximum inside high fatigue zones.', style: TextStyle(fontSize: 12, color: Colors.black54)))]))),
        const SizedBox(height: 10),
        Card(elevation: 0, child: const ListTile(leading: Icon(Icons.notifications_active, color: alertRed), title: Text('3-Strike buzzer system', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Active  •  0 of 3 strikes used'))),
        const SizedBox(height: 24),
        const Text('UPCOMING POINTS OF INTEREST', style: _EyebrowStyle()),
        const SizedBox(height: 8),
        const _Poi(icon: Icons.local_cafe, name: 'Highway Bean Coffee', detail: '18 km  •  Coffee shop'),
        const _Poi(icon: Icons.local_parking, name: 'Wardha Rest Area', detail: '31 km  •  Restrooms + parking'),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _showQuiz, icon: const Icon(Icons.mic_none), label: const Text('VOICE ENGAGEMENT CHECK')),
      ]),
    );
  }
}

class _Timeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(height: 100, child: Row(children: [Expanded(flex: 2, child: _Zone(label: 'LOW FATIGUE', color: eyeCyan, icon: Icons.check_circle)), Expanded(flex: 3, child: _Zone(label: 'HIGH FATIGUE', color: alertRed, icon: Icons.warning_rounded)), Expanded(child: _Zone(label: 'LOW', color: eyeCyan, icon: Icons.check_circle))]));
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