import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';
import '../services/database_service.dart';
import '../widgets/exercise_image_widget.dart';
import '../widgets/series_editor_widget.dart';

class AddWorkoutExerciseDialog extends StatefulWidget {
  final int workoutId;
  final Exercise selectedExercise;
  final VoidCallback onExerciseAdded;

  const AddWorkoutExerciseDialog({
    Key? key,
    required this.workoutId,
    required this.selectedExercise,
    required this.onExerciseAdded,
  }) : super(key: key);

  @override
  State<AddWorkoutExerciseDialog> createState() =>
      _AddWorkoutExerciseDialogState();
}

class _AddWorkoutExerciseDialogState extends State<AddWorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  List<WorkoutSeries> _series = [
    WorkoutSeries(
      workoutExerciseId: 0, // Temporário
      seriesNumber: 1,
      repetitions: 12,
      weight: 0.0,
      restSeconds: 60,
      type: SeriesType.valid,
      createdAt: DateTime.now(),
    ),
    WorkoutSeries(
      workoutExerciseId: 0, // Temporário
      seriesNumber: 2,
      repetitions: 12,
      weight: 0.0,
      restSeconds: 60,
      type: SeriesType.valid,
      createdAt: DateTime.now(),
    ),
    WorkoutSeries(
      workoutExerciseId: 0, // Temporário
      seriesNumber: 3,
      repetitions: 12,
      weight: 0.0,
      restSeconds: 60,
      type: SeriesType.valid,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onSeriesChanged(List<WorkoutSeries> updatedSeries) {
    if (mounted && !_isLoading) {
      setState(() {
        _series = List.from(updatedSeries);
      });
    }
  }

  Future<void> _addExerciseToWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nextOrder = await _databaseService.workoutExercises
          .getNextWorkoutExerciseOrder(widget.workoutId);

      final workoutExercise = WorkoutExercise(
        workoutId: widget.workoutId,
        exerciseId: widget.selectedExercise.id!,
        orderIndex: nextOrder,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final workoutExerciseId = await _databaseService.workoutExercises
          .insertWorkoutExercise(workoutExercise);

      List<WorkoutSeries> seriesList = [];
      for (int i = 0; i < _series.length; i++) {
        final s = _series[i];
        final series = s.copyWith(
          id: null, // Reset ID para inserção
          workoutExerciseId: workoutExerciseId,
          seriesNumber: i + 1,
        );
        seriesList.add(series);
      }

      await _databaseService.series.saveWorkoutExerciseSeries(
        workoutExerciseId,
        seriesList,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onExerciseAdded();
        _showSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Erro ao adicionar exercício: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.selectedExercise.name} adicionado ao treino!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outlined,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.selectedExercise.category,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (widget.selectedExercise.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              widget.selectedExercise.description!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
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
                        imageUrl: widget.selectedExercise.imageUrl,
                        category: widget.selectedExercise.category,
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(10),
                        enableTap: false,
                        exerciseName: widget.selectedExercise.name,
                      ),
                      const SizedBox(width: 12),

                      // Textos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configurar Exercício',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.selectedExercise.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
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
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),

                      // Notas do exercício
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Notas do Exercício (opcional)',
                          hintText: 'Ex: Foco na execução, ajustar postura...',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Series Editor
                      SeriesEditorWidget(
                        key: const ValueKey('add_series_editor'),
                        initialSeries: _series,
                        workoutExerciseId: 0, // Temporário para adição
                        onSeriesChanged: _onSeriesChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
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
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addExerciseToWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
