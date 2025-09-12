import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
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
  final DatabaseService _databaseService = DatabaseService();
  List<WorkoutExercise> _workoutExercises = [];
  bool _isLoading = true;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutExercises();
  }

  Future<void> _loadWorkoutExercises() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final exercises = await _databaseService.workoutExercises
          .getWorkoutExercisesWithDetails(widget.workout.id!);

      // Aplicar ordem salva se existir
      final orderedExercises = await _applyCustomOrder(exercises);

      if (mounted) {
        setState(() {
          _workoutExercises = orderedExercises;
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

  Future<List<WorkoutExercise>> _applyCustomOrder(
    List<WorkoutExercise> exercises,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString(
        'exercise_order_${widget.workout.id}',
      );

      if (savedOrder == null) {
        return exercises;
      }

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<WorkoutExercise> orderedExercises = [];

      for (int id in orderIds) {
        WorkoutExercise? exercise = exercises.firstWhere(
          (e) => e.id == id,
          orElse: () => null as WorkoutExercise,
        );
        if (exercise != null) {
          orderedExercises.add(exercise);
        }
      }

      for (WorkoutExercise exercise in exercises) {
        if (!orderedExercises.any((e) => e.id == exercise.id)) {
          orderedExercises.add(exercise);
        }
      }

      return orderedExercises;
    } catch (e) {
      return exercises;
    }
  }

  Future<void> _saveExerciseOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> exerciseIds = _workoutExercises
          .map((exercise) => exercise.id!)
          .toList();
      await prefs.setString(
        'exercise_order_${widget.workout.id}',
        jsonEncode(exerciseIds),
      );
    } catch (e) {
      print('Erro ao salvar ordem dos exercícios: $e');
    }
  }

  Future<void> _addExercise() async {
    final Exercise? selectedExercise = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SelectExerciseScreen()),
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
      'image_url': workoutExercise.exercise?.imageUrl,
    };

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => EditWorkoutExerciseDialog(
        workoutExerciseData: exerciseData,
        onUpdated: () {},
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
          content: Text(
            'Tem certeza que deseja remover "${workoutExercise.exercise?.name ?? 'este exercício'}" deste treino?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.workoutExercises.deleteWorkoutExercise(
                  workoutExercise.id!,
                );
                if (mounted) {
                  _loadWorkoutExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exercício removido do treino!'),
                      backgroundColor: Colors.red,
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

  void _exitReorderMode() {
    setState(() => _isReorderMode = false);
  }

  // Função para verificar se uma string é válida (não nula, não vazia, sem apenas espaços/caracteres especiais)
  bool _isValidText(String? text) {
    if (text == null) return false;

    // Remove espaços e caracteres de controle/invisíveis
    final cleanText = text
        .replaceAll(RegExp(r'[\s\u0000-\u001F\u007F-\u009F\uFEFF\u200B-\u200D\uFFF0-\uFFFF]'), '');

    return cleanText.isNotEmpty;
  }

  // Função para formatar tempo de descanso
  String _formatRestTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}min ${remainingSeconds}s';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isReorderMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isReorderMode) {
          _exitReorderMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isReorderMode ? 'Reordenar Exercícios' : widget.workout.name,
          ),
          elevation: 0,
          leading: _isReorderMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitReorderMode,
                )
              : null,
          actions: [
            if (!_isReorderMode && _workoutExercises.isNotEmpty)
              IconButton(
                onPressed: () {
                  setState(() => _isReorderMode = true);
                },
                icon: const Icon(Icons.reorder),
                tooltip: 'Reordenar Exercícios',
              ),
            if (_isReorderMode)
              IconButton(
                onPressed: () async {
                  await _saveExerciseOrder();
                  _exitReorderMode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ordem dos exercícios salva!'),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                tooltip: 'Salvar Ordem',
              ),
            if (!_isReorderMode)
              IconButton(icon: const Icon(Icons.add), onPressed: _addExercise),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (!_isReorderMode) ...[
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
                  ],

                  // Lista de exercícios
                  Expanded(
                    child: _workoutExercises.isEmpty
                        ? _buildEmptyState()
                        : _isReorderMode
                        ? _buildReorderableExercisesList()
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
      ),
    );
  }

  Widget _buildReorderableExercisesList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reordenar Exercícios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arraste os exercícios para reordená-los',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _workoutExercises.length,
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final WorkoutExercise item = _workoutExercises.removeAt(
                    oldIndex,
                  );
                  _workoutExercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final workoutExercise = _workoutExercises[index];
                return _buildReorderableExerciseCard(workoutExercise, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableExerciseCard(
    WorkoutExercise workoutExercise,
    int index,
  ) {
    final exercise = workoutExercise.exercise;
    final muscleGroupColor =
        AppConstants.categoryColors[exercise?.category] ?? Colors.grey;

    return Card(
      key: ValueKey(workoutExercise.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone de arrastar
            Icon(Icons.drag_handle, color: Colors.grey[500]),
            const SizedBox(width: 12),

            ExerciseImageWidget(
              imageUrl: exercise?.imageUrl,
              width: 50,
              height: 50,
              category: exercise?.category,
              borderRadius: BorderRadius.circular(8),
              enableTap: false, // Desabilitado no modo reordenação
              exerciseName: exercise?.name ?? 'Exercício',
            ),
            const SizedBox(width: 12),

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
                ],
              ),
            ),
          ],
        ),
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
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
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
            Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
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
              style: TextStyle(color: Colors.grey[500]),
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
    final muscleGroupColor =
        AppConstants.categoryColors[exercise?.category] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do exercício
            Row(
              children: [
                // Imagem do exercício
                ExerciseImageWidget(
                  imageUrl: exercise?.imageUrl,
                  width: 60,
                  height: 60,
                  category: exercise?.category,
                  borderRadius: BorderRadius.circular(8),
                  enableTap: true,
                  exerciseName: exercise?.name ?? 'Exercício',
                ),
                const SizedBox(width: 12),

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: series.asMap().entries.map((entry) {
                  final index = entry.key;
                  final s = entry.value;
                  final seriesTypeColor = AppConstants.getSeriesTypeColor(
                    s.type,
                  );
                  final seriesTypeName = AppConstants.getSeriesTypeName(s.type);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: seriesTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: seriesTypeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppConstants.getSeriesTypeIcon(s.type),
                              size: 16,
                              color: seriesTypeColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _buildSeriesText(s, index + 1, seriesTypeName),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: seriesTypeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isValidText(s.notes)) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s.notes!.trim(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            if (_isValidText(workoutExercise.notes)) ...[
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
                        workoutExercise.notes!.trim(),
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

  String _buildSeriesText(
    WorkoutSeries series,
    int seriesNumber,
    String typeName,
  ) {
    switch (series.type) {
      case SeriesType.rest:
        return '$seriesNumberª $typeName: ${_formatRestTime(series.restSeconds ?? 0)}';

      case SeriesType.warmup:
      case SeriesType.recognition:
        return '$seriesNumberª $typeName: ${series.repetitions ?? 0} reps';

      default:
        String text =
            '$seriesNumberª $typeName: ${series.repetitions ?? 0} reps';
        if (series.weight != null && series.weight! > 0) {
          text += ' | ${series.weight}kg';
        }
        if (series.restSeconds != null && series.restSeconds! > 0) {
          text += ' | ${_formatRestTime(series.restSeconds!)} desc';
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
          totalTime += 30;
          if (s.restSeconds != null) {
            totalTime += s.restSeconds!;
          }
        }
      }
    }
    return (totalTime / 60).ceil();
  }
}
