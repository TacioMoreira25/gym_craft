import 'dart:math';
import 'package:flutter/material.dart';

class ProgressionPoint {
  final DateTime date;
  final double weight;

  ProgressionPoint({required this.date, required this.weight});
}

class ProgressionChart extends StatelessWidget {
  final List<ProgressionPoint> data;
  final double height;
  final Color color;
  final Color textColor;

  const ProgressionChart({
    super.key,
    required this.data,
    this.height = 150,
    this.color = Colors.greenAccent,
    this.textColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                color: textColor.withOpacity(0.3),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                "Sem histórico suficiente",
                style: TextStyle(color: textColor.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Evolução de Carga",
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Se tiver poucos pontos, limita a largura para não esticar demais
                // "cobrir só a metade da tela" se tiver poucos dados
                double chartWidth = constraints.maxWidth;
                if (data.length < 5) {
                  chartWidth = constraints.maxWidth * 0.6;
                }

                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: chartWidth,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ChartPainter(data, color, textColor),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ProgressionPoint> data;
  final Color color;
  final Color textColor;

  _ChartPainter(this.data, this.color, this.textColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    double minWeight = data.map((e) => e.weight).reduce(min);
    double maxWeight = data.map((e) => e.weight).reduce(max);

    if (maxWeight == minWeight) {
      maxWeight += 5;
      minWeight -= 5;
    }

    double range = maxWeight - minWeight;
    if (range == 0) range = 1;

    final path = Path();
    final fillPath = Path();

    List<Offset> points = [];

    if (data.length == 1) {
      double x = size.width / 2;
      double y = size.height / 2;
      points.add(Offset(x, y));
    } else {
      double stepX = size.width / (data.length - 1);
      for (int i = 0; i < data.length; i++) {
        double x = i * stepX;
        double normalizedY = (data[i].weight - minWeight) / range;
        double y =
            size.height -
            (normalizedY * (size.height * 0.7)) -
            (size.height * 0.15);
        points.add(Offset(x, y));
      }
    }

    if (points.length > 1) {
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

        // Controle para curva suave
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );

        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);
    }

    for (int i = 0; i < points.length; i++) {
      bool isNewDate = false;
      if (i == 0) {
        isNewDate = true;
      } else {
        final prevDate = data[i - 1].date;
        final currDate = data[i].date;
        if (prevDate.day != currDate.day ||
            prevDate.month != currDate.month ||
            prevDate.year != currDate.year) {
          isNewDate = true;
        }
      }

      if (isNewDate && i > 0) {
        final dashPaint = Paint()
          ..color = textColor.withOpacity(0.2)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        double dashY = 0;
        while (dashY < size.height) {
          canvas.drawLine(
            Offset(points[i].dx - (size.width / (data.length - 1)) / 2, dashY),
            Offset(
              points[i].dx - (size.width / (data.length - 1)) / 2,
              dashY + 4,
            ),
            dashPaint,
          );
          dashY += 8;
        }
      }

      canvas.drawCircle(
        points[i],
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        points[i],
        3,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      final textSpan = TextSpan(
        text: "${data[i].weight.toInt()}kg",
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      double labelX = points[i].dx - textPainter.width / 2;
      double labelY = points[i].dy - 25;

      // Ajuste para não sair da tela
      if (labelX < 0) labelX = 0;
      if (labelX + textPainter.width > size.width)
        labelX = size.width - textPainter.width;

      textPainter.paint(canvas, Offset(labelX, labelY));

      if (isNewDate) {
        final dateSpan = TextSpan(
          text: _formatDate(data[i].date),
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        );
        final datePainter = TextPainter(
          text: dateSpan,
          textDirection: TextDirection.ltr,
        );
        datePainter.layout();

        double dateX = points[i].dx - datePainter.width / 2;
        // Se for o primeiro, alinha a esquerda
        if (i == 0 && points.length > 1) dateX = points[i].dx;

        double dateY = 0; // Topo do gráfico

        // Ajuste para não sair da tela
        if (dateX < 0) dateX = 0;
        if (dateX + datePainter.width > size.width)
          dateX = size.width - datePainter.width;

        datePainter.paint(canvas, Offset(dateX, dateY));
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Hoje";
    }

    const weekDays = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"];
    return "${weekDays[date.weekday - 1]} ${date.day}/${date.month}";
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
