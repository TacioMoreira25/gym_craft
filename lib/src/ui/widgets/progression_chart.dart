import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ProgressionPoint {
  final DateTime date;
  final double weight;
  final int? sessionId;

  ProgressionPoint({required this.date, required this.weight, this.sessionId});
}

class ProgressionChart extends StatefulWidget {
  final List<ProgressionPoint> data;
  final double height;
  final Color contentColor;
  final Color spotColor;
  final Color backgroundColor;

  const ProgressionChart({
    super.key,
    required this.data,
    this.height = 250,
    this.contentColor = const Color(0xFFFFC300),
    this.spotColor = Colors.orangeAccent,
    this.backgroundColor = const Color(0xFF1E1E1E),
  });

  @override
  State<ProgressionChart> createState() => _ProgressionChartState();
}

class _ProgressionChartState extends State<ProgressionChart> {
  late List<ProgressionPoint> _sortedData;
  late List<Color> _pointColors;
  double _minX = 0;
  double _maxX = 0;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(ProgressionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _processData();
    }
  }

  void _processData() {
    if (widget.data.isEmpty) {
      _sortedData = [];
      _pointColors = [];
      return;
    }

    _sortedData = widget.data.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    _calculateColors();
    _resetZoom();
  }

  void _calculateColors() {
    _pointColors = [];
    if (_sortedData.isEmpty) return;

    final colorPalette = [
      widget.contentColor,
      widget.spotColor,
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
    ];

    int colorIndex = 0;
    _pointColors.add(colorPalette[colorIndex]);

    for (int i = 1; i < _sortedData.length; i++) {
      final prevPoint = _sortedData[i - 1];
      final currPoint = _sortedData[i];

      bool sessionChanged = false;
      if (prevPoint.sessionId != null && currPoint.sessionId != null) {
        sessionChanged = prevPoint.sessionId != currPoint.sessionId;
      } else {
        sessionChanged = !DateUtils.isSameDay(prevPoint.date, currPoint.date);
      }

      if (sessionChanged) {
        colorIndex = (colorIndex + 1) % colorPalette.length;
      }
      _pointColors.add(colorPalette[colorIndex]);
    }
  }

  void _resetZoom() {
    setState(() {
      if (_sortedData.length <= 1) {
        _minX = -0.5;
        _maxX = 0.5;
      } else {
        _minX = 0;
        _maxX = (_sortedData.length - 1).toDouble();
      }
    });
  }

  void _zoomIn() {
    setState(() {
      double currentRange = _maxX - _minX;
      if (currentRange <= 1.5) return;
      double center = (_minX + _maxX) / 2;
      double newRange = currentRange * 0.6;
      _minX = center - newRange / 2;
      _maxX = center + newRange / 2;
      _fixBounds();
    });
  }

  void _zoomOut() {
    setState(() {
      double currentRange = _maxX - _minX;
      double center = (_minX + _maxX) / 2;
      double newRange = currentRange * 1.4;
      _minX = center - newRange / 2;
      _maxX = center + newRange / 2;
      _fixBounds();
    });
  }

  void _fixBounds() {
    double totalMax = max((_sortedData.length - 1).toDouble(), 0.0);
    if (_sortedData.length <= 1) {
      _minX = -0.5;
      _maxX = 0.5;
      return;
    }
    if (_minX < 0) _minX = 0;
    if (_maxX > totalMax) _maxX = totalMax;
    if ((_maxX - _minX) > totalMax) {
      _minX = 0;
      _maxX = totalMax;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedData.isEmpty) return _buildEmptyState();

    double minWeight = _sortedData.map((e) => e.weight).reduce(min);
    double maxWeight = _sortedData.map((e) => e.weight).reduce(max);
    double minY = (minWeight - 5).clamp(0, double.infinity);
    double maxY = maxWeight * 1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução de Carga',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_sortedData.isNotEmpty)
                    Text(
                      _sortedData.length > 1
                          ? '${_sortedData.length} registros'
                          : 'Primeiro registro',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  _buildZoomButton(Icons.add, _zoomIn),
                  _buildZoomButton(Icons.refresh, _resetZoom),
                  _buildZoomButton(Icons.remove, _zoomOut),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                minX: _minX,
                maxX: _maxX,
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2C2C2C),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots
                          .map((spot) {
                            final index = spot.x.toInt();
                            if (index < 0 || index >= _sortedData.length)
                              return null;
                            final point = _sortedData[index];
                            // Mostra Hora se for hoje, Data se for outro dia
                            final dateFormat =
                                DateUtils.isSameDay(point.date, DateTime.now())
                                ? DateFormat('HH:mm')
                                : DateFormat('dd/MM');

                            return LineTooltipItem(
                              '${point.weight.toStringAsFixed(1)} kg\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: dateFormat.format(point.date),
                                  style: TextStyle(
                                    color: widget.contentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          })
                          .whereType<LineTooltipItem>()
                          .toList();
                    },
                  ),
                  getTouchedSpotIndicator: (_, indexes) => indexes
                      .map(
                        (_) => TouchedSpotIndicatorData(
                          FlLine(
                            color: Colors.white24,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (p, __, ___, ____) =>
                                FlDotCirclePainter(
                                  radius: 6,
                                  color: widget.contentColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (v, m) => v == minY || v == maxY
                          ? const SizedBox()
                          : Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        final index = value.toInt();
                        if (index < 0 || index >= _sortedData.length)
                          return const SizedBox.shrink();

                        final point = _sortedData[index];
                        final isLast = index == _sortedData.length - 1;

                        // LÓGICA DE DATA:
                        // Se for o mesmo dia do ponto anterior, mostra a HORA.
                        // Se for dia diferente, mostra DATA.
                        bool sameDayAsPrev = false;
                        if (index > 0) {
                          sameDayAsPrev = DateUtils.isSameDay(
                            point.date,
                            _sortedData[index - 1].date,
                          );
                        }

                        String text;
                        if (isLast) {
                          text = "Agora";
                        } else if (sameDayAsPrev) {
                          text = DateFormat('HH:mm').format(
                            point.date,
                          ); // Mostra hora para testes no mesmo dia
                        } else {
                          text = DateFormat('dd/MM').format(point.date);
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isLast ? widget.spotColor : Colors.white38,
                              fontSize: 9,
                              fontWeight: isLast
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sortedData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.1,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    gradient: _getLineGradient(),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final color = _pointColors[index];
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 1,
                          strokeColor: Colors.black,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          widget.contentColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getLineGradient() {
    if (_sortedData.isEmpty) {
      return LinearGradient(colors: [widget.contentColor, widget.contentColor]);
    }

    final List<Color> colors = [];
    final List<double> stops = [];

    for (int i = 0; i < _sortedData.length; i++) {
      final color = _pointColors[i];
      final stop =
          i / (_sortedData.length - 1 > 0 ? _sortedData.length - 1 : 1);

      if (i > 0) {
        final prevColor = _pointColors[i - 1];
        if (color != prevColor) {
    
          final prevStop =
              (i - 1) /
              (_sortedData.length - 1 > 0 ? _sortedData.length - 1 : 1);
          colors.add(color);
          stops.add(prevStop);
        }
      }

      colors.add(color);
      stops.add(stop);
    }

    if (colors.length == 1) {
      colors.add(colors.first);
      stops.add(1.0);
    }

    return LinearGradient(colors: colors, stops: stops);
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70, size: 20),
      onPressed: onPressed,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildEmptyState() => SizedBox(
    height: widget.height,
    child: Center(
      child: Text("Sem dados", style: TextStyle(color: Colors.white54)),
    ),
  );
}
