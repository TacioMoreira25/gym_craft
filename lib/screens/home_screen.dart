import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../utils/snackbar_utils.dart';
import 'create_routine_screen.dart';
import 'create_workout_screen.dart';
import 'workout_detail_screen.dart';
import 'routine_detail_screen.dart';
import 'settings_screen.dart';
import '../widgets/edit_routine_dialog.dart';
import '../widgets/edit_workout_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Routine> _routines = [];
  bool _isLoading = true;
  bool _isReorderMode = false;

  final Map<int, List<Workout>> _workoutsByRoutine = {};
  final Set<int> _expandedRoutines = {}; // rotina.id
  final Set<int> _loadingRoutineWorkouts = {}; // rotina.id carregando

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final routines = await _databaseService.routines.getAllRoutines();
    final orderedRoutines = await _applyCustomOrder(routines);

    setState(() {
      _routines = orderedRoutines;
      _isLoading = false;
    });
  }

  Future<void> _toggleExpand(Routine routine) async {
    final id = routine.id!;
    if (_expandedRoutines.contains(id)) {
      setState(() => _expandedRoutines.remove(id));
      return;
    }
    setState(() {
      _expandedRoutines.add(id);
    });
    if (!_workoutsByRoutine.containsKey(id)) {
      await _loadWorkoutsForRoutine(id);
    }
  }

  Future<void> _loadWorkoutsForRoutine(int routineId) async {
    if (_loadingRoutineWorkouts.contains(routineId)) return;
    setState(() => _loadingRoutineWorkouts.add(routineId));
    try {
      final workouts = await _databaseService.workouts.getWorkoutsByRoutine(
        routineId,
      );
      final ordered = await _applyWorkoutOrder(routineId, workouts);
      if (mounted) {
        setState(() => _workoutsByRoutine[routineId] = ordered);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar treinos: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingRoutineWorkouts.remove(routineId));
      }
    }
  }

  Future<List<Workout>> _applyWorkoutOrder(
    int routineId,
    List<Workout> workouts,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrder = prefs.getString('workout_order_$routineId');
      if (savedOrder == null) return workouts;
      final orderIds = List<int>.from(jsonDecode(savedOrder));
      final ordered = <Workout>[];
      for (final id in orderIds) {
        final wIndex = workouts.indexWhere((w) => w.id == id);
        if (wIndex != -1) ordered.add(workouts[wIndex]);
      }
      for (final w in workouts) {
        if (!ordered.any((ow) => ow.id == w.id)) ordered.add(w);
      }
      return ordered;
    } catch (_) {
      return workouts;
    }
  }

  Future<void> _refreshRoutineWorkouts(int routineId) async {
    if (_expandedRoutines.contains(routineId)) {
      await _loadWorkoutsForRoutine(routineId);
    }
  }

  Future<List<Routine>> _applyCustomOrder(List<Routine> routines) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString('routine_order');

      if (savedOrder == null) {
        return routines;
      }

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<Routine> orderedRoutines = [];

      for (int id in orderIds) {
        try {
          Routine routine = routines.firstWhere((r) => r.id == id);
          orderedRoutines.add(routine);
        } catch (e) {
          // Continue se não encontrar a routine
        }
      }

      for (Routine routine in routines) {
        if (!orderedRoutines.any((r) => r.id == routine.id)) {
          orderedRoutines.add(routine);
        }
      }

      return orderedRoutines;
    } catch (e) {
      return routines;
    }
  }

  Future<void> _saveRoutineOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> routineIds = _routines.map((routine) => routine.id!).toList();
      await prefs.setString('routine_order', jsonEncode(routineIds));
    } catch (e) {
      print('Erro ao salvar ordem das rotinas: $e');
    }
  }

  void _editRoutine(Routine routine) {
    showDialog(
      context: context,
      builder: (context) => EditRoutineDialog(
        routine: routine,
        onUpdated: () {
          _loadRoutines();
        },
      ),
    );
  }

  void _exitReorderMode() {
    setState(() => _isReorderMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isReorderMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isReorderMode) {
          _exitReorderMode();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Text(
            _isReorderMode ? 'Reordenar Rotinas' : 'Rotinas',
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
              : null,
          actions: [
            if (!_isReorderMode && _routines.isNotEmpty)
              IconButton(
                onPressed: () {
                  setState(() => _isReorderMode = true);
                },
                icon: Icon(Icons.reorder, color: theme.colorScheme.onSurface),
                tooltip: 'Reordenar',
              ),
            if (_isReorderMode)
              IconButton(
                onPressed: () async {
                  await _saveRoutineOrder();
                  _exitReorderMode();
                  SnackBarUtils.showSuccess(context, 'Ordem salva');
                },
                icon: Icon(Icons.check, color: theme.colorScheme.primary),
                tooltip: 'Salvar',
              ),
            if (!_isReorderMode)
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
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : _routines.isEmpty
            ? _buildEmptyState()
            : _isReorderMode
            ? _buildReorderableList()
            : _buildRoutinesList(),
        floatingActionButton: _isReorderMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRoutineScreen(),
                    ),
                  ).then((_) => _loadRoutines());
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova Rotina'),
              ),
      ),
    );
  }

  Widget _buildExpandableRoutineCard(Routine routine, ThemeData theme) {
    final expanded = _expandedRoutines.contains(routine.id);
    final workouts = _workoutsByRoutine[routine.id ?? -1];
    final isLoadingWorkouts = _loadingRoutineWorkouts.contains(routine.id);

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
                onTap: () => _toggleExpand(routine),
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
                                  _formatDate(routine.createdAt),
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
                          _buildPopupMenu(routine, theme),
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
                  ).then((_) => _loadRoutines());
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
                  ).then((_) => _refreshRoutineWorkouts(routine.id!));
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
            Column(
              children: [
                Container(
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
                ),
              ],
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return _buildWorkoutInlineCard(routine, workout, index, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInlineCard(
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
          ).then((_) => _refreshRoutineWorkouts(routine.id!));
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
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (c) => EditWorkoutDialog(
                        workout: workout,
                        onUpdated: () => _refreshRoutineWorkouts(routine.id!),
                      ),
                    );
                  } else if (value == 'delete') {
                    _confirmDeleteWorkout(routine, workout);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteWorkout(Routine routine, Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Treino'),
        content: Text('Excluir "${workout.name}" desta rotina?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _databaseService.workouts.deleteWorkout(workout.id!);
                _refreshRoutineWorkouts(routine.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Treino "${workout.name}" excluído'),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir treino: $e'),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ReorderableListView.builder(
        itemCount: _routines.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final Routine routine = _routines.removeAt(oldIndex);
            _routines.insert(newIndex, routine);
          });
        },
        itemBuilder: (context, index) {
          final routine = _routines[index];
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
                                _formatDate(routine.createdAt),
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

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

  Widget _buildRoutinesList() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadRoutines,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return _buildExpandableRoutineCard(routine, theme);
        },
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

  Widget _buildPopupMenu(Routine routine, ThemeData theme) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              const Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18),
              const SizedBox(width: 8),
              const Text('Excluir'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteDialog(routine);
        } else if (value == 'edit') {
          _editRoutine(routine);
        }
      },
    );
  }

  void _showDeleteDialog(Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Rotina'),
        content: Text('Tem certeza que deseja excluir "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _databaseService.routines.deleteRoutine(routine.id!);
              _loadRoutines();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rotina "${routine.name}" excluída!'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
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
