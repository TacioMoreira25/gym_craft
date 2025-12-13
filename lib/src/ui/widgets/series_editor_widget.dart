import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/workout_series.dart';
import '../../models/series_type.dart';
import '../../shared/constants/constants.dart';
import '../controllers/series_editor_controller.dart';

class SeriesEditorWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SeriesEditorController(
        initialSeries: initialSeries,
        onSeriesChanged: onSeriesChanged,
        workoutExerciseId: workoutExerciseId,
      ),
      child: Consumer<SeriesEditorController>(
        builder: (context, controller, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, controller),
              const SizedBox(height: 16),
              ...List.generate(controller.seriesCount, (index) {
                final series = controller.series[index];
                return _SeriesCard(
                  key: ValueKey('series_$index'),
                  series: series,
                  seriesNumber: index + 1,
                  controller: controller,
                  index: index,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SeriesEditorController controller) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Text(
          'Séries (${controller.seriesCount})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        PopupMenuButton<SeriesType>(
          icon: const Icon(Icons.add_circle),
          tooltip: 'Adicionar Série',
          onSelected: (type) => controller.addSeries(type),
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
                          controller.getSeriesTypeDescription(type),
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
    );
  }
}

class _SeriesCard extends StatefulWidget {
  final WorkoutSeries series;
  final int seriesNumber;
  final SeriesEditorController controller;
  final int index;

  const _SeriesCard({
    Key? key,
    required this.series,
    required this.seriesNumber,
    required this.controller,
    required this.index,
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

  @override
  void didUpdateWidget(covariant _SeriesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series != oldWidget.series) {
      _removeListeners();
      _disposeControllers();
      _initializeControllers();
      _addListeners();
    }
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

  void _disposeControllers() {
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _notesController.dispose();
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
    _disposeControllers();
    super.dispose();
  }

  void _updateSeriesFromNumericFields() {
    if (!mounted) return;

    final updatedSeries = widget.series.copyWith(
      type: _selectedType,
      repetitions: int.tryParse(_repsController.text),
      weight: double.tryParse(_weightController.text),
      restSeconds: int.tryParse(_restController.text),
      notes: widget.series.notes,
    );

    widget.controller.updateSeriesAtIndex(widget.index, updatedSeries);
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

    widget.controller.updateSeriesAtIndex(widget.index, updatedSeries);
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

    widget.controller.updateSeriesAtIndex(widget.index, updatedSeries);
  }

  void _deleteSeries() {
    final success = widget.controller.removeSeries(widget.index);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deve haver pelo menos uma série.'),
          backgroundColor: Colors.orange,
        ),
      );
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
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFields(),
            _buildNotesField(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
              _deleteSeries();
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
            if (widget.controller.hasMultipleSeries) ...[
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
    );
  }

  Widget _buildFields() {
    final showReps = widget.controller.shouldShowField(_selectedType, 'repetitions');
    final showWeight = widget.controller.shouldShowField(_selectedType, 'weight');
    final showRest = widget.controller.shouldShowField(_selectedType, 'rest_seconds');

    return Column(
      children: [
        if (showReps || showWeight) ...[
          Row(
            children: [
              if (showReps)
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
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              if (showReps && showWeight) const SizedBox(width: 12),
              if (showWeight)
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
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (showRest) ...[
          TextField(
            controller: _restController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _selectedType == SeriesType.rest
                  ? 'Tempo (segundos)'
                  : 'Descanso (segundos)',
              hintText: _selectedType == SeriesType.rest ? '30' : '60',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 2,
      onChanged: (value) => _updateNotes(value),
      decoration: const InputDecoration(
        labelText: 'Notas (opcional)',
        hintText: 'Ex: Aumentar peso na próxima...',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
