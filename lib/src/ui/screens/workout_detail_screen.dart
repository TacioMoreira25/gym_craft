import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../models/workout_exercise.dart';
import 'select_exercise_screen.dart';
import '../widgets/add_workout_exercise_dialog.dart';
import '../../shared/constants/constants.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../widgets/edit_workout_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';
import '../widgets/progression_chart.dart';
import '../../data/repositories/history_repository.dart';
import '../controllers/workout_detail_controller.dart';
import 'workout_execution_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          WorkoutDetailController(workout: workout)..loadWorkoutExercises(),
      child: const _WorkoutDetailView(),
    );
  }
}

class _WorkoutDetailView extends StatefulWidget {
  const _WorkoutDetailView();

  @override
  State<_WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<_WorkoutDetailView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutDetailController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);

        return PopScope(
          canPop: !controller.isReorderMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && controller.isReorderMode) {
              controller.exitReorderMode();
            }
          },
          child: Scaffold(
            backgroundColor: theme.colorScheme.background,
            appBar: _buildAppBar(context, controller, theme),
            body: _buildBody(context, controller, theme),
            floatingActionButton:
                !controller.isReorderMode && controller.hasExercises
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutExecutionScreen(
                            workoutId: controller.workout.id,
                            workoutName: controller.workout.name,
                            exercises: controller.workoutExercises,
                          ),
                        ),
                      );
                      controller.loadWorkoutExercises();
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      "INICIAR",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                : (!controller.isReorderMode && !controller.hasExercises
                      ? FloatingActionButton(
                          onPressed: () => _addExercise(context, controller),
                          child: const Icon(Icons.add),
                        )
                      : null),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WorkoutDetailController controller,
    ThemeData theme,
  ) {
    return AppBar(
      title: Text(
        controller.isReorderMode
            ? 'Reordenar Exercícios'
            : controller.workout.name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: controller.isReorderMode
          ? IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              onPressed: () => controller.exitReorderMode(),
            )
          : IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (!controller.isReorderMode && controller.hasExercises) ...[
          IconButton(
            onPressed: () => _addExercise(context, controller),
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Exercício',
          ),
          IconButton(
            onPressed: () => controller.setReorderMode(true),
            icon: Icon(
              Icons.reorder,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Reordenar',
          ),
        ],
        if (controller.isReorderMode)
          IconButton(
            onPressed: () async {
              await controller.saveExerciseOrder();
              controller.exitReorderMode();
              if (context.mounted) {
                SnackBarUtils.showSuccess(context, 'Ordem salva');
              }
            },
            icon: Icon(Icons.check, color: theme.colorScheme.primary),
            tooltip: 'Salvar',
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WorkoutDetailController controller,
    ThemeData theme,
  ) {
    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (controller.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadWorkoutExercises(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!controller.isReorderMode) _buildHeaderSection(controller, theme),
        Expanded(child: _buildExercisesSection(context, controller, theme)),
      ],
    );
  }

  Widget _buildHeaderSection(
    WorkoutDetailController controller,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.workout.description?.isNotEmpty == true) ...[
            Text(
              controller.workout.description!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                _buildStatItem(
                  controller.workoutExercises.length.toString(),
                  'Exercícios',
                  theme,
                ),
                _buildStatItem(
                  controller.getTotalSeries().toString(),
                  'Séries',
                  theme,
                ),
                _buildStatItem(
                  '${controller.calculateEstimatedTime()}min',
                  'Tempo Est.',
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection(
    BuildContext context,
    WorkoutDetailController controller,
    ThemeData theme,
  ) {
    if (!controller.hasExercises) {
      return _buildEmptyState(theme);
    }

    return controller.isReorderMode
        ? _buildReorderableList(context, controller, theme)
        : _buildExercisesList(context, controller, theme);
  }

  Widget _buildReorderableList(
    BuildContext context,
    WorkoutDetailController controller,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ReorderableListView.builder(
        itemCount: controller.workoutExercises.length,
        onReorder: (int oldIndex, int newIndex) {
          controller.reorderExercises(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final workoutExercise = controller.workoutExercises[index];
          return _buildReorderableExerciseCard(
            workoutExercise,
            index,
            theme,
            false,
          );
        },
      ),
    );
  }

  Widget _buildExercisesList(
    BuildContext context,
    WorkoutDetailController controller,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercícios (${controller.workoutExercises.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: controller.workoutExercises.length,
              itemBuilder: (context, index) {
                return _buildModernExerciseCard(
                  context,
                  controller,
                  controller.workoutExercises[index],
                  index,
                  theme,
                  theme.brightness == Brightness.dark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum exercício adicionado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione exercícios ao seu treino',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernExerciseCard(
    BuildContext context,
    WorkoutDetailController controller,
    WorkoutExercise workoutExercise,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final exercise = workoutExercise.exercise;
    final series = workoutExercise.series;
    final muscleGroupColor = AppConstants.getMuscleGroupColor(
      exercise?.category ?? 'Cardio',
    );
    final isExpanded = controller.isExerciseExpanded(workoutExercise.id!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header do exercício (sempre visível)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  controller.toggleExerciseExpansion(workoutExercise.id!),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Hero(
                      tag: 'exercise_${workoutExercise.id}',
                      child: ExerciseImageWidget(
                        imageUrl: exercise?.imageUrl,
                        width: 60,
                        height: 60,
                        category: exercise?.category,
                        borderRadius: BorderRadius.circular(16),
                        enableTap: true,
                        exerciseName: exercise?.name ?? 'Exercício',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: muscleGroupColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: muscleGroupColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise?.name ?? 'Exercício',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if ((exercise?.category ?? '').isNotEmpty)
                                Text(
                                  exercise?.category ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              if ((exercise?.category ?? '').isNotEmpty &&
                                  series.isNotEmpty)
                                const SizedBox(width: 8),
                              if (series.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${series.length} séries',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.show_chart_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          tooltip: 'Ver Progresso',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => _buildProgressionSheet(
                                context,
                                workoutExercise,
                              ),
                            );
                          },
                        ),
                        PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 20,
                                    color: Colors.blue[600],
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Excluir',
                                    style: TextStyle(color: theme.colorScheme.error),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'clear_history',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 20,
                                    color: Colors.orange[600],
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Limpar Histórico'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editWorkoutExercise(
                                  context,
                                  controller,
                                  workoutExercise,
                                );
                                break;
                              case 'delete':
                                _deleteExercise(
                                  context,
                                  controller,
                                  workoutExercise,
                                );
                                break;
                              case 'clear_history':
                                _clearExerciseHistory(
                                  context,
                                  controller,
                                  workoutExercise,
                                );
                                break;
                            }
                          },
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo expansível (séries)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedSeriesContent(
              controller,
              workoutExercise,
              theme,
              isDark,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSeriesContent(
    WorkoutDetailController controller,
    WorkoutExercise workoutExercise,
    ThemeData theme,
    bool isDark,
  ) {
    final series = workoutExercise.series;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          if (series.isNotEmpty) ...[
            Text(
              'Séries (${series.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...series.asMap().entries.map((entry) {
              final s = entry.value;
              final typeColor =
                  AppConstants.seriesTypeColors[s.type] ??
                  theme.colorScheme.primary;
              final typeName = s.type.displayName;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.transparent, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            "${s.seriesNumber}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${s.weight?.toStringAsFixed(s.weight!.truncateToDouble() == s.weight ? 0 : 1) ?? '--'}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "kg",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${s.repetitions ?? '--'}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "reps",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              if (s.restSeconds != null &&
                                  s.restSeconds! > 0) ...[
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.restSeconds! >= 60
                                      ? "${s.restSeconds! ~/ 60}:${(s.restSeconds! % 60).toString().padLeft(2, '0')} min"
                                      : "${s.restSeconds}s",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (s.restSeconds! >= 60)
                                  const Text(
                                    " pausa",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(width: 24, height: 24),
                      ],
                    ),
                    if (controller.isValidText(s.notes)) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.notes!.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],

          if (controller.isValidText(workoutExercise.notes)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[100]!, Colors.amber[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_rounded, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workoutExercise.notes!.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReorderableExerciseCard(
    WorkoutExercise workoutExercise,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final exercise = workoutExercise.exercise;
    final muscleGroupColor = AppConstants.getMuscleGroupColor(
      exercise?.category ?? 'Cardio',
    );

    return Container(
      key: ValueKey(workoutExercise.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise?.name ?? 'Exercício',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: muscleGroupColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise?.category ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muscleGroupColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (workoutExercise.series.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${workoutExercise.series.length} série${workoutExercise.series.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          'Exercício',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionSheet(
    BuildContext context,
    WorkoutExercise workoutExercise,
  ) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            // Use Column em vez de ListView direto para fixar o header se quiser
            children: [
              // Puxador
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Text(
                      "Progresso de Carga",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Histórico para ${workoutExercise.exercise?.name ?? 'Exercício'}",
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

                          // Se não tiver dados ou lista vazia
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

                          // Renderiza o gráfico
                          return ProgressionChart(
                            data: snapshot.data!,
                            height: 280, // Altura boa para visualização
                            // Usa as cores do tema do seu app
                            contentColor: theme.colorScheme.primary,
                            spotColor: theme.colorScheme.secondary,
                            backgroundColor: const Color(
                              0xFF1E1E1E,
                            ), // Fundo escuro fixo ou use theme.cardColor
                          );
                        },
                      ),

                    const SizedBox(height: 32),

                    // Seção de Instruções (Mantida)
                    if (workoutExercise.exercise?.description != null &&
                        workoutExercise.exercise!.description!.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        "Instruções",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        workoutExercise.exercise!.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ProgressionPoint>> _loadHistory(int exerciseId) async {
    final rawData = await HistoryRepository().getExerciseHistory(exerciseId);
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

  // Métodos de navegação e interação
  Future<void> _addExercise(
    BuildContext context,
    WorkoutDetailController controller,
  ) async {
    final Exercise? selectedExercise = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SelectExerciseScreen(
              excludeExerciseIds: controller.getExistingExerciseIds(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );

    if (selectedExercise != null && context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AddWorkoutExerciseDialog(
          workoutId: controller.workout.id!,
          selectedExercise: selectedExercise,
          onExerciseAdded: () {
            controller.loadWorkoutExercises();
          },
        ),
      );
    }
  }

  Future<void> _editWorkoutExercise(
    BuildContext context,
    WorkoutDetailController controller,
    WorkoutExercise workoutExercise,
  ) async {
    final exerciseData = controller.prepareExerciseDataForEdit(workoutExercise);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => EditWorkoutExerciseDialog(
        workoutExerciseData: exerciseData,
        onUpdated: () {},
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    if (context.mounted) {
      await controller.loadWorkoutExercises();
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, 'Exercício atualizado com sucesso!');
      }
    }
  }

  void _deleteExercise(
    BuildContext context,
    WorkoutDetailController controller,
    WorkoutExercise workoutExercise,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Text('Confirmar Exclusão'),
            ],
          ),
          content: Text(
            'Tem certeza que deseja remover "${workoutExercise.exercise?.name ?? 'este exercício'}" deste treino?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await controller.deleteExercise(workoutExercise);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(
                    context,
                    'Exercício removido do treino!',
                  );
                }
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _clearExerciseHistory(
    BuildContext context,
    WorkoutDetailController controller,
    WorkoutExercise workoutExercise,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.orange[600], size: 28),
              const SizedBox(width: 12),
              const Text('Limpar Histórico'),
            ],
          ),
          content: Text(
            'Tem certeza que deseja limpar todo o histórico de execução de "${workoutExercise.exercise?.name ?? 'este exercício'}"? Esta ação não pode ser desfeita.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (workoutExercise.exercise?.id != null) {
                  await controller.clearHistoryForExercise(
                    workoutExercise.exercise!.id!,
                  );
                  if (context.mounted) {
                    SnackBarUtils.showSuccess(
                      context,
                      'Histórico limpo com sucesso!',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );
  }
}
