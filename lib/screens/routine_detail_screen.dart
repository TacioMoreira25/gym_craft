import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../utils/constants.dart';
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
  Map<String, dynamic> _stats = {};
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
      final stats = await _databaseService.routines.getRoutineStats(widget.routine.id!);

      final orderedWorkouts = await _applyCustomOrder(workouts);

      if (mounted) {
        setState(() {
          _workouts = orderedWorkouts;
          _stats = stats;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erro ao carregar dados: $e', isError: true);
      }
    }
  }

  Future<List<Workout>> _applyCustomOrder(List<Workout> workouts) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedOrder = prefs.getString('workout_order_${widget.routine.id}');

      if (savedOrder == null) return workouts;

      List<int> orderIds = List<int>.from(jsonDecode(savedOrder));
      List<Workout> orderedWorkouts = [];

      for (int id in orderIds) {
        Workout? workout = workouts.firstWhere(
          (w) => w.id == id,
          orElse: () => null as Workout,
        );
        if (workout != null) orderedWorkouts.add(workout);
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
      await prefs.setString('workout_order_${widget.routine.id}', jsonEncode(workoutIds));
    } catch (e) {
      print('Erro ao salvar ordem dos treinos: $e');
    }
  }

  void _exitReorderMode() => setState(() => _isReorderMode = false);

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF8B5A5A) : const Color(0xFF5A8B5A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isReorderMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isReorderMode) _exitReorderMode();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        appBar: _buildMinimalAppBar(isDark),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B6B6B)))
            : Column(
                children: [
                  if (!_isReorderMode) _buildHeaderSection(isDark),
                  Expanded(child: _buildWorkoutsSection(isDark)),
                ],
              ),
        floatingActionButton: !_isReorderMode ? _buildFAB() : null,
      ),
    );
  }

  AppBar _buildMinimalAppBar(bool isDark) {
    return AppBar(
      title: Text(
        _isReorderMode ? 'Reordenar Treinos' : widget.routine.name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF2A2A2A),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      elevation: 0,
      leading: _isReorderMode
          ? IconButton(
              icon: Icon(Icons.close, color: isDark ? Colors.white : const Color(0xFF2A2A2A)),
              onPressed: _exitReorderMode,
            )
          : IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF2A2A2A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (!_isReorderMode && _workouts.isNotEmpty)
          IconButton(
            onPressed: () => setState(() => _isReorderMode = true),
            icon: Icon(Icons.reorder, color: isDark ? Colors.white70 : const Color(0xFF6B6B6B)),
            tooltip: 'Reordenar',
          ),
        if (_isReorderMode)
          IconButton(
            onPressed: () async {
              await _saveWorkoutOrder();
              _exitReorderMode();
              _showSnackBar('Ordem salva');
            },
            icon: const Icon(Icons.check, color: Color(0xFF5A8B5A)),
            tooltip: 'Salvar',
          ),
      ],
    );
  }

  Widget _buildHeaderSection(bool isDark) {
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
                      ? const Color(0xFF5A8B5A).withOpacity(0.1)
                      : const Color(0xFF6B6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.routine.isActive
                        ? const Color(0xFF5A8B5A).withOpacity(0.3)
                        : const Color(0xFF6B6B6B).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.routine.isActive ? 'ATIVA' : 'INATIVA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.routine.isActive ? const Color(0xFF5A8B5A) : const Color(0xFF6B6B6B),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(widget.routine.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF8A8A8A),
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
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
              ),
            ),
          ],

          // Stats
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
              ),
            ),
            child: Row(
              children: [
                _buildStatItem('${_stats['workouts_count'] ?? 0}', 'treinos', isDark),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                ),
                _buildStatItem('${_stats['exercises_count'] ?? 0}', 'exercícios', isDark),
              ],
            ),
          ),

          // Grupos musculares
          if (_stats['muscle_groups'] != null && _stats['muscle_groups'].isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Grupos musculares',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (_stats['muscle_groups'] as List).map<Widget>((group) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsSection(bool isDark) {
    if (_workouts.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return _isReorderMode
        ? _buildReorderableList(isDark)
        : _buildWorkoutsList(isDark);
  }

  Widget _buildReorderableList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5A8B8B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF5A8B8B).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: const Color(0xFF5A8B8B)),
                const SizedBox(width: 8),
                Text(
                  'Arraste os itens para reordenar',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF5A8B8B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
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
                return _buildReorderableWorkoutCard(workout, index, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableWorkoutCard(Workout workout, int index, bool isDark) {
    return Container(
      key: ValueKey(workout.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_handle, color: isDark ? Colors.white30 : const Color(0xFFB0B0B0)),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
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
                  workout.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2A2A2A),
                  ),
                ),
                if (workout.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    workout.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF8A8A8A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList(bool isDark) {
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
              color: isDark ? Colors.white : const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildWorkoutCard(_workouts[index], index, isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
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
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
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
                          color: isDark ? Colors.white : const Color(0xFF2A2A2A),
                        ),
                      ),
                      if (workout.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          workout.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : const Color(0xFF8A8A8A),
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
                    color: isDark ? Colors.white30 : const Color(0xFFB0B0B0),
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          Icon(Icons.edit, size: 16, color: const Color(0xFF5A8B8B)),
                          const SizedBox(width: 8),
                          const Text('Editar', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: const Color(0xFF8B5A5A)),
                          const SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(fontSize: 14, color: const Color(0xFF8B5A5A))),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 40,
                color: isDark ? Colors.white30 : const Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum treino criado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione treinos à sua rotina',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF8A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateWorkoutScreen(routine: widget.routine),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  void _showDeleteWorkoutDialog(Workout workout) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Excluir treino?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2A2A2A),
            ),
          ),
          content: Text(
            'O treino "${workout.name}" será excluído permanentemente.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF8A8A8A),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.workouts.deleteWorkout(workout.id!);
                _loadData();
                _showSnackBar('Treino excluído', isError: true);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: Color(0xFF8B5A5A)),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
