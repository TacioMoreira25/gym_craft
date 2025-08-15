import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../screens/select_exercise_screen.dart';
import '../widgets/add_workout_exercise_dialog.dart';
import '../utils/constants.dart';
import '../widgets/edit_workout_exercise_dialog.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _workoutExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutExercises();
  }

  Future<void> _loadWorkoutExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _databaseHelper.getWorkoutExercises(widget.workout.id!);
      setState(() {
        _workoutExercises = exercises;
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

  Future<void> _addExercise() async {
    final Exercise? selectedExercise = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SelectExerciseScreen(),
      ),
    );

    if (selectedExercise != null) {
      await showDialog(
        context: context,
        builder: (context) => AddWorkoutExerciseDialog(
          workoutId: widget.workout.id!,
          selectedExercise: selectedExercise,
          onExerciseAdded: () {
            _loadWorkoutExercises();
          },
        ),
      );
    }
  }

  void _editWorkoutExercise(Map<String, dynamic> exerciseData) {
  showDialog(
    context: context,
    builder: (context) => EditWorkoutExerciseDialog(
      workoutExerciseData: exerciseData,
      onUpdated: _loadWorkoutExercises,
    ),
  );
}

  void _deleteExercise(Map<String, dynamic> exerciseData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja remover "${exerciseData['exercise_name']}" deste treino?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseHelper.deleteWorkoutExercise(exerciseData['id']);
                _loadWorkoutExercises();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exercício removido do treino!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Remover'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _addExercise();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header com info do treino
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Exercícios',
                            _workoutExercises.length.toString(),
                            Icons.fitness_center,
                          ),
                          _buildStatCard(
                            'Séries Total',
                            _workoutExercises.fold<int>(
                              0, 
                              (sum, ex) => sum + (ex['sets'] as int? ?? 0)
                            ).toString(),
                            Icons.repeat,
                          ),
                          _buildStatCard(
                            'Tempo Est.',
                            '${_calculateEstimatedTime()}min',
                            Icons.timer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de exercícios
                Expanded(
                  child: _workoutExercises.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _workoutExercises.length,
                          itemBuilder: (context, index) {
                            final exerciseData = _workoutExercises[index];
                            return _buildExerciseCard(exerciseData, index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
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
              Icons.fitness_center,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum exercício adicionado',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para adicionar seu primeiro exercício',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Exercício'),
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

  Widget _buildExerciseCard(Map<String, dynamic> exerciseData, int index) {
    final muscleGroupColor = AppConstants.categoryColors[exerciseData['muscle_group']] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do exercício
            Row(
              children: [
                // Ícone e ordem
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: muscleGroupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: muscleGroupColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Nome e grupo muscular
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseData['exercise_name'] ?? 'Exercício',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        exerciseData['muscle_group'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: muscleGroupColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu de opções
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
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
                          Text('Remover', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editWorkoutExercise(exerciseData);
                        break;
                      case 'delete':
                        _deleteExercise(exerciseData);
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Configurações do treino
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildConfigItem(
                    Icons.repeat,
                    'Séries',
                    exerciseData['sets']?.toString() ?? '0',
                  ),
                  const SizedBox(width: 16),
                  _buildConfigItem(
                    Icons.fitness_center,
                    'Reps',
                    exerciseData['reps']?.toString() ?? '0',
                  ),
                  if (exerciseData['weight'] != null) ...[
                    const SizedBox(width: 16),
                    _buildConfigItem(
                      Icons.monitor_weight,
                      'Peso',
                      '${exerciseData['weight']}kg',
                    ),
                  ],
                  if (exerciseData['rest_time'] != null) ...[
                    const SizedBox(width: 16),
                    _buildConfigItem(
                      Icons.timer,
                      'Descanso',
                      '${exerciseData['rest_time']}s',
                    ),
                  ],
                ],
              ),
            ),
            
            // Notas (se houver)
            if (exerciseData['notes'] != null && exerciseData['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exerciseData['notes'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  int _calculateEstimatedTime() {
    int totalTime = 0;
    for (final exercise in _workoutExercises) {
      final sets = exercise['sets'] as int? ?? 0;
      final restTime = exercise['rest_time'] as int? ?? 60;
      
      // Tempo estimado: 30s por série + tempo de descanso
      totalTime += (sets * 30) + ((sets - 1) * restTime);
    }
    return (totalTime / 60).ceil(); // Converte para minutos
  }
}