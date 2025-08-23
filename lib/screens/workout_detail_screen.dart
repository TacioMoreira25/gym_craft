import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';
import '../screens/select_exercise_screen.dart';
import '../widgets/add_workout_exercise_dialog.dart';
import '../utils/constants.dart';
import '../widgets/edit_workout_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';
import '../widgets/ImageViewerDialog.dart'; 

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<WorkoutExercise> _workoutExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutExercises();
  }

  Future<void> _loadWorkoutExercises() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final exercises = await _databaseHelper.getWorkoutExercisesWithDetails(widget.workout.id!);
      if (mounted) {
        setState(() {
          _workoutExercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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

    if (selectedExercise != null && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AddWorkoutExerciseDialog(
          workoutId: widget.workout.id!,
          selectedExercise: selectedExercise,
          onExerciseAdded: () {
            if (mounted) _loadWorkoutExercises();
          },
        ),
      );
    }
  }

  Future<void> _editWorkoutExercise(WorkoutExercise workoutExercise) async {
    final exerciseData = {
      'id': workoutExercise.id,
      'workout_id': workoutExercise.workoutId,
      'exercise_id': workoutExercise.exerciseId,
      'order_index': workoutExercise.orderIndex,
      'notes': workoutExercise.notes,
      'created_at': workoutExercise.createdAt.millisecondsSinceEpoch,
      'exercise_name': workoutExercise.exercise?.name ?? 'Exercício',
      'category': workoutExercise.exercise?.category ?? '',
      'description': workoutExercise.exercise?.description ?? '',
      'instructions': workoutExercise.exercise?.instructions ?? '',
      'image_url': workoutExercise.exercise?.imageUrl, // ADICIONE ESTA LINHA
    };

    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => EditWorkoutExerciseDialog(
        workoutExerciseData: exerciseData,
        onUpdated: () {}, // Callback vazio
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      await _loadWorkoutExercises();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteExercise(WorkoutExercise workoutExercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja remover "${workoutExercise.exercise?.name ?? 'este exercício'}" deste treino?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseHelper.deleteWorkoutExercise(workoutExercise.id!);
                if (mounted) {
                  _loadWorkoutExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exercício removido do treino!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remover'),
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
            onPressed: _addExercise,
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
                            _getTotalSeries().toString(),
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
                            final workoutExercise = _workoutExercises[index];
                            return _buildExerciseCard(workoutExercise, index);
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
        const SizedBox(width: 8),
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

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, int index) {
    final exercise = workoutExercise.exercise;
    final series = workoutExercise.series;
    final muscleGroupColor = AppConstants.categoryColors[exercise?.category] ?? Colors.grey;
    
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
                // Imagem do exercício (ATUALIZADA COM FUNCIONALIDADE DE CLIQUE)
                ExerciseImageWidget(
                  imageUrl: exercise?.imageUrl,
                  width: 60,
                  height: 60,
                  category: exercise?.category,
                  borderRadius: BorderRadius.circular(8),
                  enableTap: true, // Habilita o clique
                  exerciseName: exercise?.name ?? 'Exercício', // Nome do exercício
                ),
                const SizedBox(width: 12),
                
                // Número do exercício (círculo menor)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: muscleGroupColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: muscleGroupColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: muscleGroupColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                        exercise?.name ?? 'Exercício',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: muscleGroupColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise?.category ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: muscleGroupColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // ADICIONE ESTA DICA VISUAL ABAIXO DA CATEGORIA
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 10,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Toque na imagem para ampliar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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
                        _editWorkoutExercise(workoutExercise);
                        break;
                      case 'delete':
                        _deleteExercise(workoutExercise);
                        break;
                    }
                  },
                ),
              ],
            ),

            // Detalhes das séries
            if (series.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Séries configuradas:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: series.asMap().entries.map((entry) {
                  final index = entry.key;
                  final s = entry.value;
                  final seriesTypeColor = AppConstants.getSeriesTypeColor(s.type);
                  final seriesTypeName = AppConstants.getSeriesTypeName(s.type);
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: seriesTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: seriesTypeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppConstants.getSeriesTypeIcon(s.type),
                          size: 12,
                          color: seriesTypeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _buildSeriesText(s, index + 1, seriesTypeName),
                          style: TextStyle(
                            fontSize: 12,
                            color: seriesTypeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Notas (se houver)
            if (workoutExercise.notes != null && workoutExercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                        workoutExercise.notes!,
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

  String _buildSeriesText(WorkoutSeries series, int seriesNumber, String typeName) {
    switch (series.type) {
      case SeriesType.rest:
        return '$seriesNumberª $typeName: ${series.restSeconds ?? 0}s';
      
      case SeriesType.warmup:
      case SeriesType.recognition:
        return '$seriesNumberª $typeName: ${series.repetitions ?? 0} reps';
      
      default:
        String text = '$seriesNumberª $typeName: ${series.repetitions ?? 0} reps';
        if (series.weight != null && series.weight! > 0) {
          text += ' | ${series.weight}kg';
        }
        if (series.restSeconds != null && series.restSeconds! > 0) {
          text += ' | ${series.restSeconds}s desc';
        }
        return text;
    }
  }

  int _getTotalSeries() {
    return _workoutExercises.fold<int>(0, (sum, ex) => sum + ex.series.length);
  }

  int _calculateEstimatedTime() {
    int totalTime = 0;
    for (final workoutExercise in _workoutExercises) {
      final series = workoutExercise.series;
      
      for (final s in series) {
        if (s.type == SeriesType.rest) {
          totalTime += s.restSeconds ?? 30;
        } else {
          totalTime += 30; // Tempo estimado de execução
          if (s.restSeconds != null) {
            totalTime += s.restSeconds!; // Tempo de descanso
          }
        }
      }
    }
    return (totalTime / 60).ceil(); // Converte para minutos
  }
}