import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/database_service.dart';
import '../../models/routine.dart';
import 'base_controller.dart';

class CreateRoutineController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<String> routineSuggestions = [
    'Push Pull Legs',
    'Upper Lower',
    'Full Body',
    'ABC Tradicional',
    'ABCD Split',
    'Ganho de Massa',
    'Definição',
    'Força',
    'Iniciante',
    'Avançado',
  ];

  void applySuggestion(String suggestion) {
    nameController.text = suggestion;
    if (descriptionController.text.isEmpty) {
      descriptionController.text = _getDescriptionSuggestion(suggestion);
    }
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  String _getDescriptionSuggestion(String routineName) {
    switch (routineName) {
      case 'Push Pull Legs':
        return 'Rotina dividida em treinos de empurrar, puxar e pernas';
      case 'Upper Lower':
        return 'Divisão entre membros superiores e inferiores';
      case 'Full Body':
        return 'Treino completo trabalhando corpo todo';
      case 'ABC Tradicional':
        return 'Divisão clássica em três treinos diferentes';
      case 'ABCD Split':
        return 'Divisão em quatro treinos específicos';
      case 'Ganho de Massa':
        return 'Foco no desenvolvimento de massa muscular';
      case 'Definição':
        return 'Rotina voltada para definição e queima de gordura';
      case 'Força':
        return 'Treinamento focado no ganho de força';
      case 'Iniciante':
        return 'Rotina adequada para iniciantes';
      case 'Avançado':
        return 'Rotina para praticantes avançados';
      default:
        return 'Rotina personalizada de treinos';
    }
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    clearError();
    return true;
  }

  Future<bool> saveRoutine() async {
    if (!validateForm()) {
      return false;
    }

    setLoading(true);

    try {
      final routine = Routine(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _databaseService.routines.insertRoutine(routine);
      return true;
    } catch (e) {
      setError('Erro ao salvar rotina: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
