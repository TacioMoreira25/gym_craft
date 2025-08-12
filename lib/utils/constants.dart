import 'package:flutter/material.dart';

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

  static Map<String, Color> muscleGroupColors = {
    'Peito': Colors.red,
    'Costas': Colors.blue,
    'Quadricps': Colors.green,
    'Posterior': const Color.fromARGB(255, 0, 41, 1),
    'Glúteos': Colors.pinkAccent,
    'Ombros': Colors.purple,
    'Bíceps': Colors.orange,
    'Tríceps': Colors.tealAccent,
    'Abdômen': Colors.teal,
    'Panturrilhas': Colors.pink,
    'Cardio': Colors.amber,
  };
}