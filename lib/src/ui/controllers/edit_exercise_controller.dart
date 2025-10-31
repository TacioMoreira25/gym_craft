import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../data/services/database_service.dart';
import '../../shared/constants/constants.dart';
import '../controllers/base_controller.dart';

class EditExerciseController extends BaseController {
  final Exercise? exercise;
  final VoidCallback onUpdated;

  final DatabaseService _databaseService = DatabaseService();
  final formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController instructionsController;
  late TextEditingController imageUrlController;

  String _selectedCategory = 'Peito';

  final List<String> categories = ['Todos', ...AppConstants.muscleGroups];

  EditExerciseController({required this.exercise, required this.onUpdated}) {
    _initializeControllers();
  }

  // Getters
  String get selectedCategory => _selectedCategory;
  bool get isEditing => exercise != null;
  String get dialogTitle => isEditing ? 'Editar Exercício' : 'Novo Exercício';
  String get buttonText => isEditing ? 'Salvar' : 'Criar';
  String get successMessage => isEditing
      ? 'Exercício atualizado com sucesso!'
      : 'Exercício criado com sucesso!';
  bool get shouldShowCustomInfo =>
      isEditing && exercise != null && !exercise!.isCustom;
  bool get hasImageUrl => imageUrlController.text.isNotEmpty;

  void _initializeControllers() {
    nameController = TextEditingController(text: exercise?.name ?? '');
    descriptionController = TextEditingController(
      text: exercise?.description ?? '',
    );
    instructionsController = TextEditingController(
      text: exercise?.instructions ?? '',
    );
    imageUrlController = TextEditingController(text: exercise?.imageUrl ?? '');

    if (exercise != null) {
      _selectedCategory = exercise!.category;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    instructionsController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  // Seleção de categoria
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Atualização de imagem para preview
  void onImageUrlChanged() {
    notifyListeners();
  }

  // Salvar exercício
  Future<bool> saveExercise() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    setLoading(true);

    try {
      final exerciseToSave = Exercise(
        id: exercise?.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        category: _selectedCategory,
        instructions: instructionsController.text.trim().isEmpty
            ? null
            : instructionsController.text.trim(),
        imageUrl: imageUrlController.text.trim().isEmpty
            ? null
            : imageUrlController.text.trim(),
        createdAt: exercise?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await _databaseService.exercises.updateExercise(exerciseToSave);
      } else {
        await _databaseService.exercises.insertExercise(exerciseToSave);
      }

      onUpdated();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Erro ao ${isEditing ? 'atualizar' : 'criar'} exercício: $e');
      return false;
    }
  }
}
