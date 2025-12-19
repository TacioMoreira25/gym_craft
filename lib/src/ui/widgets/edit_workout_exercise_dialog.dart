import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercise_image_widget.dart';
import 'series_editor_widget.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/edit_workout_exercise_controller.dart';
import 'app_dialog.dart';

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
          return AppDialog(
            title: 'Editar Exercício',
            content: _buildContent(context, controller),
            actions: _buildActions(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EditWorkoutExerciseController controller,
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

  List<Widget> _buildActions(
    BuildContext context,
    EditWorkoutExerciseController controller,
  ) {
    return [
      TextButton(
        onPressed: (controller.isLoading || controller.isSaving)
            ? null
            : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: (controller.isLoading || controller.isSaving)
            ? null
            : () => _updateExercise(context, controller),
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
    ];
  }

  Future<void> _updateExercise(
    BuildContext context,
    EditWorkoutExerciseController controller,
  ) async {
    final success = await controller.updateWorkoutExercise();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop();
        SnackBarUtils.showUpdateSuccess(
          context,
          'Exercício atualizado com sucesso!',
        );
      } else if (controller.hasError) {
        SnackBarUtils.showError(context, controller.errorMessage!);
      }
    }
  }
}
