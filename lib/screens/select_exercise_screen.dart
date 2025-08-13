import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../utils/constants.dart';
import 'add_exercise_screen.dart';

class SelectExerciseScreen extends StatefulWidget {
  const SelectExerciseScreen({super.key});

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedMuscleGroupFilter = 'Todos';
  bool _isLoading = true;

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
      final exercises = await _databaseHelper.getAllExercises();
      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
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
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final matchesSearch = exercise.name.toLowerCase().contains(query);
        final matchesMuscleGroup = _selectedMuscleGroupFilter == 'Todos' || 
                                   exercise.muscleGroup == _selectedMuscleGroupFilter;
        return matchesSearch && matchesMuscleGroup;
      }).toList();
    });
  }

  Future<void> _createNewExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddExerciseScreen(),
      ),
    );
    
    if (result != null && result is Exercise) {
      // Se exercício foi criado, recarrega lista e auto-seleciona
      await _loadExercises();
      Navigator.of(context).pop(result);
    } else {
      // Se só criou o exercício, apenas recarrega a lista
      _loadExercises();
    }
  }

  void _selectExercise(Exercise exercise) {
    // Retorna o exercício selecionado para a tela anterior
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroupOptions = ['Todos'] + AppConstants.muscleGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Exercício'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _isLoading
              ? const LinearProgressIndicator()
              : const SizedBox(height: 4),
        ),
      ),
      body: Column(
        children: [
          // Header com busca e filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Info do treino
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adicionando exercício',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botão criar novo exercício
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createNewExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Novo Exercício'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Busca
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterExercises(),
                  decoration: InputDecoration(
                    hintText: 'Buscar exercícios...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Filtro por grupo muscular
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: muscleGroupOptions.length,
                    itemBuilder: (context, index) {
                      final group = muscleGroupOptions[index];
                      final isSelected = _selectedMuscleGroupFilter == group;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroupFilter = group;
                              _filterExercises();
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: group == 'Todos' 
                              ? Colors.blue[100]
                              : AppConstants.muscleGroupColors[group]?.withOpacity(0.2),
                          checkmarkColor: group == 'Todos' 
                              ? Colors.blue[700]
                              : AppConstants.muscleGroupColors[group],
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
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final muscleGroupColor = AppConstants.muscleGroupColors[exercise.muscleGroup] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectExercise(exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone do grupo muscular
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: muscleGroupColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getExerciseIcon(exercise.muscleGroup),
                  color: muscleGroupColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações do exercício
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscleGroup,
                      style: TextStyle(
                        fontSize: 14,
                        color: muscleGroupColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (exercise.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Indicador de seleção
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecionar',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedMuscleGroupFilter != 'Todos'
                  ? 'Nenhum exercício encontrado'
                  : 'Nenhum exercício na biblioteca',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _selectedMuscleGroupFilter != 'Todos'
                  ? 'Tente ajustar os filtros ou criar um novo exercício'
                  : 'Comece criando seu primeiro exercício',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewExercise,
              icon: const Icon(Icons.add),
              label: const Text('Criar Primeiro Exercício'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'peito':
        return Icons.favorite;
      case 'costas':
        return Icons.view_column;
      case 'pernas':
        return Icons.directions_run;
      case 'ombros':
        return Icons.accessibility_new;
      case 'braços':
        return Icons.sports_handball;
      case 'core':
        return Icons.grain;
      case 'cardio':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }
}