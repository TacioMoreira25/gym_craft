import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';

class SeriesEditorWidget extends StatefulWidget {
  final List<WorkoutSeries> initialSeries;
  final Function(List<WorkoutSeries>) onSeriesChanged;

  const SeriesEditorWidget({
    Key? key,
    required this.initialSeries,
    required this.onSeriesChanged,
  }) : super(key: key);

  @override
  State<SeriesEditorWidget> createState() => _SeriesEditorWidgetState();
}

class _SeriesEditorWidgetState extends State<SeriesEditorWidget> {
  late List<WorkoutSeries> series;

  @override
  void initState() {
    super.initState();
    series = List.from(widget.initialSeries);

    if (series.isEmpty) {
      _addSeries(SeriesType.valid);
    }
  }

  void _addSeries(SeriesType type) {
    setState(() {
      series.add(
        WorkoutSeries(
          id: 0,
          workoutExerciseId: 0,
          seriesNumber: series.length + 1,
          type: type,
          repetitions: type == SeriesType.valid ? 12 : null,
          weight: 0.0,
          restSeconds: type == SeriesType.rest ? 0 : 60,
          notes: "",
        ),
      );
    });
    widget.onSeriesChanged(series);
  }

  void _removeSeries(int index) {
    if (series.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deve haver pelo menos uma série'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      series.removeAt(index);
      for (int i = 0; i < series.length; i++) {
        series[i] = series[i].copyWith(seriesNumber: i + 1);
      }
    });
    widget.onSeriesChanged(series);
  }

  void _updateSeries(int index, WorkoutSeries updatedSeries) {
    setState(() {
      series[index] = updatedSeries;
    });
    widget.onSeriesChanged(series);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          children: [
            const Icon(Icons.fitness_center, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              'Séries (${series.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

        // Lista de séries
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: series.length,
          itemBuilder: (context, index) {
            return _SeriesCard(
              series: series[index],
              seriesNumber: index + 1,
              onChanged: (updatedSeries) => _updateSeries(index, updatedSeries),
              onDelete: () => _removeSeries(index),
              canDelete: series.length > 1,
            );
          },
        ),
      ],
    );
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
                    setState(() {
                      _selectedType = newType;
                    });
                    _updateSeries();
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
                          labelText: 'repetitions',
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

            // Descanso (para todos os tipos exceto descanso)
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

            // Notas (sempre disponível)
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
        return true; 

      case SeriesType.warmup:
      case SeriesType.recognition:
        return field != 'weight'; // Sem peso

      case SeriesType.rest:
        return field == 'rest_seconds'; // Só tempo de descanso
    }
  }
}
