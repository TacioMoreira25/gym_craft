import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/home_controller.dart';
import 'create_routine_screen.dart';
import 'create_workout_screen.dart';
import 'workout_detail_screen.dart';
import 'routine_detail_screen.dart';
import 'settings_screen.dart';
import '../widgets/edit_routine_dialog.dart';
import '../widgets/edit_workout_dialog.dart';
import '../widgets/app_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController()..initialize(),
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
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
            appBar: AppBar(
              title: Text(
                controller.isReorderMode ? 'Reordenar Rotinas' : 'Rotinas',
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
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () => controller.exitReorderMode(),
                    )
                  : null,
              actions: [
                if (!controller.isReorderMode && controller.routines.isNotEmpty)
                  IconButton(
                    onPressed: () => controller.enableReorderMode(),
                    icon: Icon(
                      Icons.reorder,
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: 'Reordenar',
                  ),
                if (controller.isReorderMode)
                  IconButton(
                    onPressed: () async {
                      await controller.saveReorderAndExit();
                      if (context.mounted) {
                        SnackBarUtils.showUpdateSuccess(context, 'Ordem salva');
                      }
                    },
                    icon: Icon(Icons.check, color: theme.colorScheme.primary),
                    tooltip: 'Salvar',
                  ),
                if (!controller.isReorderMode)
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.settings_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Configurações',
                  ),
              ],
            ),
            body: _buildBody(context, controller, theme),
            floatingActionButton: controller.isReorderMode
                ? null
                : FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateRoutineScreen(),
                        ),
                      ).then((_) => controller.loadRoutines());
                    },
                    child: const Icon(Icons.add),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    HomeController controller,
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
              onPressed: () => controller.loadRoutines(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (controller.routines.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (controller.isReorderMode) {
      return _buildReorderableList(context, controller, theme);
    }

    return _buildRoutinesList(context, controller, theme);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.fitness_center_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bem-vindo ao GymCraft!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Crie sua primeira rotina de treinos para começar sua jornada fitness',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dica Rápida',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uma rotina pode conter vários treinos (ex: Treino A, Treino B, Push, Pull, etc.)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableList(
    BuildContext context,
    HomeController controller,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ReorderableListView.builder(
        itemCount: controller.routines.length,
        onReorder: (oldIndex, newIndex) =>
            controller.reorderRoutines(oldIndex, newIndex),
        itemBuilder: (context, index) {
          final routine = controller.routines[index];
          return Container(
            key: ValueKey('routine_${routine.id}'),
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
                                  routine.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildStatusBadge(routine, theme),
                            ],
                          ),
                          if (routine.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              routine.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                controller.formatDate(routine.createdAt),
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
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
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
        },
      ),
    );
  }

  Widget _buildRoutinesList(
    BuildContext context,
    HomeController controller,
    ThemeData theme,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadRoutines(),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.routines.length,
        itemBuilder: (context, index) {
          final routine = controller.routines[index];
          return _buildExpandableRoutineCard(
            context,
            controller,
            routine,
            theme,
          );
        },
      ),
    );
  }

  Widget _buildExpandableRoutineCard(
    BuildContext context,
    HomeController controller,
    Routine routine,
    ThemeData theme,
  ) {
    final expanded = controller.expandedRoutines.contains(routine.id);
    final workouts = controller.workoutsByRoutine[routine.id ?? -1];
    final isLoadingWorkouts = controller.loadingRoutineWorkouts.contains(
      routine.id,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              InkWell(
                onTap: () => controller.toggleExpand(routine),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    routine.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildStatusBadge(routine, theme),
                              ],
                            ),
                            if (routine.description?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(
                                routine.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  controller.formatDate(routine.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                if (!expanded)
                                  Text(
                                    'Toque para ver treinos',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _buildPopupMenu(context, controller, routine, theme),
                          const SizedBox(height: 4),
                          Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedRoutineContent(
                  context,
                  controller,
                  routine,
                  workouts,
                  isLoadingWorkouts,
                  theme,
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedRoutineContent(
    BuildContext context,
    HomeController controller,
    Routine routine,
    List<Workout>? workouts,
    bool isLoading,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Treinos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              if (workouts != null)
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
                    '${workouts.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Ver detalhes / reordenar',
                icon: Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RoutineDetailScreen(routine: routine),
                    ),
                  ).then((_) => controller.loadRoutines());
                },
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateWorkoutScreen(routine: routine),
                    ),
                  ).then((_) => controller.refreshRoutineWorkouts(routine.id!));
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Treino'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (workouts == null || workouts.isEmpty)
            _buildEmptyWorkoutsState(theme)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return _buildWorkoutInlineCard(
                  context,
                  controller,
                  routine,
                  workout,
                  index,
                  theme,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkoutsState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum treino ainda',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crie seu primeiro treino para esta rotina',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInlineCard(
    BuildContext context,
    HomeController controller,
    Routine routine,
    Workout workout,
    int index,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(workout: workout),
            ),
          ).then((_) => controller.refreshRoutineWorkouts(routine.id!));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (workout.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        workout.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                tooltip: 'Opções do treino',
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.primaryBlue, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Excluir',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditWorkoutDialog(
                      context,
                      controller,
                      routine,
                      workout,
                    );
                  } else if (value == 'delete') {
                    _showDeleteWorkoutDialog(
                      context,
                      controller,
                      routine,
                      workout,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Routine routine, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: routine.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        routine.isActive ? 'Ativa' : 'Inativa',
        style: theme.textTheme.bodySmall?.copyWith(
          color: routine.isActive
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    HomeController controller,
    Routine routine,
    ThemeData theme,
  ) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryBlue, size: 18),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Excluir',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteRoutineDialog(context, controller, routine);
        } else if (value == 'edit') {
          _showEditRoutineDialog(context, controller, routine);
        }
      },
    );
  }

  void _showEditRoutineDialog(
    BuildContext context,
    HomeController controller,
    Routine routine,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditRoutineDialog(
        routine: routine,
        onUpdated: () => controller.loadRoutines(),
      ),
    );
  }

  void _showDeleteRoutineDialog(
    BuildContext context,
    HomeController controller,
    Routine routine,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'Excluir Rotina',
      content: 'Tem certeza que deseja excluir "${routine.name}"?',
      confirmText: 'Excluir',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await controller.deleteRoutine(routine.id!);
        SnackBarUtils.showDeleteSuccessAt(
          messenger,
          'Rotina "${routine.name}" excluída!',
        );
      } catch (e) {
        SnackBarUtils.showErrorAt(messenger, 'Erro ao excluir rotina: $e');
      }
    }
  }

  void _showEditWorkoutDialog(
    BuildContext context,
    HomeController controller,
    Routine routine,
    Workout workout,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditWorkoutDialog(
        workout: workout,
        onUpdated: () => controller.refreshRoutineWorkouts(routine.id!),
      ),
    );
  }

  void _showDeleteWorkoutDialog(
    BuildContext context,
    HomeController controller,
    Routine routine,
    Workout workout,
  ) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'Excluir Treino',
      content: 'Excluir "${workout.name}" desta rotina?',
      confirmText: 'Excluir',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await controller.deleteWorkout(workout.id!);
        await controller.refreshRoutineWorkouts(routine.id!);
        if (context.mounted) {
          SnackBarUtils.showDeleteSuccess(
            context,
            'Treino "${workout.name}" excluído',
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Erro ao excluir treino: $e');
        }
      }
    }
  }
}
