import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../data/services/database_service.dart';
import '../../shared/utils/snackbar_utils.dart';
import 'app_dialog.dart';

class EditWorkoutDialog extends StatefulWidget {
  final Workout workout;
  final VoidCallback onUpdated;

  const EditWorkoutDialog({
    Key? key,
    required this.workout,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditWorkoutDialog> createState() => _EditWorkoutDialogState();
}

class _EditWorkoutDialogState extends State<EditWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _descriptionController = TextEditingController(
      text: widget.workout.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedWorkout = Workout(
        id: widget.workout.id,
        routineId: widget.workout.routineId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: widget.workout.createdAt,
      );

      await _databaseService.workouts.updateWorkout(updatedWorkout);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdated();
        SnackBarUtils.showUpdateSuccess(
          context,
          'Treino atualizado com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao atualizar treino: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Editar Treino',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Treino',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _updateWorkout,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
