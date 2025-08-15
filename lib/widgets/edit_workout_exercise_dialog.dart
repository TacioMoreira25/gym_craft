import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise.dart';
import '../database/database_helper.dart';

class EditWorkoutExerciseDialog extends StatefulWidget {
  final Map<String, dynamic> workoutExerciseData;
  final VoidCallback onUpdated;

  const EditWorkoutExerciseDialog({
    Key? key,
    required this.workoutExerciseData,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditWorkoutExerciseDialog> createState() => _EditWorkoutExerciseDialogState();
}

class _EditWorkoutExerciseDialogState extends State<EditWorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;
  late TextEditingController _notesController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.workoutExerciseData;
    _setsController = TextEditingController(text: data['sets'].toString());
    _repsController = TextEditingController(text: data['reps'].toString());
    _weightController = TextEditingController(
      text: data['weight'] != null ? data['weight'].toString() : ''
    );
    _restController = TextEditingController(
      text: data['rest_time'] != null ? data['rest_time'].toString() : ''
    );
    _notesController = TextEditingController(text: data['notes'] ?? '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateWorkoutExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = widget.workoutExerciseData;
      final workoutExercise = WorkoutExercise(
        id: data['id'],
        workoutId: data['workout_id'],
        exerciseId: data['exercise_id'],
        order: data['order'],
        notes: data['notes'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at']),
        
      );

      await _dbHelper.updateWorkoutExercise(workoutExercise);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercício atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.workoutExerciseData['exercise_name'];
    
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Editar Exercício'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            exerciseName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateWorkoutExercise,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}