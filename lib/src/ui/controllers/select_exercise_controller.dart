import 'package:flutter/material.dart';
import 'package:gym_craft/src/shared/constants/constants.dart';
import '../../data/services/database_service.dart';
import '../../models/exercise.dart';
import 'base_controller.dart';

class SelectExerciseController extends BaseController {
  final DatabaseService _databaseService = DatabaseService();
  final List<int> excludeExerciseIds;

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  final TextEditingController searchController = TextEditingController();

  List<Exercise> get exercises => _exercises;
  List<Exercise> get filteredExercises => _filteredExercises;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories => ['Todos', ...AppConstants.muscleGroups];

  SelectExerciseController({this.excludeExerciseIds = const []}) {
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchQuery = searchController.text;
    applyFilters();
  }

  Future<void> loadExercises() async {
    setLoading(true);
    try {
      final exercises = await _databaseService.exercises.getAllExercises();

      // Filtrar exercícios excluídos
      _exercises = exercises.where((exercise) {
        return !excludeExerciseIds.contains(exercise.id);
      }).toList();

      applyFilters();
    } catch (e) {
      setError('Erro ao carregar exercícios: $e');
    } finally {
      setLoading(false);
    }
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    applyFilters();
  }

  void applyFilters() {
    List<Exercise> filtered = _exercises;

    // Filtrar por categoria
    if (_selectedCategory != 'Todos') {
      filtered = filtered
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    // Filtrar por busca
    final searchQuery = _searchQuery.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(searchQuery) ||
                (e.description?.toLowerCase().contains(searchQuery) ?? false),
          )
          .toList();
    }

    _filteredExercises = filtered;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'Todos';
    searchController.clear();
    _searchQuery = '';
    applyFilters();
  }

  Color getCategoryColor(String category) {
    if (category == 'Todos') {
      return Colors.indigo;
    }
    return AppConstants.getMuscleGroupColor(category);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
