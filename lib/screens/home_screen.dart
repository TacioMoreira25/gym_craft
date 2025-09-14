import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gym_craft/models/series_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/routine.dart';
import '../utils/constants.dart';
import 'create_routine_screen.dart';
import 'routine_detail_screen.dart';
import 'settings_screen.dart';
import '../widgets/edit_routine_dialog.dart';

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
        Routine? routine = routines.firstWhere(
          (r) => r.id == id,
          orElse: () => null as Routine,
        );
        if (routine != null) {
          orderedRoutines.add(routine);
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

  Future<bool> _onWillPop() async {
    if (_isReorderMode) {
      _exitReorderMode();
      return false;
    }
    return true;
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
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Text(_isReorderMode ? 'Reordenar Rotinas' : 'Minhas Rotinas'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          leading: _isReorderMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _exitReorderMode,
                )
              : null,
          actions: [
            if (!_isReorderMode && _routines.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    setState(() => _isReorderMode = true);
                  },
                  icon: const Icon(Icons.reorder_rounded),
                  tooltip: 'Reordenar Rotinas',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            if (_isReorderMode)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () async {
                    await _saveRoutineOrder();
                    _exitReorderMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Ordem das rotinas salva!'),
                        backgroundColor: AppConstants.getSeriesTypeColor(SeriesType.valid, isDark: isDark),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Salvar Ordem',
                  style: IconButton.styleFrom(
                    backgroundColor: AppConstants.getSeriesTypeColor(SeriesType.valid, isDark: isDark),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (!_isReorderMode)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: 'Configurações',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
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
                    MaterialPageRoute(builder: (context) => CreateRoutineScreen()),
                  ).then((_) => _loadRoutines());
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova Rotina'),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 4,
              ),
      ),
    );
  }

  Widget _buildReorderableList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.background,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
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
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: isDark ? 8 : 4,
              shadowColor: theme.colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Position indicator with modern gradient
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Routine information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (routine.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              routine.description!,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildStatusBadge(routine, theme, isDark),
                        ],
                      ),
                    ),
                    // Drag handle with modern design
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.drag_indicator_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Arraste',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.background,
          ],
          stops: const [0.0, 0.4],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bem-vindo ao GymCraft!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Crie sua primeira rotina de treinos para começar sua jornada fitness',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  boxShadow: AppConstants.getCardShadow(isDark),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dica Rápida',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uma rotina pode conter vários treinos (ex: Treino A, Treino B, Push, Pull, etc.)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildRoutinesList() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.background,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadRoutines,
        color: theme.colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _routines.length,
          itemBuilder: (context, index) {
            final routine = _routines[index];
            return _buildRoutineCard(routine, theme);
          },
        ),
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isDark ? 8 : 4,
        shadowColor: theme.colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoutineDetailScreen(routine: routine),
              ),
            ).then((_) => _loadRoutines());
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.8),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        routine.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildPopupMenu(routine, theme, isDark),
                  ],
                ),
                if (routine.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    routine.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatusBadge(routine, theme, isDark),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(routine.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildStatusBadge(Routine routine, ThemeData theme, bool isDark) {
    final statusConfigs = AppConstants.getStatusConfigs(isDark);
    final config = statusConfigs[routine.isActive ? 'active' : 'inactive']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config['color'].withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config['text'],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(Routine routine, ThemeData theme, bool isDark) {
    return PopupMenuButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                size: 18,
                color: theme.colorScheme.primary,
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
                color: theme.colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Excluir',
                style: TextStyle(color: theme.colorScheme.error),
              ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirmar Exclusão',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tem certeza que deseja excluir a rotina:',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                '"${routine.name}"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Todos os treinos e exercícios desta rotina serão excluídos permanentemente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.routines.deleteRoutine(routine.id!);
                _loadRoutines();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rotina "${routine.name}" excluída!'),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
