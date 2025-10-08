import 'dart:math' as math;
import 'package:flutter/material.dart';

class TimerProgressArc extends StatelessWidget {
  final int totalSeconds;
  final int maxSeconds;

  const TimerProgressArc({
    super.key,
    required this.totalSeconds,
    required this.maxSeconds,
  });

  String get _formattedTime {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (totalSeconds / maxSeconds).clamp(0.0, 1.0);
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(250, 250),
            painter: _TimerArcPainter(progress: progress),
          ),
          Text(
            _formattedTime,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              // Use a color that contrasts well with the background
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  final double progress;

  _TimerArcPainter({required this.progress});

  // An angle of 0 is at 3 o'clock, this is the start angle for our arc (at 7 o'clock)
  final double _startAngle = (150 * math.pi) / 180; 
  // The total sweep of our arc (240 degrees)
  final double _totalSweepAngle = (240 * math.pi) / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double strokeWidth = 15.0;

    // 1. Draw the background track
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _totalSweepAngle, false, backgroundPaint);

    // 2. Draw the progress arc with an interpolated color
    final Color currentColor = Color.lerp(Colors.red, Colors.green, progress)!;

    final foregroundPaint = Paint()
      ..color = currentColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final double currentSweepAngle = _totalSweepAngle * progress;

    canvas.drawArc(rect, _startAngle, currentSweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
