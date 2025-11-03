import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../data/services/database_service.dart';
import '../../shared/constants/constants.dart';
import 'base_controller.dart';

class ExerciseManagementController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  List<String> get categories => ['Todos', ...AppConstants.muscleGroups];

  List<Exercise> get exercises => _exercises;
  List<Exercise> get filteredExercises => _filteredExercises;
  String get selectedCategory => _selectedCategory;
  TextEditingController get searchController => _searchController;
  bool get hasExercises => _exercises.isNotEmpty;
  bool get hasFilteredExercises => _filteredExercises.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadExercises() async {
    setLoading(true);
    try {
      final exercises = await _databaseService.exercises.getAllExercises();
      _exercises = exercises;
      _applyFilters();
      setLoading(false);
    } catch (e) {
      setError('Erro ao carregar exercícios: $e');
    }
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    List<Exercise> filtered = _exercises;

    if (_selectedCategory != 'Todos') {
      filtered = filtered
          .where((exercise) => exercise.category == _selectedCategory)
          .toList();
    }

    final searchText = _searchController.text.toLowerCase().trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((exercise) {
        final name = exercise.name.toLowerCase();
        final description = exercise.description?.toLowerCase() ?? '';
        final category = exercise.category.toLowerCase();

        return name.contains(searchText) ||
            description.contains(searchText) ||
            category.contains(searchText);
      }).toList();
    }

    _filteredExercises = filtered;
    notifyListeners();
  }

  Future<bool> canDeleteExercise(int exerciseId) async {
    try {
      return await _databaseService.exercises.canDeleteExercise(exerciseId);
    } catch (e) {
      setError('Erro ao verificar se exercício pode ser deletado: $e');
      return false;
    }
  }

  Future<void> deleteExercise(Exercise exercise) async {
    try {
      await _databaseService.exercises.deleteExercise(exercise.id!);
      await loadExercises(); // Recarrega a lista
    } catch (e) {
      setError('Erro ao excluir exercício: $e');
    }
  }

  Color getCategoryColor(String category) {
    if (category == 'Todos') {
      return Colors.indigo;
    }
    return AppConstants.getMuscleGroupColor(category);
  }

  Future<void> onExerciseUpdated() async {
    await loadExercises();
  }
}
