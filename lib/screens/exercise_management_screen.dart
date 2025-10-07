import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../widgets/edit_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';
import '../mixins/filter_mixin.dart';
import '../utils/snackbar_utils.dart';
import '../utils/constants.dart';

class ExerciseManagementScreen extends StatefulWidget {
  const ExerciseManagementScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseManagementScreen> createState() =>
      _ExerciseManagementScreenState();
}

class _ExerciseManagementScreenState extends State<ExerciseManagementScreen>
    with FilterMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedCategory = 'Todos';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Implementação do FilterMixin
  @override
  List<Exercise> get allExercises => _exercises;

  @override
  List<Exercise> get filteredExercises => _filteredExercises;

  @override
  String get selectedCategory => _selectedCategory;

  @override
  TextEditingController get searchController => _searchController;

  @override
  set filteredExercises(List<Exercise> value) => _filteredExercises = value;

  @override
  set selectedCategory(String value) => _selectedCategory = value;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _databaseService.exercises.getAllExercises();
      setState(() {
        _exercises = exercises;
        applyFilters(); // Usando método do FilterMixin
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showOperationError(
          context,
          'carregar exercícios',
          e.toString(),
        );
      }
    }
  }

  void _editExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) =>
          EditExerciseDialog(exercise: exercise, onUpdated: _loadExercises),
    );
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    // Verificar se pode deletar
    final canDelete = await _databaseService.exercises.canDeleteExercise(
      exercise.id!,
    );

    if (!canDelete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não é possível excluir este exercício pois ele está sendo usado em treinos',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Confirmar exclusão
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o exercício "${exercise.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.exercises.deleteExercise(exercise.id!);
        _loadExercises();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercício excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir exercício: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) =>
          EditExerciseDialog(exercise: null, onUpdated: _loadExercises),
    );
  }

  Color _getCategoryColor(String category) {
    if (category == 'Todos') {
      return Colors.indigo;
    }
    return AppConstants.getMuscleGroupColor(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Gerenciar Exercícios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _addExercise,
            icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
            tooltip: 'Adicionar Exercício',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Campo de busca
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar exercícios...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => applyFilters(),
                ),
                const SizedBox(height: 12),

                // Filtro de categoria
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                              applyFilters();
                            });
                          },
                          selectedColor: _getCategoryColor(
                            category,
                          ).withOpacity(0.2),
                          checkmarkColor: _getCategoryColor(category),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? _getCategoryColor(category)
                                : Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de exercícios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum exercício encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque no + para adicionar exercícios',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ExerciseImageWidget(
                            imageUrl: exercise.imageUrl,
                            width: 50,
                            height: 50,
                          ),
                          title: Text(
                            exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (exercise.description?.isNotEmpty == true)
                                Text(
                                  exercise.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppConstants.getMuscleGroupColor(
                                        exercise.category,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 4),
                                        Text(
                                          exercise.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                AppConstants.getMuscleGroupColor(
                                                  exercise.category,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (exercise.isCustom) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Personalizado',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editExercise(exercise);
                                  break;
                                case 'delete':
                                  _deleteExercise(exercise);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _editExercise(exercise),
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
