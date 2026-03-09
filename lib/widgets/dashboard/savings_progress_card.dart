import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class SavingsProgressCard extends StatefulWidget {
  final AppThemeColors colors;
  final double currentAmount; // lo que ya ahorró
  final double goalAmount; // la meta total
  final String? name;

  const SavingsProgressCard({
    super.key,
    required this.colors,
    required this.currentAmount,
    required this.goalAmount,
    this.name,
  });

  @override
  State<SavingsProgressCard> createState() => _SavingsProgressCardState();
}

class _SavingsProgressCardState extends State<SavingsProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SavingsProgressCard old) {
    super.didUpdateWidget(old);
    if (old.currentAmount != widget.currentAmount ||
        old.goalAmount != widget.goalAmount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    // progress va de 0.0 a 1.0 (o negativo si currentAmount < 0)
    final progress = widget.goalAmount > 0
        ? (widget.currentAmount / widget.goalAmount).clamp(-1.0, 1.0)
        : 0.0;
    final isNegative = widget.currentAmount < 0;

    Color progressColor;
    IconData statusIconData;
    if (isNegative) {
      progressColor = colors.error;
      statusIconData = Icons.trending_down;
    } else if (progress >= 1.0) {
      progressColor = colors.success;
      statusIconData = Icons.trending_up;
    } else if (progress >= 0.6) {
      progressColor = colors.warning;
      statusIconData = Icons.trending_flat;
    } else {
      progressColor = colors.primary;
      statusIconData = Icons.savings_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              final animatedProgress = progress.abs() * _animation.value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: animatedProgress,
                        isNegative: isNegative,
                        color: progressColor,
                        trackColor: progressColor.withOpacity(0.12),
                      ),
                      child: Center(
                        child: Icon(
                          statusIconData,
                          size: 12,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            widget.name ?? 'Ahorro',
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\u20a1${widget.currentAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isNegative;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.isNegative,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 7) / 2;
    const strokeWidth = 3.0;
    const startAngle = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        isNegative ? -sweep : sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isNegative != isNegative;
}
