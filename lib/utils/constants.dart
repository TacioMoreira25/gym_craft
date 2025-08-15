import 'package:flutter/material.dart';
import '../models/series_type.dart';

class AppConstants {
  static const List<String> muscleGroups = [
    'Peito',
    'Costas',
    'Quadricps',
    'Posterior',
    'Glúteos',
    'Panturrilhas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdômen',
    'Cardio',
    'Antebraços',
  ];

  static const List<String> workoutSuggestions = [
    'Treino A',
    'Treino B',
    'Treino C',
    'Push',
    'Pull',
    'Legs',
    'Upper',
    'Lower',
    'Peito e Tríceps',
    'Costas e Bíceps',
    'Pernas e Glúteos',
    'Ombro e Abdômen',
    'Full Body',
    'Cardio',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
  ];

  static Map<String, Color> categoryColors = {
    'Peito': Colors.red,
    'Costas': Colors.blue,
    'Quadricps': Colors.green,
    'Posterior': const Color.fromARGB(255, 0, 41, 1),
    'Glúteos': Colors.pinkAccent,
    'Ombros': Colors.purple,
    'Bíceps': Colors.orange,
    'Tríceps': Colors.tealAccent,
    'Abdômen': Colors.teal,
    'Antebraços': Colors.black54,
    'Panturrilhas': Colors.pink,
    'Cardio': Colors.amber,
  };

  static const Map<SeriesType, Color> seriesTypeColors = {
    SeriesType.valid: Colors.green,
    SeriesType.warmup: Colors.orange,
    SeriesType.recognition: Colors.blue,
    SeriesType.dropset: Colors.purple,
    SeriesType.failure: Colors.red,
    SeriesType.rest: Colors.grey,
    SeriesType.negativa: Colors.indigo,
  };

  static const Map<SeriesType, IconData> seriesTypeIcons = {
    SeriesType.valid: Icons.check_circle,
    SeriesType.warmup: Icons.whatshot,
    SeriesType.recognition: Icons.visibility,
    SeriesType.dropset: Icons.trending_down,
    SeriesType.failure: Icons.warning,
    SeriesType.rest: Icons.pause,
    SeriesType.negativa: Icons.trending_up,
  };

  static const Map<SeriesType, String> seriesTypeNames = {
    SeriesType.valid: 'Válida',
    SeriesType.warmup: 'Aquecimento',
    SeriesType.recognition: 'Reconhecimento',
    SeriesType.dropset: 'Drop Set',
    SeriesType.failure: 'Falha',
    SeriesType.rest: 'Descanso',
    SeriesType.negativa: 'Negativa',
  };

  static Color getSeriesTypeColor(SeriesType type) {
    return seriesTypeColors[type] ?? Colors.grey;
  }

  static IconData getSeriesTypeIcon(SeriesType type) {
    return seriesTypeIcons[type] ?? Icons.help;
  }

  static String getSeriesTypeName(SeriesType type) {
    return seriesTypeNames[type] ?? 'Desconhecido';
  }

  static Map<SeriesType, Color> getDarkSeriesTypeColors() {
    return {
      SeriesType.valid: Colors.green.shade400,
      SeriesType.warmup: Colors.orange.shade400,
      SeriesType.recognition: Colors.blue.shade400,
      SeriesType.dropset: Colors.purple.shade400,
      SeriesType.failure: Colors.red.shade400,
      SeriesType.rest: Colors.grey.shade400,
      SeriesType.negativa: Colors.indigo.shade400,
    };
  }

  static Map<SeriesType, Color> getSeriesTypeBackgroundColors() {
    return {
      SeriesType.valid: Colors.green.shade100,
      SeriesType.warmup: Colors.orange.shade100,
      SeriesType.recognition: Colors.blue.shade100,
      SeriesType.dropset: Colors.purple.shade100,
      SeriesType.failure: Colors.red.shade100,
      SeriesType.rest: Colors.grey.shade100,
      SeriesType.negativa: Colors.indigo.shade100,
    };
  }

  static const Map<SeriesType, IconData> alternativeSeriesTypeIcons = {
    SeriesType.valid: Icons.fitness_center,
    SeriesType.warmup: Icons.local_fire_department,
    SeriesType.recognition: Icons.remove_red_eye,
    SeriesType.dropset: Icons.arrow_drop_down_circle,
    SeriesType.failure: Icons.flash_on,
    SeriesType.rest: Icons.bed,
    SeriesType.negativa: Icons.trending_down,
  };

  static bool shouldShowField(SeriesType type, String field) {
    switch (type) {
      case SeriesType.valid:
      case SeriesType.dropset:
      case SeriesType.failure:
      case SeriesType.negativa:
        return true; 
      case SeriesType.warmup:
      case SeriesType.recognition:
        return field != 'weight'; 
      
      case SeriesType.rest:
        return field == 'rest'; 
    }
  }
}