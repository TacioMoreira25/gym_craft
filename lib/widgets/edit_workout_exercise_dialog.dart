import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_craft/models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/exercise_image_widget.dart';
import '../widgets/ImageViewerDialog.dart';
import '../widgets/series_editor_widget.dart';

class EditWorkoutExerciseDialog extends StatefulWidget {
  final Map<String, dynamic> workoutExerciseData;
  final VoidCallback onUpdated;

  const EditWorkoutExerciseDialog({
    Key? key,
    required this.workoutExerciseData,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditWorkoutExerciseDialog> createState() =>
      _EditWorkoutExerciseDialogState();
}

class _EditWorkoutExerciseDialogState extends State<EditWorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = true;
  bool _isSaving = false;
  List<WorkoutSeries> _series = [];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.workoutExerciseData['notes'] ?? '',
    );
    _loadSeries();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    if (!mounted) return;

    try {
      final workoutExerciseId = widget.workoutExerciseData['id'];
      final seriesList = await _databaseService.series
          .getSeriesByWorkoutExercise(workoutExerciseId);

      if (mounted) {
        setState(() {
          _series = List.from(seriesList);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar séries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar séries: $e');
      }
    }
  }

  void _onSeriesChanged(List<WorkoutSeries> updatedSeries) {
    if (mounted && !_isSaving) {
      setState(() {
        _series = List.from(updatedSeries);
      });
    }
  }

  Future<void> _updateWorkoutExercise() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final data = widget.workoutExerciseData;
      final notesText = _notesController.text.trim();

      final workoutExercise = WorkoutExercise(
        id: data['id'],
        workoutId: data['workout_id'],
        exerciseId: data['exercise_id'],
        orderIndex: data['order_index'],
        notes: notesText.isEmpty ? null : notesText,
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at']),
      );

      await _databaseService.workoutExercises.updateWorkoutExercise(
        workoutExercise,
      );

      await _updateSeriesInDatabase();

      if (mounted) {
        widget.onUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Erro ao atualizar exercício: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao atualizar: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateSeriesInDatabase() async {
    final workoutExerciseId = widget.workoutExerciseData['id'];

    // Remove todas as séries existentes
    await _databaseService.series.deleteSeriesByWorkoutExercise(
      workoutExerciseId,
    );

    // Insere as novas séries com numeração correta
    for (int i = 0; i < _series.length; i++) {
      final s = _series[i];
      final newSeries = s.copyWith(
        id: null, // Reset ID para inserção
        workoutExerciseId: workoutExerciseId,
        seriesNumber: i + 1,
      );
      await _databaseService.series.insertSeries(newSeries);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.workoutExerciseData['exercise_name'];
    final workoutExerciseId = widget.workoutExerciseData['id'];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExerciseImageWidget(
                        imageUrl: widget.workoutExerciseData['image_url'] as String?,
                        category: widget.workoutExerciseData['category'] as String?,
                        borderRadius: BorderRadius.circular(8),
                        enableTap: true,
                        exerciseName: widget.workoutExerciseData['exercise_name'] as String?,
                      ),
                      const SizedBox(width: 12),

                      // Textos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Editar Exercício',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exerciseName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Categoria com ícone
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.workoutExerciseData['category'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Toque na imagem para ampliar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notas do exercício
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Notas do Exercício (opcional)',
                          hintText: 'Ex: Foco na execução, ajustar postura...',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Series Editor
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        SeriesEditorWidget(
                          // Chave estável baseada apenas no workoutExerciseId
                          key: ValueKey('series_editor_$workoutExerciseId'),
                          initialSeries: _series,
                          workoutExerciseId: workoutExerciseId,
                          onSeriesChanged: _onSeriesChanged,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (_isLoading || _isSaving)
                        ? null
                        : () {
                            if (mounted) Navigator.of(context).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_isLoading || _isSaving) ? null : _updateWorkoutExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
