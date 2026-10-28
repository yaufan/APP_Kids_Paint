import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/weather.dart';

/// The weather drawn over the town or a place, in screen space: rain
/// falling, clouds drifting by, leaves in the wind, a rainbow fading in.
/// In the candy house the rain is sprinkles. It never takes a tap.
class WeatherLayer extends StatefulWidget {
  const WeatherLayer({super.key, required this.weather, this.sprinkles = false});

  final Weather weather;

  /// Rain of colored sprinkles instead of water (the candy house).
  final bool sprinkles;

  @override
  State<WeatherLayer> createState() => _WeatherLayerState();
}

class _WeatherLayerState extends State<WeatherLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6);
  final _seconds = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(WeatherLayer old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // Sunshine has nothing to move: no frames for it.
  void _sync() {
    final moving = widget.weather != Weather.sunny;
    if (moving && !_ticker.isActive) _ticker.start();
    if (!moving && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather == Weather.sunny) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: ValueKey('weather-${widget.weather.name}'),
          painter: WeatherPainter(widget.weather, _seconds, sprinkles: widget.sprinkles),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class WeatherPainter extends CustomPainter {
  WeatherPainter(this.weather, this.seconds, {this.sprinkles = false}) : super(repaint: seconds);

  final Weather weather;
  final ValueListenable<double> seconds;
  final bool sprinkles;

  static const _sprinkleColors = [Color(0xFFFF5E5B), Color(0xFFFFD84D), Color(0xFF4DA3FF), Color(0xFFA98BFF), Color(0xFF6BCB77), Color(0xFFFF8FB1)];

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    switch (weather) {
      case Weather.sunny:
        break;
      case Weather.cloudy:
        canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x12384A5C));
        _clouds(canvas, size, t, const Color(0x99FFFFFF));
      case Weather.rain:
        if (!sprinkles) canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x2234507A));
        _clouds(canvas, size, t, sprinkles ? const Color(0xAAFFE0F0) : const Color(0xAADDE3EA));
        sprinkles ? _sprinkles(canvas, size, t) : _rain(canvas, size, t);
      case Weather.rainbow:
        _rainbow(canvas, size, t);
      case Weather.windy:
        _leaves(canvas, size, t);
    }
  }

  void _clouds(Canvas canvas, Size size, double t, Color color) {
    final paint = Paint()..color = color;
    final r = math.Random(3);
    for (var i = 0; i < 3; i++) {
      final w = size.width * (0.35 + 0.15 * r.nextDouble());
      final span = size.width + w * 2;
      final x = (r.nextDouble() * span + t * (10 + 6 * i)) % span - w;
      final y = size.height * (0.06 + 0.1 * i);
      for (final (dx, dy, k) in [(0.0, 0.0, 0.28), (0.25, -0.08, 0.22), (0.5, 0.0, 0.26), (0.75, 0.02, 0.18)]) {
        canvas.drawCircle(Offset(x + w * dx, y + w * dy), w * k, paint);
      }
    }
  }

  void _rain(Canvas canvas, Size size, double t) {
    final r = math.Random(11);
    final paint = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final count = (size.width * size.height / 9000).clamp(40, 160).round();
    for (var i = 0; i < count; i++) {
      final speed = 650 + 350 * r.nextDouble(), length = 16 + 12 * r.nextDouble();
      final span = size.height + 60;
      final y = (r.nextDouble() * span + t * speed) % span - 30;
      final x = (r.nextDouble() * (size.width + 80) - y * 0.22) % (size.width + 80) - 40;
      canvas.drawLine(Offset(x, y), Offset(x - length * 0.22, y + length), paint);
    }
  }

  void _sprinkles(Canvas canvas, Size size, double t) {
    final r = math.Random(13);
    final count = (size.width * size.height / 14000).clamp(30, 110).round();
    for (var i = 0; i < count; i++) {
      final speed = 160 + 120 * r.nextDouble();
      final span = size.height + 40;
      final y = (r.nextDouble() * span + t * speed) % span - 20;
      final x = r.nextDouble() * size.width + 10 * math.sin(t * 2 + i);
      final paint = Paint()
        ..color = _sprinkleColors[i % _sprinkleColors.length]
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      final a = r.nextDouble() * math.pi + t * (1 + r.nextDouble());
      final d = Offset(math.cos(a), math.sin(a)) * 6;
      canvas.drawLine(Offset(x, y) - d, Offset(x, y) + d, paint);
    }
  }

  void _leaves(Canvas canvas, Size size, double t) {
    final r = math.Random(17);
    const colors = [Color(0xCC6BCB77), Color(0xCC9ED36A), Color(0xCCFFC94A), Color(0xCCFF9AB8)];
    for (var i = 0; i < 22; i++) {
      final speed = 110 + 110 * r.nextDouble();
      final span = size.width + 80;
      final x = (r.nextDouble() * span + t * speed) % span - 40;
      final y = size.height * r.nextDouble() + 26 * math.sin(t * (1.2 + r.nextDouble()) + i);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * (2 + 2 * r.nextDouble()) + i);
      canvas.drawOval(const Rect.fromLTWH(-9, -4, 18, 8), Paint()..color = colors[i % colors.length]);
      canvas.restore();
    }
    // A few streaks of wind.
    final streak = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final span = size.width + 300;
      final x = (i * 260 + t * 260) % span - 150;
      final y = size.height * (0.2 + 0.18 * i);
      canvas.drawPath(Path()..moveTo(x, y)..quadraticBezierTo(x + 60, y - 14, x + 120, y), streak);
    }
  }

  void _rainbow(Canvas canvas, Size size, double t) {
    const bands = [Color(0xFFFF5E5B), Color(0xFFFF9F45), Color(0xFFFFD84D), Color(0xFF6BCB77), Color(0xFF4DA3FF), Color(0xFF8C6CFF)];
    final fade = (t / 2.5).clamp(0.0, 1.0);
    final center = Offset(size.width * 0.72, size.height * 0.42);
    final outer = math.max(size.width, size.height) * 0.42;
    final width = outer * 0.05;
    for (final (i, color) in bands.indexed) {
      final radius = outer - i * width;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.32 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }
  }

  @override
  bool shouldRepaint(WeatherPainter old) => old.weather != weather || old.sprinkles != sprinkles;
}
