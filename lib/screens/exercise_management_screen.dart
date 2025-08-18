import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../database/database_helper.dart';
import '../widgets/edit_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';

class ExerciseManagementScreen extends StatefulWidget {
  const ExerciseManagementScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseManagementScreen> createState() => _ExerciseManagementScreenState();
}

class _ExerciseManagementScreenState extends State<ExerciseManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedCategory = 'Todos';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
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
      final exercises = await _dbHelper.getAllExercises();
      setState(() {
        _exercises = exercises;
        _filterExercises();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar exercícios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterExercises() {
    List<Exercise> filtered = _exercises;

    // Filtrar por categoria
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Filtrar por busca
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.name.toLowerCase().contains(searchQuery) ||
        (e.description?.toLowerCase().contains(searchQuery) ?? false)
      ).toList();
    }

    setState(() {
      _filteredExercises = filtered;
    });
  }

  void _editExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => EditExerciseDialog(
        exercise: exercise,
        onUpdated: _loadExercises,
      ),
    );
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    // Verificar se pode deletar
    final canDelete = await _dbHelper.canDeleteExercise(exercise.id!);
    
    if (!canDelete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não é possível excluir este exercício pois ele está sendo usado em treinos'),
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
        content: Text('Deseja realmente excluir o exercício "${exercise.name}"?'),
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
        await _dbHelper.deleteExercise(exercise.id!);
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
      builder: (context) => EditExerciseDialog(
        exercise: null, // null para criar novo
        onUpdated: _loadExercises,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Exercícios'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
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
                  onChanged: (_) => _filterExercises(),
                ),
                const SizedBox(height: 12),
                
                // Filtro de categoria
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                              _filterExercises();
                            });
                          },
                          selectedColor: Colors.indigo[100],
                          checkmarkColor: Colors.indigo[700],
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
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
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
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          exercise.category,
                                          style: const TextStyle(fontSize: 12),
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
                                        Icon(Icons.delete, size: 20, color: Colors.red),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'peito':
        return Icons.fitness_center;
      case 'costas':
        return Icons.back_hand;
      case 'ombros':
        return Icons.keyboard_arrow_up;
      case 'Bíceps':
        return Icons.sports_martial_arts;
      case 'Tríceps':
        return Icons.sports_martial_arts;
      case 'Quadricps':
        return Icons.directions_run;
      case 'Posterior':
        return Icons.directions_run;
      case 'Glúteos':
        return Icons.directions_run;
      case 'Panturrilhas':
        return Icons.directions_run;
      case 'abdomen':
        return Icons.center_focus_strong;
      case 'cardio':
        return Icons.favorite;
      case 'Antebraços':
        return Icons.sports_martial_arts;
      default:
        return Icons.sports_gymnastics;
    }
  }
}