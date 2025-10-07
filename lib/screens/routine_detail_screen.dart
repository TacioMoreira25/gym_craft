import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../utils/snackbar_utils.dart';
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
  final DatabaseService _databaseService = DatabaseService();
  List<Workout> _workouts = [];
  bool _isLoading = true;
  bool _isReorderMode = false;
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
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final workouts = await _databaseService.workouts.getWorkoutsByRoutine(
        widget.routine.id!,
      );

      final orderedWorkouts = await _applyCustomOrder(workouts);

      if (mounted) {
        setState(() {
          _workouts = orderedWorkouts;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showOperationError(
          context,
          'carregar dados',
          e.toString(),
        );
      }
    }
  }

  Future<List<Workout>> _applyCustomOrder(List<Workout> workouts) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString(
        'workout_order_${widget.routine.id}',
      );

      if (savedOrder == null) return workouts;

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<Workout> orderedWorkouts = [];

      for (int id in orderIds) {
        try {
          Workout workout = workouts.firstWhere((w) => w.id == id);
          orderedWorkouts.add(workout);
        } catch (e) {
          // Continue se não encontrar o workout
        }
      }

      for (Workout workout in workouts) {
        if (!orderedWorkouts.any((w) => w.id == workout.id)) {
          orderedWorkouts.add(workout);
        }
      }

      return orderedWorkouts;
    } catch (e) {
      return workouts;
    }
  }

  Future<void> _saveWorkoutOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> workoutIds = _workouts.map((workout) => workout.id!).toList();
      await prefs.setString(
        'workout_order_${widget.routine.id}',
        jsonEncode(workoutIds),
      );
    } catch (e) {
      print('Erro ao salvar ordem dos treinos: $e');
    }
  }

  void _exitReorderMode() => setState(() => _isReorderMode = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isReorderMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isReorderMode) _exitReorderMode();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: _buildAppBar(theme),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : Column(
                children: [
                  if (!_isReorderMode) _buildHeaderSection(theme),
                  Expanded(child: _buildWorkoutsSection(theme)),
                ],
              ),
        floatingActionButton: !_isReorderMode ? _buildFAB() : null,
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        _isReorderMode ? 'Reordenar Treinos' : widget.routine.name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: _isReorderMode
          ? IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              onPressed: _exitReorderMode,
            )
          : IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (!_isReorderMode && _workouts.isNotEmpty)
          IconButton(
            onPressed: () => setState(() => _isReorderMode = true),
            icon: Icon(
              Icons.reorder,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Reordenar',
          ),
        if (_isReorderMode)
          IconButton(
            onPressed: () async {
              await _saveWorkoutOrder();
              _exitReorderMode();
              SnackBarUtils.showSuccess(context, 'Ordem salva');
            },
            icon: Icon(Icons.check, color: theme.colorScheme.primary),
            tooltip: 'Salvar',
          ),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
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
                  color: widget.routine.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.routine.isActive ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.routine.isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Criada em ${_formatDate(widget.routine.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Descrição
          if (widget.routine.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              widget.routine.description!,
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

  Widget _buildWorkoutsSection(ThemeData theme) {
    if (_workouts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _isReorderMode
        ? _buildReorderableList(theme)
        : _buildWorkoutsList(theme);
  }

  Widget _buildReorderableList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ReorderableListView.builder(
        itemCount: _workouts.length,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _workouts.removeAt(oldIndex);
            _workouts.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final workout = _workouts[index];
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

  Widget _buildWorkoutsList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Treinos (${_workouts.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildWorkoutCard(_workouts[index], index, theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, int index, ThemeData theme) {
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
            ).then((_) => _loadData());
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
                      showDialog(
                        context: context,
                        builder: (context) => EditWorkoutDialog(
                          workout: workout,
                          onUpdated: _loadData,
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteWorkoutDialog(workout);
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateWorkoutScreen(routine: widget.routine),
          ),
        ).then((_) => _loadData());
      },
      child: const Icon(Icons.add),
    );
  }

  void _showDeleteWorkoutDialog(Workout workout) {
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
              await _databaseService.workouts.deleteWorkout(workout.id!);
              _loadData();
              SnackBarUtils.showSuccess(context, 'Treino excluído');
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
