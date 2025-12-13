import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercise_image_widget.dart';
import 'series_editor_widget.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/edit_workout_exercise_controller.dart';

class EditWorkoutExerciseDialog extends StatelessWidget {
  final Map<String, dynamic> workoutExerciseData;
  final VoidCallback onUpdated;

  const EditWorkoutExerciseDialog({
    Key? key,
    required this.workoutExerciseData,
    required this.onUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditWorkoutExerciseController(
        workoutExerciseData: workoutExerciseData,
        onUpdated: onUpdated,
      ),
      child: Consumer<EditWorkoutExerciseController>(
        builder: (context, controller, child) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
    EditWorkoutExerciseController controller,
  ) {
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
                      'Editar Exercício',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.exerciseName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    EditWorkoutExerciseController controller,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notas do exercício
              TextFormField(
                controller: controller.notesController,
                maxLines: 3,
                enabled: !controller.isSaving,
                decoration: const InputDecoration(
                  labelText: 'Notas do Exercício (opcional)',
                  hintText: 'Ex: Foco na execução, ajustar postura...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Series Editor ou loading
              if (controller.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (controller.hasError)
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.loadSeries(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              else
                SeriesEditorWidget(
                  key: ValueKey(
                    'series_editor_${controller.workoutExerciseId}',
                  ),
                  initialSeries: controller.series,
                  workoutExerciseId: controller.workoutExerciseId,
                  onSeriesChanged: controller.onSeriesChanged,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    EditWorkoutExerciseController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            onPressed: (controller.isLoading || controller.isSaving)
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: (controller.isLoading || controller.isSaving)
                ? null
                : () => _updateExercise(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: controller.isSaving
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

  Future<void> _updateExercise(
    BuildContext context,
    EditWorkoutExerciseController controller,
  ) async {
    final success = await controller.updateWorkoutExercise();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else if (controller.hasError) {
        SnackBarUtils.showError(context, controller.errorMessage!);
      }
    }
  }
}
