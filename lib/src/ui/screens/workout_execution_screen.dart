import 'package:flutter/material.dart';
import 'package:gym_craft/src/models/workout_exercise.dart';
import 'package:gym_craft/src/models/workout_series.dart';
import 'package:gym_craft/src/models/series_type.dart';
import 'package:gym_craft/src/data/database/database_helper.dart';
import 'package:gym_craft/src/ui/widgets/exercise_image_widget.dart';
import 'package:gym_craft/src/ui/widgets/progression_chart.dart';
import 'package:gym_craft/src/shared/constants/constants.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final String workoutName;
  final List<WorkoutExercise> exercises;

  const WorkoutExecutionScreen({
    super.key,
    required this.workoutName,
    required this.exercises,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentIndex = 0;
  final Set<int> _completedSeriesIds = {};
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Text(
                      _currentIndex < widget.exercises.length
                          ? "${_currentIndex + 1} / ${widget.exercises.length}"
                          : "Resumo",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Conteúdo (Cards dos Exercícios)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.exercises.length + 1,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    if (index == widget.exercises.length) {
                      return _buildFinishScreen(theme);
                    }
                    return _buildExerciseCard(widget.exercises[index], theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges && _completedSeriesIds.isEmpty) return true;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Sair do Treino?"),
            content: const Text(
              "Se sair agora, o progresso marcado será salvo, mas o treino não será finalizado. Deseja sair?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Continuar Treinando"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Sair"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildFinishScreen(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Treino Finalizado!",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Bom trabalho! Descanso merecido.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Concluir e Sair"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, ThemeData theme) {
    final exercise = workoutExercise.exercise;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row (Title + Buttons)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise?.name ?? 'Exercício',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (exercise?.category != null)
                        Text(
                          exercise!.category,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Botão de Insights (Gráfico) - Mantido, pois é opcional e útil
                IconButton(
                  icon: const Icon(Icons.insights_rounded),
                  tooltip: "Ver Progresso",
                  onPressed: () {
                    if (exercise?.id != null) {
                      _showExerciseDetails(context, workoutExercise);
                    }
                  },
                ),
              ],
            ),
          ),

          if (exercise?.imageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ExerciseImageWidget(
                  imageUrl: exercise?.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  category: exercise?.category,
                  enableTap: false,
                  exerciseName: exercise?.name ?? '',
                ),
              ),
            ),

          // Lista de Séries
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  if (workoutExercise.notes != null && workoutExercise.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Text(
                          "Nota: ${workoutExercise.notes}",
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                  ...workoutExercise.series.map(
                    (series) => _buildSeriesRow(series, theme),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Toque no peso para editar • Toque no check para concluir",
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesRow(WorkoutSeries series, ThemeData theme) {
    final isDone = _completedSeriesIds.contains(series.id);
    final typeName = series.type.displayName;
    final typeColor = AppConstants.seriesTypeColors[series.type] ?? theme.colorScheme.primary;

    return GestureDetector(
      // Toque no card abre edição
      onTap: () => _showEditDialog(series),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDone
              ? theme.colorScheme.primaryContainer.withOpacity(0.15)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo da Série (Aquecimento, Válida, etc)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                typeName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Row(
              children: [
                // Número da Série
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDone ? theme.colorScheme.primary : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? Colors.transparent : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    "${series.seriesNumber}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDone ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Dados (Peso e Reps)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${series.weight?.toStringAsFixed(series.weight!.truncateToDouble() == series.weight ? 0 : 1) ?? '--'}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Text("kg", style: TextStyle(fontSize: 12, color: Colors.grey)),

                      const Spacer(),

                      Text(
                        "${series.repetitions ?? '--'}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Text("reps", style: TextStyle(fontSize: 12, color: Colors.grey)),

                      const Spacer(),

                      // Tempo de descanso
                      if (series.restSeconds != null && series.restSeconds! > 0) ...[
                        Container(width: 1, height: 16, color: theme.colorScheme.outlineVariant),
                        const Spacer(),
                        Text(
                          series.restSeconds! >= 60
                              ? "${series.restSeconds! ~/ 60}m ${(series.restSeconds! % 60)}s"
                              : "${series.restSeconds}s",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (series.restSeconds! >= 60)
                          const Text(" pausa", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Botão de Check (Independente do card)
                InkWell(
                  onTap: () => _toggleSeries(series),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? theme.colorScheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? Icon(Icons.check, size: 20, color: theme.colorScheme.onPrimary)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSeries(WorkoutSeries series) {
    setState(() {
      _hasChanges = true;
      if (_completedSeriesIds.contains(series.id)) {
        _completedSeriesIds.remove(series.id);
      } else {
        _completedSeriesIds.add(series.id!);

        // 1. Atualiza a ficha (para o peso ficar salvo no card)
        DatabaseHelper().updateSeries(
          series.id!,
          series.weight ?? 0,
          series.repetitions ?? 0,
          true,
          series.type.name,
        );

        if (series.type == SeriesType.valid ||
            series.type == SeriesType.dropset ||
            series.type == SeriesType.failure) {

          final exerciseId = widget.exercises
              .firstWhere((e) => e.series.contains(series))
              .exercise
              ?.id;

          if (exerciseId != null) {
            DatabaseHelper().logSeriesCompletion(
              exerciseId,
              series.weight ?? 0,
              series.repetitions ?? 0
            );
          }
        }
      }
    });
  }

  void _showEditDialog(WorkoutSeries series) {
    final weightCtrl = TextEditingController(text: series.weight?.toString() ?? "");
    final repsCtrl = TextEditingController(text: series.repetitions?.toString() ?? "");
    final restCtrl = TextEditingController(text: series.restSeconds?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Editar Série ${series.seriesNumber}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Carga (kg)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Repetições",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: restCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Descanso (segundos)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _hasChanges = true;
                series.weight = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
                series.repetitions = int.tryParse(repsCtrl.text);
                series.restSeconds = int.tryParse(restCtrl.text);
              });

              // Atualiza a ficha
              await DatabaseHelper().updateSeries(
                series.id!,
                series.weight ?? 0,
                series.repetitions ?? 0,
                _completedSeriesIds.contains(series.id),
                series.type.name,
                restSeconds: series.restSeconds,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, WorkoutExercise workoutExercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Progresso de Carga",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Histórico para ${workoutExercise.exercise?.name}",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  if (workoutExercise.exercise?.id != null)
                    FutureBuilder<List<ProgressionPoint>>(
                      future: _loadHistory(workoutExercise.exercise!.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 250,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            height: 150,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16)
                            ),
                            child: const Text("Nenhum histórico registrado ainda."),
                          );
                        }
                        // Seu gráfico atualizado
                        return ProgressionChart(
                          data: snapshot.data!,
                          height: 250,
                          contentColor: theme.colorScheme.primary,
                          spotColor: theme.colorScheme.secondary,
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  if (workoutExercise.exercise?.description != null) ...[
                    Text("Instruções", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(workoutExercise.exercise!.description!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<ProgressionPoint>> _loadHistory(int exerciseId) async {
    // Busca do novo método getExerciseHistory que une histórico + treino atual
    final rawData = await DatabaseHelper().getExerciseHistory(exerciseId);
    return rawData.map((row) {
      DateTime date;
      if (row['created_at'] is int) {
        date = DateTime.fromMillisecondsSinceEpoch(row['created_at']);
      } else {
        date = DateTime.parse(row['created_at'].toString());
      }
      return ProgressionPoint(
        date: date,
        weight: (row['weight'] as num).toDouble(),
      );
    }).toList();
  }
}
