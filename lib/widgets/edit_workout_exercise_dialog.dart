import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

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
  late TextEditingController _notesController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  List<WorkoutSeries> _series = [];

  @override
  void initState() {
    super.initState();
    final data = widget.workoutExerciseData;
    _notesController = TextEditingController(text: data['notes'] ?? '');
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
      final seriesList = await _dbHelper.getSeriesByWorkoutExercise(workoutExerciseId);
      
      if (mounted) {
        setState(() {
          _series = List.from(seriesList);
          if (_series.isEmpty) {
            _series.add(WorkoutSeries(
              id: 0,
              workoutExerciseId: workoutExerciseId,
              seriesNumber: 1,
              type: SeriesType.valid,
              repetitions: 12,
              weight: 0.0,
              restSeconds: 60,
              notes: "",
            ));
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar séries: $e');
    }
  }

  Future<void> _updateWorkoutExercise() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final data = widget.workoutExerciseData;
      
      // Atualizar o workout exercise
      final workoutExercise = WorkoutExercise(
        id: data['id'],
        workoutId: data['workout_id'],
        exerciseId: data['exercise_id'],
        orderIndex: data['order_index'],
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at']),
      );

      await _dbHelper.updateWorkoutExercise(workoutExercise);
      
      // Atualizar as séries
      await _updateSeries();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSeries() async {
    final workoutExerciseId = widget.workoutExerciseData['id'];
    
    // Primeiro, excluir todas as séries existentes
    await _dbHelper.deleteSeriesByWorkoutExercise(workoutExerciseId);
    
    // Depois, inserir as novas séries
    for (int i = 0; i < _series.length; i++) {
      final series = _series[i].copyWith(
        workoutExerciseId: workoutExerciseId,
        seriesNumber: i + 1,
      );
      await _dbHelper.insertSeries(series);
    }
  }

  void _addSeries(SeriesType type) {
    if (!mounted) return;
    
    setState(() {
      _series.add(
        WorkoutSeries(
          id: 0,
          workoutExerciseId: widget.workoutExerciseData['id'],
          seriesNumber: _series.length + 1,
          type: type,
          repetitions: type == SeriesType.valid ? 12 : null,
          weight: 0.0,
          restSeconds: type == SeriesType.rest ? 0 : 60,
          notes: "",
        ),
      );
    });
  }

  void _removeSeries(int index) {
    if (!mounted) return;
    
    if (_series.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deve haver pelo menos uma série'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _series.removeAt(index);
      for (int i = 0; i < _series.length; i++) {
        _series[i] = _series[i].copyWith(seriesNumber: i + 1);
      }
    });
  }

  void _updateSeriesAtIndex(int index, WorkoutSeries updatedSeries) {
    if (!mounted) return;
    
    setState(() {
      _series[index] = updatedSeries;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.workoutExerciseData['exercise_name'];
    
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
                      Icon(Icons.edit, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Editar Exercício',
                        style: TextStyle(
                          fontSize: 20,
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
                        decoration: const InputDecoration(
                          labelText: 'Notas do Exercício (opcional)',
                          hintText: 'Ex: Foco na execução, ajustar postura...',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Cabeçalho das séries
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'Séries (${_series.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Botão para adicionar série
                          PopupMenuButton<SeriesType>(
                            icon: const Icon(Icons.add_circle, color: Colors.indigo),
                            tooltip: 'Adicionar Série',
                            onSelected: _addSeries,
                            itemBuilder: (context) => SeriesType.values.map((type) {
                              return PopupMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      AppConstants.getSeriesTypeIcon(type),
                                      size: 20,
                                      color: AppConstants.getSeriesTypeColor(type),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(AppConstants.getSeriesTypeName(type)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lista de séries
                      ..._series.asMap().entries.map((entry) {
                        final index = entry.key;
                        final series = entry.value;
                        return _SeriesCard(
                          key: ValueKey('series_${series.id}_$index'),
                          series: series,
                          seriesNumber: index + 1,
                          onChanged: (updatedSeries) => _updateSeriesAtIndex(index, updatedSeries),
                          onDelete: () => _removeSeries(index),
                          canDelete: _series.length > 1,
                        );
                      }).toList(),
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
                    onPressed: _isLoading ? null : () {
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateWorkoutExercise,
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

class _SeriesCard extends StatefulWidget {
  final WorkoutSeries series;
  final int seriesNumber;
  final Function(WorkoutSeries) onChanged;
  final VoidCallback onDelete;
  final bool canDelete;

  const _SeriesCard({
    Key? key,
    required this.series,
    required this.seriesNumber,
    required this.onChanged,
    required this.onDelete,
    required this.canDelete,
  }) : super(key: key);

  @override
  State<_SeriesCard> createState() => _SeriesCardState();
}

class _SeriesCardState extends State<_SeriesCard> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;
  late TextEditingController _notesController;
  late SeriesType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.series.type;
    _repsController = TextEditingController(
      text: widget.series.repetitions?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.series.weight?.toString() ?? '',
    );
    _restController = TextEditingController(
      text: widget.series.restSeconds?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.series.notes ?? '');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateSeries() {
    if (!mounted) return;
    
    final updatedSeries = widget.series.copyWith(
      type: _selectedType,
      repetitions: _repsController.text.isEmpty
          ? null
          : int.tryParse(_repsController.text),
      weight: _weightController.text.isEmpty
          ? null
          : double.tryParse(_weightController.text),
      restSeconds: _restController.text.isEmpty
          ? null
          : int.tryParse(_restController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    widget.onChanged(updatedSeries);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da série
            Row(
              children: [
                // Badge do tipo de série
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.getSeriesTypeColor(_selectedType),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppConstants.getSeriesTypeIcon(_selectedType),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.seriesNumber}ª ${AppConstants.getSeriesTypeName(_selectedType)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Dropdown para mudar tipo
                PopupMenuButton<SeriesType>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (newType) {
                    if (mounted) {
                      setState(() {
                        _selectedType = newType;
                      });
                      _updateSeries();
                    }
                  },
                  itemBuilder: (context) => [
                    ...SeriesType.values
                        .map(
                          (type) => PopupMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  AppConstants.getSeriesTypeIcon(type),
                                  size: 16,
                                  color: AppConstants.getSeriesTypeColor(type),
                                ),
                                const SizedBox(width: 8),
                                Text(AppConstants.getSeriesTypeName(type)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    if (widget.canDelete) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        onTap: widget.onDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos de entrada baseados no tipo de série
            if (_shouldShowField('repetitions')) ...[
              Row(
                children: [
                  // Repetições
                  if (_shouldShowField('repetitions'))
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Repetições',
                          hintText: '12',
                          prefixIcon: Icon(Icons.repeat),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _updateSeries(),
                      ),
                    ),

                  if (_shouldShowField('repetitions') && _shouldShowField('weight'))
                    const SizedBox(width: 12),

                  // Peso
                  if (_shouldShowField('weight'))
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          hintText: '20.0',
                          prefixIcon: Icon(Icons.fitness_center),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _updateSeries(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Descanso
            if (_shouldShowField('rest_seconds'))
              TextField(
                controller: _restController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _selectedType == SeriesType.rest
                      ? 'Tempo (segundos)'
                      : 'Descanso (segundos)',
                  hintText: _selectedType == SeriesType.rest ? '30' : '60',
                  prefixIcon: const Icon(Icons.timer),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _updateSeries(),
              ),

            if (_shouldShowField('rest_seconds')) const SizedBox(height: 12),

            // Notas
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Ex: Aumentar peso na próxima...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateSeries(),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowField(String field) {
    switch (_selectedType) {
      case SeriesType.valid:
      case SeriesType.dropset:
      case SeriesType.failure:
      case SeriesType.negativa:
        return true; // Todos os campos

      case SeriesType.warmup:
      case SeriesType.recognition:
        return field != 'weight'; // Sem peso

      case SeriesType.rest:
        return field == 'rest_seconds'; // Só tempo de descanso
    }
  }
}