import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/routine_detail_controller.dart';
import 'create_workout_screen.dart';
import 'workout_detail_screen.dart';
import '../widgets/edit_workout_dialog.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  _RoutineDetailScreenState createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          RoutineDetailController(routine: widget.routine)..loadData(),
      child: _RoutineDetailView(
        fadeAnimation: _fadeAnimation,
        animationController: _animationController,
      ),
    );
  }
}

class _RoutineDetailView extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final AnimationController animationController;

  const _RoutineDetailView({
    required this.fadeAnimation,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineDetailController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);

        // Iniciar animação quando os dados são carregados
        if (!controller.isLoading && !animationController.isCompleted) {
          animationController.forward();
        }

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
            floatingActionButton: !controller.isReorderMode
                ? _buildFAB(context, controller)
                : null,
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    RoutineDetailController controller,
    ThemeData theme,
  ) {
    return AppBar(
      title: Text(
        controller.isReorderMode
            ? 'Reordenar Treinos'
            : controller.routine.name,
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
        if (!controller.isReorderMode && controller.workouts.isNotEmpty)
          IconButton(
            onPressed: () => controller.enableReorderMode(),
            icon: Icon(
              Icons.reorder,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Reordenar',
          ),
        if (controller.isReorderMode)
          IconButton(
            onPressed: () async {
              await controller.saveReorderAndExit();
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
    RoutineDetailController controller,
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
              onPressed: () => controller.loadData(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!controller.isReorderMode) _buildHeaderSection(controller, theme),
        Expanded(child: _buildWorkoutsSection(context, controller, theme)),
      ],
    );
  }

  Widget _buildHeaderSection(
    RoutineDetailController controller,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status e data
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.routine.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.routine.isActive ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: controller.routine.isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Criada em ${controller.formatDate(controller.routine.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Descrição
          if (controller.routine.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              controller.routine.description!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutsSection(
    BuildContext context,
    RoutineDetailController controller,
    ThemeData theme,
  ) {
    if (controller.workouts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return controller.isReorderMode
        ? _buildReorderableList(controller, theme)
        : _buildWorkoutsList(context, controller, theme);
  }

  Widget _buildReorderableList(
    RoutineDetailController controller,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ReorderableListView.builder(
        itemCount: controller.workouts.length,
        onReorder: (int oldIndex, int newIndex) =>
            controller.reorderWorkouts(oldIndex, newIndex),
        itemBuilder: (context, index) {
          final workout = controller.workouts[index];
          return _buildReorderableWorkoutCard(workout, index, theme);
        },
      ),
    );
  }

  Widget _buildReorderableWorkoutCard(
    Workout workout,
    int index,
    ThemeData theme,
  ) {
    return Container(
      key: ValueKey(workout.id),
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
                    Text(
                      workout.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (workout.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        workout.description!,
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
                          Icons.fitness_center_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Treino',
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

  Widget _buildWorkoutsList(
    BuildContext context,
    RoutineDetailController controller,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Treinos (${controller.workouts.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: controller.workouts.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: _buildWorkoutCard(
                    context,
                    controller,
                    controller.workouts[index],
                    index,
                    theme,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    RoutineDetailController controller,
    Workout workout,
    int index,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailScreen(workout: workout),
              ),
            ).then((_) => controller.loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (workout.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          workout.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditWorkoutDialog(context, controller, workout);
                    } else if (value == 'delete') {
                      _showDeleteWorkoutDialog(context, controller, workout);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('Editar', style: TextStyle(fontSize: 14)),
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
                ),
              ],
            ),
          ),
        ),
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
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fitness_center_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum treino criado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione treinos à sua rotina',
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

  Widget _buildFAB(BuildContext context, RoutineDetailController controller) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateWorkoutScreen(routine: controller.routine),
          ),
        ).then((_) => controller.loadData());
      },
      child: const Icon(Icons.add),
    );
  }

  void _showEditWorkoutDialog(
    BuildContext context,
    RoutineDetailController controller,
    Workout workout,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditWorkoutDialog(
        workout: workout,
        onUpdated: () => controller.loadData(),
      ),
    );
  }

  void _showDeleteWorkoutDialog(
    BuildContext context,
    RoutineDetailController controller,
    Workout workout,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: Text(
          'O treino "${workout.name}" será excluído permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await controller.deleteWorkout(workout.id!);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, 'Treino excluído');
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showError(context, 'Erro ao excluir treino');
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
