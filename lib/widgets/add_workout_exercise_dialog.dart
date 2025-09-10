import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';
import '../services/database_service.dart';

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
  State<AddWorkoutExerciseDialog> createState() => _AddWorkoutExerciseDialogState();
}

class _AddWorkoutExerciseDialogState extends State<AddWorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  List<SeriesData> _seriesList = [
    SeriesData(repetitions: 12, weight: 0.0, restSeconds: 60, type: SeriesType.valid),
    SeriesData(repetitions: 12, weight: 0.0, restSeconds: 60, type: SeriesType.valid),
    SeriesData(repetitions: 12, weight: 0.0, restSeconds: 60, type: SeriesType.valid),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addSeries() {
    setState(() {
      final lastSeries = _seriesList.isNotEmpty ? _seriesList.last : null;
      _seriesList.add(SeriesData(
        repetitions: lastSeries?.repetitions ?? 12,
        weight: lastSeries?.weight ?? 0.0,
        restSeconds: lastSeries?.restSeconds ?? 60,
        type: SeriesType.valid,
      ));
    });
  }

  void _removeSeries(int index) {
    if (_seriesList.length > 1) {
      setState(() {
        _seriesList.removeAt(index);
      });
    }
  }

  Future<void> _addExerciseToWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nextOrder = await _databaseService.workoutExercises.getNextWorkoutExerciseOrder(widget.workoutId);

      final workoutExercise = WorkoutExercise(
        workoutId: widget.workoutId,
        exerciseId: widget.selectedExercise.id!,
        orderIndex: nextOrder,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final workoutExerciseId = await _databaseService.workoutExercises.insertWorkoutExercise(workoutExercise);

      List<WorkoutSeries> seriesList = [];
      for (int i = 0; i < _seriesList.length; i++) {
        final seriesData = _seriesList[i];
        final series = WorkoutSeries(
          workoutExerciseId: workoutExerciseId,
          seriesNumber: i + 1,
          repetitions: seriesData.repetitions,
          weight: seriesData.weight,
          restSeconds: seriesData.restSeconds,
          type: seriesData.type,
          notes: seriesData.notes,
          createdAt: DateTime.now(),
        );
        seriesList.add(series);
      }

      await _databaseService.series.saveWorkoutExerciseSeries(workoutExerciseId, seriesList);

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
              child: Text('${widget.selectedExercise.name} adicionado ao treino!'),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedExercise.category ?? 'Exercício',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
                if (widget.selectedExercise.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.selectedExercise.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(int index) {
    final seriesData = _seriesList[index];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Cabeçalho da série
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    'Série',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Botão remover
                if (_seriesList.length > 1)
                  IconButton(
                    onPressed: () => _removeSeries(index),
                    icon: Icon(Icons.remove_circle, color: Colors.red[600]),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Campos da série
            Column(
              children: [
                Row(
                  children: [
                    // Repetições
                    Expanded(
                      child: TextFormField(
                        initialValue: seriesData.repetitions?.toString() ?? '12',
                        decoration: InputDecoration(
                          labelText: 'Repetições',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.repeat, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Obrigatório';
                          final reps = int.tryParse(value);
                          if (reps == null || reps <= 0) return 'Deve ser > 0';
                          if (reps > 999) return 'Máximo 999';
                          return null;
                        },
                        onChanged: (value) {
                          final reps = int.tryParse(value) ?? 12;
                          setState(() {
                            _seriesList[index].repetitions = reps;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Peso
                    Expanded(
                      child: TextFormField(
                        initialValue: seriesData.weight?.toString() ?? '0',
                        decoration: InputDecoration(
                          labelText: 'Peso (kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.fitness_center, size: 20),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final weight = double.tryParse(value);
                            if (weight == null) return 'Inválido';
                            if (weight > 9999) return 'Máximo 9999kg';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final weight = double.tryParse(value) ?? 0.0;
                          setState(() {
                            _seriesList[index].weight = weight;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tempo de descanso individual
                TextFormField(
                  initialValue: seriesData.restSeconds?.toString() ?? '60',
                  decoration: InputDecoration(
                    labelText: 'Descanso (segundos)',
                    hintText: 'Ex: 60, 90, 120...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: const Icon(Icons.timer, size: 20),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final rest = int.tryParse(value);
                      if (rest == null || rest < 0) return 'Deve ser ≥ 0';
                      if (rest > 3600) return 'Máximo 3600s (1h)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final rest = int.tryParse(value) ?? 60;
                    setState(() {
                      _seriesList[index].restSeconds = rest;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Configurar Exercício',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.selectedExercise.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),

                // Título das séries
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Séries (${_seriesList.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _seriesList.length < 10 ? _addSeries : null,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lista de séries
                ...List.generate(_seriesList.length, (index) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSeriesCard(index),
                  ),
                ),

                const SizedBox(height: 16),

                // Observações
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText: 'Ex: Foco na forma, técnica específica...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.note, color: Colors.blue[600]),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 2,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addExerciseToWorkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Adicionar ao Treino'),
        ),
      ],
    );
  }
}

// Classe auxiliar para gerenciar dados das séries
class SeriesData {
  int? repetitions;
  double? weight;
  int? restSeconds;
  SeriesType type;
  String? notes;

  SeriesData({
    this.repetitions,
    this.weight,
    this.restSeconds,
    this.type = SeriesType.valid,
    this.notes,
  });
}
