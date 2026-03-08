import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:where_ma_money_go/providers/theme/app_colors.dart';

class CategoryChartData {
  final String name;
  final String icon;
  final double amount;
  final double total;

  const CategoryChartData({
    required this.name,
    required this.icon,
    required this.amount,
    required this.total,
  });

  double get percentage => total > 0 ? (amount / total * 100) : 0;
}

class CategoryPieChart extends StatefulWidget {
  final AppThemeColors colors;
  final List<CategoryChartData> data;

  const CategoryPieChart({super.key, required this.colors, required this.data});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selected = -1;

  // Paleta de colores para las categorías
  static const _palette = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF8BC34A),
    Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final data = widget.data.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Gastos por categoría', colors: colors),
          const SizedBox(height: 20),
          Row(
            children: [
              // Gráfico de dona
              SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (_, __) => GestureDetector(
                    onTapDown: (details) => _handleTap(details, data, 140),
                    child: CustomPaint(
                      painter: _DonutPainter(
                        data: data,
                        colors: _palette,
                        progress: _animation.value,
                        selected: _selected,
                        backgroundColor: colors.border,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Leyenda
              Expanded(
                child: Column(
                  children: data.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final color = _palette[i % _palette.length];
                    final isSelected = _selected == i;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selected = _selected == i ? -1 : i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.icon,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          // Detalle de selección
          if (_selected >= 0 && _selected < data.length) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _palette[_selected % _palette.length].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _palette[_selected % _palette.length].withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    data[_selected].icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data[_selected].name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '\₡${data[_selected].amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _palette[_selected % _palette.length],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleTap(
    TapDownDetails details,
    List<CategoryChartData> data,
    double size,
  ) {
    final center = Offset(size / 2, size / 2);
    final pos = details.localPosition;
    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final radius = size / 2;
    final innerRadius = radius * 0.52;

    if (dist < innerRadius || dist > radius) return;

    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final total = data.fold(0.0, (s, d) => s + d.amount);
    double start = 0;
    for (int i = 0; i < data.length; i++) {
      final sweep = data[i].amount / total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) {
        setState(() => _selected = _selected == i ? -1 : i);
        return;
      }
      start += sweep;
    }
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryChartData> data;
  final List<Color> colors;
  final double progress;
  final int selected;
  final Color backgroundColor;

  _DonutPainter({
    required this.data,
    required this.colors,
    required this.progress,
    required this.selected,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.52;
    final strokeWidth = radius - innerRadius;

    final total = data.fold(0.0, (s, d) => s + d.amount);
    double startAngle = -math.pi / 2;
    const gap = 0.02;

    for (int i = 0; i < data.length; i++) {
      final sweep = (data[i].amount / total) * 2 * math.pi * progress - gap;
      if (sweep <= 0) continue;

      final isSelected = selected == i;
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(isSelected ? 1.0 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: innerRadius + (isSelected ? strokeWidth + 4 : strokeWidth) / 2,
      );
      canvas.drawArc(rect, startAngle + gap / 2, sweep, false, paint);
      startAngle += sweep + gap;
    }

    // Centro: texto del total o ítem seleccionado
    if (selected >= 0 && selected < data.length) {
      _drawCenterText(
        canvas,
        center,
        data[selected].icon,
        '${data[selected].percentage.toStringAsFixed(0)}%',
        colors[selected % colors.length],
      );
    } else {
      _drawCenterText(canvas, center, '💸', 'Gastos', backgroundColor);
    }
  }

  void _drawCenterText(
    Canvas canvas,
    Offset center,
    String emoji,
    String label,
    Color color,
  ) {
    final emojiPainter = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    )..layout();
    emojiPainter.paint(
      canvas,
      center - Offset(emojiPainter.width / 2, emojiPainter.height / 2 + 10),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      center - Offset(labelPainter.width / 2, -labelPainter.height / 2 + 4),
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.selected != selected;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppThemeColors colors;
  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: colors.textPrimary,
      ),
    );
  }
}
