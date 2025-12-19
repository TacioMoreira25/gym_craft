import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import 'exercise_image_widget.dart';
import 'series_editor_widget.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/add_workout_exercise_controller.dart';
import 'app_dialog.dart';

class AddWorkoutExerciseDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddWorkoutExerciseController(
        workoutId: workoutId,
        selectedExercise: selectedExercise,
        onExerciseAdded: onExerciseAdded,
      ),
      child: Consumer<AddWorkoutExerciseController>(
        builder: (context, controller, child) {
          return AppDialog(
            title: 'Configurar Exercício',
            content: _buildContent(context, controller),
            actions: _buildActions(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) {
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ExerciseImageWidget(
                    imageUrl: controller.exerciseImageUrl,
                    category: controller.exerciseCategory,
                    width: 50,
                    height: 50,
                    borderRadius: BorderRadius.circular(10),
                    enableTap: false,
                    exerciseName: controller.exerciseName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.exerciseName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(context, controller),
              const SizedBox(height: 16),

              // Notas do exercício
              TextFormField(
                controller: controller.notesController,
                maxLines: 3,
                enabled: !controller.isLoading,
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
                initialSeries: controller.series,
                workoutExerciseId: 0, // Temporário para adição
                onSeriesChanged: controller.onSeriesChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) {
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
                controller.exerciseCategory,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (controller.hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              controller.exerciseDescription!,
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

  List<Widget> _buildActions(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) {
    return [
      TextButton(
        onPressed: controller.isLoading
            ? null
            : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () => _saveExercise(context, controller),
        child: controller.isLoading
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
    ];
  }

  Future<void> _saveExercise(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) async {
    final success = await controller.addExerciseToWorkout();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        SnackBarUtils.showAddSuccess(context, controller.successMessage);
      } else if (controller.hasError) {
        SnackBarUtils.showError(context, controller.errorMessage!);
      }
    }
  }
}
