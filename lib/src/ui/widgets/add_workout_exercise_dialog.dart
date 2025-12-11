import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import 'exercise_image_widget.dart';
import 'series_editor_widget.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/add_workout_exercise_controller.dart';

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
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, controller),
                  _buildContent(context, controller),
                  _buildActions(context, controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) {
    final theme = Theme.of(context);

    return Container(
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
                      controller.exerciseName,
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
    );
  }

  Widget _buildContent(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

  Widget _buildActions(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) {
    final theme = Theme.of(context);

    return Container(
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
            onPressed: controller.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : () => _saveExercise(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
        ],
      ),
    );
  }

  Future<void> _saveExercise(
    BuildContext context,
    AddWorkoutExerciseController controller,
  ) async {
    final success = await controller.addExerciseToWorkout();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        SnackBarUtils.showSuccess(context, controller.successMessage);
      } else if (controller.hasError) {
        SnackBarUtils.showError(context, controller.errorMessage!);
      }
    }
  }
}
