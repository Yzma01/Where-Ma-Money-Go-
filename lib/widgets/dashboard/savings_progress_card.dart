import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class SavingsProgressCard extends StatefulWidget {
  final AppThemeColors colors;
  final double savings; // depósitos al ahorro (expense con categoría ahorro)
  final double withdrawals; // retiros del ahorro (income con categoría ahorro)
  final double income;
  final double? savingsGoalPercent;

  const SavingsProgressCard({
    super.key,
    required this.colors,
    required this.savings,
    required this.withdrawals,
    required this.income,
    this.savingsGoalPercent,
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
    if (old.savings != widget.savings ||
        old.withdrawals != widget.withdrawals ||
        old.income != widget.income) {
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
    final goalPercent = widget.savingsGoalPercent ?? 20.0;
    final goalAmount = widget.income * goalPercent / 100;
    final net = widget.savings - widget.withdrawals; // puede ser negativo
    final progress = goalAmount > 0 ? (net / goalAmount).clamp(-1.0, 1.0) : 0.0;
    final isNegative = net < 0;

    Color progressColor;
    Icon statusIcon;
    if (isNegative) {
      progressColor = colors.error;
      statusIcon = Icon(Icons.trending_down, size: 12, color: colors.error);
    } else if (progress >= 1.0) {
      progressColor = colors.success;
      statusIcon = Icon(Icons.trending_up, size: 12, color: colors.success);
    } else if (progress >= 0.6) {
      progressColor = colors.warning;
      statusIcon = Icon(Icons.trending_flat, size: 12, color: colors.warning);
    } else {
      progressColor = colors.primary;
      statusIcon = Icon(
        Icons.savings_outlined,
        size: 12,
        color: colors.primary,
      );
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
          // ── Círculo de progreso + número
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress.abs() * _animation.value,
                        isNegative: isNegative,
                        color: progressColor,
                        trackColor: progressColor.withOpacity(0.12),
                      ),
                      child: Center(child: statusIcon),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Badge de porcentaje
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Ahorro',
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\₡${net.toStringAsFixed(0)}',
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
  final double progress; // 0.0 → 1.0
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
    const strokeWidth = 5.0;
    const startAngle = -math.pi / 2;

    // Track
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
        // Negativo va en sentido anti-horario
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
