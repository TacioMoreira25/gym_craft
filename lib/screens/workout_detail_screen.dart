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
import '../widgets/edit_workout_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';
import '../widgets/ImageViewerDialog.dart';

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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
        _showSnackBar('Erro ao carregar exercícios: $e', isError: true);
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
        WorkoutExercise? exercise = exercises.firstWhere(
          (e) => e.id == id,
          orElse: () => null as WorkoutExercise,
        );
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
      _showSnackBar('Exercício atualizado com sucesso!');
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
                  _showSnackBar('Exercício removido do treino!', isError: true);
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
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isReorderMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isReorderMode) {
          _exitReorderMode();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(theme, isDark),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (!_isReorderMode) _buildStatsSection(theme, isDark),
              _buildExercisesSection(theme, isDark),
            ],
          ],
        ),
        floatingActionButton: !_isReorderMode
            ? _buildFloatingActionButton(theme)
            : null,
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: _isReorderMode ? 120 : 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.indigo[800]!, Colors.purple[800]!]
                  : [Colors.indigo[600]!, Colors.purple[600]!],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _isReorderMode
                        ? 'Reordenar Exercícios'
                        : widget.workout.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isReorderMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Toque nos exercícios para editar',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      leading: _isReorderMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: _exitReorderMode,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (!_isReorderMode && _workoutExercises.isNotEmpty)
          IconButton(
            onPressed: () => setState(() => _isReorderMode = true),
            icon: const Icon(Icons.reorder_rounded, color: Colors.white),
            tooltip: 'Reordenar Exercícios',
          ),
        if (_isReorderMode)
          IconButton(
            onPressed: () async {
              await _saveExerciseOrder();
              _exitReorderMode();
              _showSnackBar('Ordem dos exercícios salva!');
            },
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            tooltip: 'Salvar Ordem',
          ),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey[850]!, Colors.grey[800]!]
                    : [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModernStatCard(
                  'Exercícios',
                  _workoutExercises.length.toString(),
                  Icons.fitness_center_rounded,
                  Colors.blue[600]!,
                  isDark,
                ),
                _buildModernStatCard(
                  'Séries Total',
                  _getTotalSeries().toString(),
                  Icons.repeat_rounded,
                  Colors.green[600]!,
                  isDark,
                ),
                _buildModernStatCard(
                  'Tempo Est.',
                  '${_calculateEstimatedTime()}min',
                  Icons.timer_rounded,
                  Colors.orange[600]!,
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesSection(ThemeData theme, bool isDark) {
    if (_workoutExercises.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(isDark));
    }

    return _isReorderMode
        ? _buildReorderableExercisesList(theme, isDark)
        : _buildExercisesList(theme, isDark);
  }

  Widget _buildExercisesList(ThemeData theme, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildModernExerciseCard(
                _workoutExercises[index],
                index,
                theme,
                isDark,
              ),
            ),
          );
        }, childCount: _workoutExercises.length),
      ),
    );
  }

  Widget _buildReorderableExercisesList(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Arraste os exercícios para reordená-los',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _workoutExercises.length,
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final WorkoutExercise item = _workoutExercises.removeAt(
                    oldIndex,
                  );
                  _workoutExercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final workoutExercise = _workoutExercises[index];
                return _buildReorderableExerciseCard(
                  workoutExercise,
                  index,
                  theme,
                  isDark,
                );
              },
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editWorkoutExercise(workoutExercise),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                  ],
                ),

                if (series.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[100]!, Colors.amber[50]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_rounded,
                          size: 18,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            workoutExercise.notes!.trim(),
                            style: TextStyle(
                              fontSize: 13,
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
          ),
        ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[800]!]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.drag_handle_rounded, color: Colors.grey[500]),
            const SizedBox(width: 12),
            ExerciseImageWidget(
              imageUrl: exercise?.imageUrl,
              width: 50,
              height: 50,
              category: exercise?.category,
              borderRadius: BorderRadius.circular(12),
              enableTap: false,
              exerciseName: exercise?.name ?? 'Exercício',
            ),
            const SizedBox(width: 12),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [muscleGroupColor, muscleGroupColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: muscleGroupColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: muscleGroupColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: muscleGroupColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 12,
                          color: muscleGroupColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise?.category ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: muscleGroupColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _addExercise,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum exercício adicionado',
              style: TextStyle(
                fontSize: 24,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comece adicionando exercícios ao seu treino',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar Exercício'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
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
        return '$seriesNumberª $typeName: ${_formatRestTime(series.restSeconds ?? 0)}';

      case SeriesType.warmup:
      case SeriesType.recognition:
        return '$seriesNumberª $typeName: ${series.repetitions ?? 0} reps';

      default:
        String text =
            '$seriesNumberª $typeName: ${series.repetitions ?? 0} reps';
        if (series.weight != null && series.weight! > 0) {
          text += ' | ${series.weight}kg';
        }
        if (series.restSeconds != null && series.restSeconds! > 0) {
          text += ' | ${_formatRestTime(series.restSeconds!)} desc';
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
