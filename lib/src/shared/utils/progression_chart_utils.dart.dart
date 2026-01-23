import 'package:flutter/material.dart';
import '../../ui/widgets/progression_chart.dart';

class ProgressionChartUtils {
  // Função para processar os dados brutos e extrair o ponto de maior carga por sessão.
  static List<ProgressionPoint> aggregateProgressionData(
    List<ProgressionPoint> allPoints,
  ) {
    if (allPoints.isEmpty) {
      return [];
    }
    // 1. Agrupar todos os pontos pelo 'sessionId' ou, como fallback, pela data.
    // A chave do mapa será o ID da sessão, e o valor será uma lista de pontos daquela sessão.
    final Map<Object, List<ProgressionPoint>> sessions = {};

    for (final point in allPoints) {
      // Usa o sessionId como chave. Se for nulo, agrupa pelo dia (DateUtils.dateOnly).
      final key = DateUtils.dateOnly(point.date);

      if (!sessions.containsKey(key)) {
        sessions[key] = [];
      }
      sessions[key]!.add(point);
    }

    // 2. Para cada sessão, encontrar o ponto com o maior peso.
    final List<ProgressionPoint> aggregatedPoints = [];
    sessions.forEach((key, pointsInSession) {
      if (pointsInSession.isNotEmpty) {
        // Ordena os pontos da sessão pelo peso (do maior para o menor).
        pointsInSession.sort((a, b) => b.weight.compareTo(a.weight));

        // O primeiro item da lista ordenada é o de maior peso.
        aggregatedPoints.add(pointsInSession.first);
      }
    });

    // 3. Ordenar a lista final por data para garantir que o gráfico seja cronológico.
    aggregatedPoints.sort((a, b) => a.date.compareTo(b.date));

    return aggregatedPoints;
  }
}
