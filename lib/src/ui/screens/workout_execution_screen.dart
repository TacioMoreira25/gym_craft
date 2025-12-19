import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_craft/src/models/workout_exercise.dart';
import 'package:gym_craft/src/models/workout_series.dart';
import 'package:gym_craft/src/ui/controllers/workout_execution_controller.dart';
import 'package:gym_craft/src/ui/widgets/exercise_image_widget.dart';
import 'package:gym_craft/src/ui/widgets/progression_chart.dart';
import 'package:gym_craft/src/data/repositories/history_repository.dart';
import 'package:gym_craft/src/shared/constants/constants.dart';
import '../widgets/app_dialog.dart';

class WorkoutExecutionScreen extends StatelessWidget {
  final int? workoutId;
  final String workoutName;
  final List<WorkoutExercise> exercises;

  const WorkoutExecutionScreen({
    super.key,
    this.workoutId,
    required this.workoutName,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          WorkoutExecutionController(workoutId: workoutId, exercises: exercises)
            ..initSession(),
      child: _WorkoutExecutionView(workoutName: workoutName),
    );
  }
}

class _WorkoutExecutionView extends StatefulWidget {
  final String workoutName;

  const _WorkoutExecutionView({required this.workoutName});

  @override
  State<_WorkoutExecutionView> createState() => _WorkoutExecutionViewState();
}

class _WorkoutExecutionViewState extends State<_WorkoutExecutionView> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<WorkoutExecutionController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context, controller);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        final shouldPop = await _onWillPop(context, controller);
                        if (shouldPop && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        widget.workoutName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Espaço para equilibrar o botão de fechar e manter o título centralizado
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Conteúdo (Cards dos Exercícios)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: controller.exercises.length + 1,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    if (index == controller.exercises.length) {
                      return _buildFinishScreen(context, theme, controller);
                    }
                    return _buildExerciseCard(
                      context,
                      controller.exercises[index],
                      theme,
                      controller,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(
    BuildContext context,
    WorkoutExecutionController controller,
  ) async {
    if (!controller.hasChanges) return true;

    return await AppDialog.showConfirmation(
      context,
      title: "Sair do Treino?",
      content:
          "Se sair agora, o progresso marcado será salvo, mas o treino não será finalizado oficialmente. Deseja sair?",
      confirmText: "Sair",
      cancelText: "Continuar Treinando",
    );
  }

  Widget _buildFinishScreen(
    BuildContext context,
    ThemeData theme,
    WorkoutExecutionController controller,
  ) {
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
            onPressed: () async {
              await controller.finishWorkout();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Concluir e Sair"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WorkoutExercise workoutExercise,
    ThemeData theme,
    WorkoutExecutionController controller,
  ) {
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
          // Header Row (Title)
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
                // Botão de Insights (Gráfico)
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
                  if (workoutExercise.notes != null &&
                      workoutExercise.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.5,
                            ),
                          ),
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
                    (series) => _buildSeriesRow(
                      context,
                      series,
                      theme,
                      controller,
                      workoutExercise.exercise?.id,
                    ),
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

  Widget _buildSeriesRow(
    BuildContext context,
    WorkoutSeries series,
    ThemeData theme,
    WorkoutExecutionController controller,
    int? exerciseId,
  ) {
    final isDone = controller.isSeriesCompleted(series.id!);
    final typeName = series.type.displayName;
    final typeColor =
        AppConstants.seriesTypeColors[series.type] ?? theme.colorScheme.primary;

    return GestureDetector(
      // Toque no card abre edição
      onTap: () => _showEditDialog(context, series, controller),
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
            color: isDone
                ? theme.colorScheme.primary.withOpacity(0.3)
                : Colors.transparent,
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
                    color: isDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? Colors.transparent
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    "${series.seriesNumber}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDone
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "kg",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const Spacer(),

                      Text(
                        "${series.repetitions ?? '--'}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "reps",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const Spacer(),

                      // Tempo de descanso
                      if (series.restSeconds != null &&
                          series.restSeconds! > 0) ...[
                        Container(
                          width: 1,
                          height: 16,
                          color: theme.colorScheme.outlineVariant,
                        ),
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
                          const Text(
                            " pausa",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Botão de Check (Independente do card)
                InkWell(
                  onTap: () {
                    if (exerciseId != null) {
                      controller.toggleSeries(series, exerciseId);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: theme.colorScheme.onPrimary,
                          )
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

  void _showEditDialog(
    BuildContext context,
    WorkoutSeries series,
    WorkoutExecutionController controller,
  ) {
    final weightCtrl = TextEditingController(
      text: series.weight?.toString() ?? "",
    );
    final repsCtrl = TextEditingController(
      text: series.repetitions?.toString() ?? "",
    );
    final restCtrl = TextEditingController(
      text: series.restSeconds?.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: "Editar Série ${series.seriesNumber}",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Carga (kg)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Repetições",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: restCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Descanso (segundos)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () async {
              final weight =
                  double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? 0;
              final reps = int.tryParse(repsCtrl.text) ?? 0;
              final rest = int.tryParse(restCtrl.text);

              await controller.updateSeriesValues(series, weight, reps, rest);

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

  void _showExerciseDetails(
    BuildContext context,
    WorkoutExercise workoutExercise,
  ) {
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Histórico para ${workoutExercise.exercise?.name}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (workoutExercise.exercise?.id != null)
                    FutureBuilder<List<ProgressionPoint>>(
                      future: _loadHistory(workoutExercise.exercise!.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              "Nenhum histórico registrado ainda.",
                            ),
                          );
                        }
                        return ProgressionChart(
                          data: snapshot.data!,
                          height: 250,
                          contentColor: theme.colorScheme.primary,
                          spotColor: theme.colorScheme.secondary,
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<ProgressionPoint>> _loadHistory(int exerciseId) async {
    final rawData = await HistoryRepository().getExerciseHistory(exerciseId);
    return rawData
        .where((row) {
          // Filtra séries de aquecimento/reconhecimento
          // Garante que o valor seja tratado como int (0 ou 1)
          final isWarmupVal = row['is_warmup'];
          final isWarmup = isWarmupVal == 1 || isWarmupVal == true;
          return !isWarmup;
        })
        .map((row) {
          DateTime date;
          if (row['created_at'] is int) {
            date = DateTime.fromMillisecondsSinceEpoch(row['created_at']);
          } else {
            date = DateTime.parse(row['created_at'].toString());
          }
          return ProgressionPoint(
            date: date,
            weight: (row['weight'] as num).toDouble(),
            sessionId: row['session_id'] as int?,
          );
        })
        .toList();
  }
}
