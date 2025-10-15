import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/workout_series.dart';
import '../../models/series_type.dart';
import '../../shared/constants/constants.dart';

class SeriesEditorWidget extends StatefulWidget {
  final List<WorkoutSeries> initialSeries;
  final Function(List<WorkoutSeries>) onSeriesChanged;
  final int workoutExerciseId;

  const SeriesEditorWidget({
    Key? key,
    required this.initialSeries,
    required this.onSeriesChanged,
    required this.workoutExerciseId,
  }) : super(key: key);

  @override
  State<SeriesEditorWidget> createState() => _SeriesEditorWidgetState();
}

class _SeriesEditorWidgetState extends State<SeriesEditorWidget> {
  late List<WorkoutSeries> _series;

  @override
  void initState() {
    super.initState();
    _series = List.from(widget.initialSeries);

    if (_series.isEmpty) {
      _addSeries(SeriesType.valid, notify: false);
    }
  }

  @override
  void didUpdateWidget(covariant SeriesEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSeries != oldWidget.initialSeries) {
      setState(() {
        _series = List.from(widget.initialSeries);
        if (_series.isEmpty) {
          _addSeries(SeriesType.valid, notify: false);
        }
      });
    }
  }

  void _notifyParent() {
    widget.onSeriesChanged(List.from(_series));
  }

  void _addSeries(SeriesType type, {bool notify = true}) {
    if (!mounted) return;

    final newSeries = WorkoutSeries(
      id: null,
      workoutExerciseId: widget.workoutExerciseId,
      seriesNumber: _series.length + 1,
      type: type,
      repetitions: type == SeriesType.valid ? 12 : null,
      weight: type == SeriesType.rest ? null : 0.0,
      restSeconds: type == SeriesType.rest ? 30 : 60,
      notes: null,
    );

    setState(() {
      _series.add(newSeries);
    });

    if (notify) _notifyParent();
  }

  void _removeSeries(int index) {
    if (!mounted) return;

    if (_series.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deve haver pelo menos uma série.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _series.removeAt(index);
    });
    _notifyParent();
  }

  void _updateSeriesAtIndex(int index, WorkoutSeries updatedSeries) {
    if (!mounted || index >= _series.length) return;

    setState(() {
      _series[index] = updatedSeries;
    });
    _notifyParent();
  }

  String _getSeriesTypeDescription(SeriesType type) {
    switch (type) {
      case SeriesType.valid:
        return 'Série normal de treino';
      case SeriesType.warmup:
        return 'Série de aquecimento';
      case SeriesType.recognition:
        return 'Série de reconhecimento';
      case SeriesType.dropset:
        return 'Redução progressiva de peso';
      case SeriesType.failure:
        return 'Série até a falha muscular';
      case SeriesType.rest:
        return 'Intervalo de descanso';
      case SeriesType.negativa:
        return 'Foco na fase negativa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            PopupMenuButton<SeriesType>(
              icon: const Icon(Icons.add_circle, color: Colors.indigo),
              tooltip: 'Adicionar Série',
              onSelected: (type) => _addSeries(type),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppConstants.getSeriesTypeName(type)),
                            Text(
                              _getSeriesTypeDescription(type),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...List.generate(_series.length, (index) {
          final series = _series[index];

          return _SeriesCard(
            key: ValueKey('series_$index'),
            series: series,
            seriesNumber: index + 1,
            onChanged: (updatedSeries) => _updateSeriesAtIndex(index, updatedSeries),
            onDelete: () => _removeSeries(index),
            canDelete: _series.length > 1,
          );
        }),
      ],
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _addListeners();
  }

  void _initializeControllers() {
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
    _notesController = TextEditingController(
      text: widget.series.notes ?? '',
    );
  }

  void _addListeners() {
    _repsController.addListener(_onNumericFieldChanged);
    _weightController.addListener(_onNumericFieldChanged);
    _restController.addListener(_onNumericFieldChanged);
  }

  void _removeListeners() {
    _repsController.removeListener(_onNumericFieldChanged);
    _weightController.removeListener(_onNumericFieldChanged);
    _restController.removeListener(_onNumericFieldChanged);
  }

  void _onNumericFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateSeriesFromNumericFields();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeListeners();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateSeriesFromNumericFields() {
    if (!mounted) return;

    final updatedSeries = widget.series.copyWith(
      type: _selectedType,
      repetitions: int.tryParse(_repsController.text),
      weight: double.tryParse(_weightController.text),
      restSeconds: int.tryParse(_restController.text),
      // Mantém as notas atuais sem alteração
      notes: widget.series.notes,
    );

    widget.onChanged(updatedSeries);
  }

  void _updateNotes(String value) {
    if (!mounted) return;

    final updatedSeries = widget.series.copyWith(
      type: _selectedType,
      repetitions: widget.series.repetitions,
      weight: widget.series.weight,
      restSeconds: widget.series.restSeconds,
      notes: value.isEmpty ? null : value,
    );

    widget.onChanged(updatedSeries);
  }

  void _updateSeriesType() {
    if (!mounted) return;

    final updatedSeries = widget.series.copyWith(
      type: _selectedType,
      repetitions: int.tryParse(_repsController.text),
      weight: double.tryParse(_weightController.text),
      restSeconds: int.tryParse(_restController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onChanged(updatedSeries);
  }

  bool _shouldShowField(String field) {
    switch (_selectedType) {
      case SeriesType.valid:
      case SeriesType.dropset:
      case SeriesType.failure:
      case SeriesType.negativa:
        return field == 'repetitions' ||
            field == 'weight' ||
            field == 'rest_seconds';
      case SeriesType.warmup:
      case SeriesType.recognition:
        return field == 'repetitions' || field == 'rest_seconds';
      case SeriesType.rest:
        return field == 'rest_seconds';
    }
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      widget.onDelete();
                    } else {
                      // É um tipo de série
                      final newType = SeriesType.values.firstWhere(
                        (type) => type.toString() == value,
                      );
                      setState(() {
                        _selectedType = newType;
                      });
                      _updateSeriesType();
                    }
                  },
                  itemBuilder: (context) => [
                    ...SeriesType.values.map(
                      (type) => PopupMenuItem(
                        value: type.toString(),
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
                    ),
                    if (widget.canDelete) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
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
            if (_shouldShowField('repetitions') || _shouldShowField('weight')) ...[
              Row(
                children: [
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
                      ),
                    ),
                  if (_shouldShowField('repetitions') && _shouldShowField('weight'))
                    const SizedBox(width: 12),
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
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (_shouldShowField('rest_seconds')) ...[
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
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _notesController,
              maxLines: 2,
              onChanged: (value) => _updateNotes(value),
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Ex: Aumentar peso na próxima...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
