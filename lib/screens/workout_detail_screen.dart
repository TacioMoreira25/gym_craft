import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_series.dart';
import '../models/series_type.dart';
import '../screens/select_exercise_screen.dart';
import '../widgets/add_workout_exercise_dialog.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/edit_workout_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<WorkoutExercise> _workoutExercises = [];
  bool _isLoading = true;
  bool _isReorderMode = false;
  late AnimationController _animationController;
  final Set<int> _expandedExercises = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadWorkoutExercises();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutExercises() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final exercises = await _databaseService.workoutExercises
          .getWorkoutExercisesWithDetails(widget.workout.id!);

      final orderedExercises = await _applyCustomOrder(exercises);

      if (mounted) {
        setState(() {
          _workoutExercises = orderedExercises;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarUtils.showOperationError(
          context,
          'carregar exercícios',
          e.toString(),
        );
      }
    }
  }

  Future<List<WorkoutExercise>> _applyCustomOrder(
    List<WorkoutExercise> exercises,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString(
        'exercise_order_${widget.workout.id}',
      );

      if (savedOrder == null) {
        return exercises;
      }

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<WorkoutExercise> orderedExercises = [];

      for (int id in orderIds) {
        final exercise = exercises.where((e) => e.id == id).firstOrNull;
        if (exercise != null) {
          orderedExercises.add(exercise);
        }
      }

      for (WorkoutExercise exercise in exercises) {
        if (!orderedExercises.any((e) => e.id == exercise.id)) {
          orderedExercises.add(exercise);
        }
      }

      return orderedExercises;
    } catch (e) {
      return exercises;
    }
  }

  Future<void> _saveExerciseOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<int> exerciseIds = _workoutExercises
          .map((exercise) => exercise.id!)
          .toList();
      await prefs.setString(
        'exercise_order_${widget.workout.id}',
        jsonEncode(exerciseIds),
      );
    } catch (e) {
      print('Erro ao salvar ordem dos exercícios: $e');
    }
  }

  Future<void> _addExercise() async {
    final Exercise? selectedExercise = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SelectExerciseScreen(),
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

    if (selectedExercise != null && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AddWorkoutExerciseDialog(
          workoutId: widget.workout.id!,
          selectedExercise: selectedExercise,
          onExerciseAdded: () {
            if (mounted) _loadWorkoutExercises();
          },
        ),
      );
    }
  }

  Future<void> _editWorkoutExercise(WorkoutExercise workoutExercise) async {
    final exerciseData = {
      'id': workoutExercise.id,
      'workout_id': workoutExercise.workoutId,
      'exercise_id': workoutExercise.exerciseId,
      'order_index': workoutExercise.orderIndex,
      'notes': workoutExercise.notes,
      'created_at': workoutExercise.createdAt.millisecondsSinceEpoch,
      'exercise_name': workoutExercise.exercise?.name ?? 'Exercício',
      'category': workoutExercise.exercise?.category ?? '',
      'description': workoutExercise.exercise?.description ?? '',
      'instructions': workoutExercise.exercise?.instructions ?? '',
      'image_url': workoutExercise.exercise?.imageUrl,
    };

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => EditWorkoutExerciseDialog(
        workoutExerciseData: exerciseData,
        onUpdated: () {},
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      await _loadWorkoutExercises();
      SnackBarUtils.showSuccess(context, 'Exercício atualizado com sucesso!');
    }
  }

  void _deleteExercise(WorkoutExercise workoutExercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange[600], size: 28),
              const SizedBox(width: 12),
              const Text('Confirmar Exclusão'),
            ],
          ),
          content: Text(
            'Tem certeza que deseja remover "${workoutExercise.exercise?.name ?? 'este exercício'}" deste treino?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.workoutExercises.deleteWorkoutExercise(
                  workoutExercise.id!,
                );
                if (mounted) {
                  _loadWorkoutExercises();
                  SnackBarUtils.showSuccess(
                    context,
                    'Exercício removido do treino!',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  void _exitReorderMode() {
    setState(() => _isReorderMode = false);
  }

  bool _isValidText(String? text) {
    if (text == null) return false;

    final cleanText = text.replaceAll(
      RegExp(r'[\s\u0000-\u001F\u007F-\u009F\uFEFF\u200B-\u200D\uFFF0-\uFFFF]'),
      '',
    );

    return cleanText.isNotEmpty;
  }

  String _formatRestTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}min ${remainingSeconds}s';
      }
    }
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
                  Expanded(child: _buildExercisesSection(theme)),
                ],
              ),
        floatingActionButton: !_isReorderMode ? _buildFAB() : null,
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        _isReorderMode ? 'Reordenar Exercícios' : widget.workout.name,
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
        if (!_isReorderMode && _workoutExercises.isNotEmpty)
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
              await _saveExerciseOrder();
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
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descrição do treino
          if (widget.workout.description?.isNotEmpty == true) ...[
            Text(
              widget.workout.description!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stats compactas
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
                  _workoutExercises.length.toString(),
                  'Exercícios',
                  theme,
                ),
                _buildStatItem(_getTotalSeries().toString(), 'Séries', theme),
                _buildStatItem(
                  '${_calculateEstimatedTime()}min',
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

  Widget _buildExercisesSection(ThemeData theme) {
    if (_workoutExercises.isEmpty) {
      return _buildEmptyState();
    }

    return _isReorderMode
        ? _buildReorderableList(theme)
        : _buildExercisesList(theme);
  }

  Widget _buildReorderableList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ReorderableListView.builder(
        itemCount: _workoutExercises.length,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final WorkoutExercise item = _workoutExercises.removeAt(oldIndex);
            _workoutExercises.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final workoutExercise = _workoutExercises[index];
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

  Widget _buildExercisesList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercícios (${_workoutExercises.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _workoutExercises.length,
              itemBuilder: (context, index) {
                return _buildModernExerciseCard(
                  _workoutExercises[index],
                  index,
                  theme,
                  false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _addExercise,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
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
              child: Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
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
    final isExpanded = _expandedExercises.contains(workoutExercise.id);

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
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedExercises.remove(workoutExercise.id);
                  } else {
                    _expandedExercises.add(workoutExercise.id!);
                  }
                });
              },
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise?.name ?? 'Exercício',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                              ),
                              if (series.isNotEmpty) ...[
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
                            ],
                          ),
                          if ((exercise?.category ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              exercise?.category ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    color: Colors.red[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Remover',
                                    style: TextStyle(color: Colors.red[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editWorkoutExercise(workoutExercise);
                                break;
                              case 'delete':
                                _deleteExercise(workoutExercise);
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
              final sIndex = entry.key;
              final s = entry.value;
              final typeColor = AppConstants.getSeriesTypeColor(s.type);
              final typeName = AppConstants.getSeriesTypeName(s.type);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(
                    isDark ? 0.1 : 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: typeColor.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: typeColor.withOpacity(0.7),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${sIndex + 1}ª  $typeName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _buildSeriesText(s, sIndex + 1, typeName),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isValidText(s.notes)) ...[
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

          if (_isValidText(workoutExercise.notes)) ...[
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
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

  String _buildSeriesText(
    WorkoutSeries series,
    int seriesNumber,
    String typeName,
  ) {
    switch (series.type) {
      case SeriesType.rest:
        return ' ${_formatRestTime(series.restSeconds ?? 0)}';

      case SeriesType.warmup:
      case SeriesType.recognition:
        return '${series.repetitions ?? 0} reps | ${_formatRestTime(series.restSeconds!)} pausa';

      default:
        String text = '${series.repetitions ?? 0} reps';
        if (series.weight != null && series.weight! > 0) {
          text += ' | ${series.weight}kg';
        }
        if (series.restSeconds != null && series.restSeconds! > 0) {
          text += ' | ${_formatRestTime(series.restSeconds!)} pausa';
        }
        return text;
    }
  }

  int _getTotalSeries() {
    return _workoutExercises.fold<int>(0, (sum, ex) => sum + ex.series.length);
  }

  int _calculateEstimatedTime() {
    int totalTime = 0;
    for (final workoutExercise in _workoutExercises) {
      final series = workoutExercise.series;

      for (final s in series) {
        if (s.type == SeriesType.rest) {
          totalTime += s.restSeconds ?? 30;
        } else {
          totalTime += 30;
          if (s.restSeconds != null) {
            totalTime += s.restSeconds!;
          }
        }
      }
    }
    return (totalTime / 60).ceil();
  }
}
