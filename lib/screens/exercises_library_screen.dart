import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../data/database_helper.dart';
import '../models/exercise.dart';
import '../utils/constants.dart';
import 'package:sqflite/sqflite.dart';
import '../widgets/edit_exercise_dialog.dart';

class ExercisesLibraryScreen extends StatefulWidget {
  const ExercisesLibraryScreen({super.key});

  @override
  _ExercisesLibraryScreenState createState() => _ExercisesLibraryScreenState();
}

class _ExercisesLibraryScreenState extends State<ExercisesLibraryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  final List<String> _categoryFilter = ['Todos', ...AppConstants.muscleGroups];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);

    final exercises = await _databaseService.exercises.getAllExercises();

    setState(() {
      _allExercises = exercises;
      _filteredExercises = exercises;
      _isLoading = false;
    });
  }

  void _filterExercises() {
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final matchesSearch =
            exercise.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (exercise.description?.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ?? false);

        final matchesCategoty =
            _selectedCategory == 'Todos' ||
            exercise.category == _selectedCategory;

        return matchesSearch && matchesCategoty;
      }).toList();
    });
  }

  // Método para editar exercício
  void _editExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) =>
          EditExerciseDialog(exercise: exercise, onUpdated: _loadExercises),
    );
  }

  // Método para deletar exercício
  void _showDeleteConfirmation(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja excluir o exercício:'),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação irá remover o exercício de todos os treinos que o utilizam.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _databaseService.exercises.deleteExercise(exercise.id!);
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadExercises();
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblioteca de Exercícios'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Barra de pesquisa e filtros
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar exercícios...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterExercises();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => _filterExercises(),
                ),
                SizedBox(height: 12),

                // Filtro por grupo muscular
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryFilter.map((group) {
                      final isSelected = group == _selectedCategory;
                      final color = group == 'Todos'
                          ? Colors.grey[700]
                          : AppConstants.categoryColors[group];

                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = group;
                            });
                            _filterExercises();
                          },
                          selectedColor: color?.withOpacity(0.2),
                          checkmarkColor: color,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? color ?? Colors.grey
                                : Colors.grey[300]!,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Informações dos resultados
          if (!_isLoading)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${_filteredExercises.length} exercícios encontrados',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Spacer(),
                ],
              ),
            ),

          // Lista de exercícios
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                ? _buildEmptyState()
                : _buildExercisesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Nenhum exercício encontrado'
                  : 'Nenhum resultado para "${_searchController.text}"',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Tente ajustar sua pesquisa ou filtros',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
            if (_selectedCategory != 'Todos') ...[
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'Todos';
                  });
                  _filterExercises();
                },
                child: Text('Limpar filtro de grupo muscular'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return RefreshIndicator(
      onRefresh: _loadExercises,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredExercises.length,
        itemBuilder: (context, index) {
          final exercise = _filteredExercises[index];
          return _buildExerciseCard(exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final color = AppConstants.categoryColors[exercise.category] ?? Colors.grey;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(
            AppConstants.getMuscleGroupIcon(exercise.category),
            color: color,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                exercise.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (exercise.isCustom) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                exercise.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Spacer(),
            Text(
              _formatDate(exercise.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        // CORRIGIDO: ADICIONANDO O TRAILING COM BOTÕES DE EDIÇÃO
        trailing: exercise.isCustom
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editExercise(exercise);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(exercise);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blue),
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
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Padrão',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descrição
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Descrição:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (exercise.description?.isNotEmpty == true) ...[
                        SizedBox(height: 4),
                        Text(
                          exercise.description!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),

                // Instruções
                if (exercise.instructions != null &&
                    exercise.instructions!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Instruções:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          exercise.instructions!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Estatísticas de uso
                SizedBox(height: 16),
                FutureBuilder<int>(
                  future: _getExerciseUsageCount(exercise.id!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final usageCount = snapshot.data!;
                      return Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Usado em $usageCount treino${usageCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            if (exercise.isCustom) ...[
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue[600],
                                ),
                                onPressed: () => _editExercise(exercise),
                                tooltip: 'Editar exercício',
                                constraints: BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.all(4),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red[600],
                                ),
                                onPressed: () =>
                                    _showDeleteConfirmation(exercise),
                                tooltip: 'Excluir exercício',
                                constraints: BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.all(4),
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getExerciseUsageCount(int exerciseId) async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT workout_id) as count
      FROM workout_exercises
      WHERE exercise_id = ?
    ''',
      [exerciseId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
