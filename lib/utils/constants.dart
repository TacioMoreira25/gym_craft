import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/series_type.dart';

class AppConstants {
  static const List<String> muscleGroups = [
    'Peito',
    'Costas',
    'Quadríceps',
    'Posterior',
    'Glúteos',
    'Panturrilhas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdomen',
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
  static const Map<String, Color> categoryColors = {
    'Peito': Color(0xFFEF4444), // Red-500
    'Costas': Color(0xFF3B82F6), // Blue-500
    'Quadríceps': Color(0xFF10B981), // Emerald-500
    'Posterior': Color(0xFF059669), // Emerald-600
    'Glúteos': Color(0xFFEC4899), // Pink-500
    'Ombros': Color(0xFFF97316), // Orange-500
    'Bíceps': Color(0xFF8B5CF6), // Violet-500
    'Tríceps': Color(0xFF6366F1), // Indigo-500
    'Abdomen': Color(0xFF06B6D4), // Cyan-500
    'Antebraços': Color(0xFF84CC16), // Lime-500
    'Panturrilhas': Color(0xFF64748B), // Slate-500
    'Cardio': Color(0xFFF59E0B), // Amber-500
  };
  static const Map<String, Color> categoryColorsDark = {
    'Peito': Color(0xFFF87171), // Red-400
    'Costas': Color(0xFF60A5FA), // Blue-400
    'Quadríceps': Color(0xFF34D399), // Emerald-400
    'Posterior': Color(0xFF10B981), // Emerald-500
    'Glúteos': Color(0xFFF472B6), // Pink-400
    'Ombros': Color(0xFFFB923C), // Orange-400
    'Bíceps': Color(0xFFA78BFA), // Violet-400
    'Tríceps': Color(0xFF818CF8), // Indigo-400
    'Abdomen': Color(0xFF22D3EE), // Cyan-400
    'Antebraços': Color(0xFFA3E635), // Lime-400
    'Panturrilhas': Color(0xFF94A3B8), // Slate-400
    'Cardio': Color(0xFFFBBF24), // Amber-400
  };
  static const Map<String, IconData> muscleGroupIcons = {
    'Peito': Icons.fitness_center,
    'Costas': Icons.back_hand,
    'Quadríceps': Icons.accessibility_new,
    'Posterior': Icons.sports_gymnastics,
    'Glúteos': Icons.self_improvement,
    'Ombros': Icons.sports_martial_arts,
    'Bíceps': Icons.sports_kabaddi,
    'Tríceps': Icons.gesture,
    'Abdomen': Icons.fitbit,
    'Antebraços': Icons.pan_tool,
    'Panturrilhas': Icons.directions_walk,
    'Cardio': Icons.favorite,
  };
  static const Map<SeriesType, Color> seriesTypeColors = {
    SeriesType.valid: Color(0xFF10B981), // Emerald-500
    SeriesType.warmup: Color(0xFFF97316), // Orange-500
    SeriesType.recognition: Color(0xFF3B82F6), // Blue-500
    SeriesType.dropset: Color(0xFF8B5CF6), // Violet-500
    SeriesType.failure: Color(0xFFEF4444), // Red-500
    SeriesType.rest: Color(0xFF64748B), // Slate-500
    SeriesType.negativa: Color(0xFF6366F1), // Indigo-500
  };
  static const Map<SeriesType, Color> seriesTypeColorsDark = {
    SeriesType.valid: Color(0xFF34D399), // Emerald-400
    SeriesType.warmup: Color(0xFFFB923C), // Orange-400
    SeriesType.recognition: Color(0xFF60A5FA), // Blue-400
    SeriesType.dropset: Color(0xFFA78BFA), // Violet-400
    SeriesType.failure: Color(0xFFF87171), // Red-400
    SeriesType.rest: Color(0xFF94A3B8), // Slate-400
    SeriesType.negativa: Color(0xFF818CF8), // Indigo-400
  };
  static const Map<SeriesType, IconData> seriesTypeIcons = {
    SeriesType.valid: Icons.check_circle_rounded,
    SeriesType.warmup: Icons.local_fire_department_rounded,
    SeriesType.recognition: Icons.visibility_rounded,
    SeriesType.dropset: Icons.trending_down_rounded,
    SeriesType.failure: Icons.flash_on_rounded,
    SeriesType.rest: Icons.pause_circle_rounded,
    SeriesType.negativa: Icons.trending_up_rounded,
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
  static const Map<SeriesType, Color> seriesTypeBackgroundColors = {
    SeriesType.valid: Color(0xFFD1FAE5), // Emerald-100
    SeriesType.warmup: Color(0xFFFED7AA), // Orange-100
    SeriesType.recognition: Color(0xFFDBEAFE), // Blue-100
    SeriesType.dropset: Color(0xFFE9D5FF), // Violet-100
    SeriesType.failure: Color(0xFFFEE2E2), // Red-100
    SeriesType.rest: Color(0xFFF1F5F9), // Slate-100
    SeriesType.negativa: Color(0xFFE0E7FF), // Indigo-100
  };
  static const Map<SeriesType, Color> seriesTypeBackgroundColorsDark = {
    SeriesType.valid: Color(0xFF064E3B), // Emerald-900
    SeriesType.warmup: Color(0xFF9A3412), // Orange-800
    SeriesType.recognition: Color(0xFF1E3A8A), // Blue-800
    SeriesType.dropset: Color(0xFF581C87), // Violet-800
    SeriesType.failure: Color(0xFF991B1B), // Red-800
    SeriesType.rest: Color(0xFF334155), // Slate-700
    SeriesType.negativa: Color(0xFF312E81), // Indigo-800
  };
  static IconData getMuscleGroupIcon(String muscleGroup) {
    return muscleGroupIcons[muscleGroup] ?? Icons.fitness_center;
  }
  static Color getMuscleGroupColor(String muscleGroup, {bool isDark = false}) {
    if (isDark) {
      return categoryColorsDark[muscleGroup] ?? categoryColorsDark['Cardio']!;
    }
    return categoryColors[muscleGroup] ?? categoryColors['Cardio']!;
  }
  static Color getSeriesTypeColor(SeriesType type, {bool isDark = false}) {
    if (isDark) {
      return seriesTypeColorsDark[type] ?? seriesTypeColorsDark[SeriesType.valid]!;
    }
    return seriesTypeColors[type] ?? seriesTypeColors[SeriesType.valid]!;
  }
  static Color getSeriesTypeBackgroundColor(SeriesType type, {bool isDark = false}) {
    if (isDark) {
      return seriesTypeBackgroundColorsDark[type] ?? seriesTypeBackgroundColorsDark[SeriesType.valid]!;
    }
    return seriesTypeBackgroundColors[type] ?? seriesTypeBackgroundColors[SeriesType.valid]!;
  }
  static IconData getSeriesTypeIcon(SeriesType type) {
    return seriesTypeIcons[type] ?? Icons.help_rounded;
  }
  static String getSeriesTypeName(SeriesType type) {
    return seriesTypeNames[type] ?? 'Desconhecido';
  }
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
  static Map<String, Map<String, dynamic>> getStatusConfigs(bool isDark) {
    return {
      'active': {
        'color': isDark ? const Color(0xFF34D399) : const Color(0xFF10B981), // Emerald
        'backgroundColor': isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        'text': 'ATIVA',
      },
      'inactive': {
        'color': isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), // Slate
        'backgroundColor': isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        'text': 'INATIVA',
      },
    };
  }
  static List<BoxShadow> getCardShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    }
  }
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)], // Emerald to Cyan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)], // Amber to Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
