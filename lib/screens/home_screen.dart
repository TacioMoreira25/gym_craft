import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/routine.dart';
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
            _isReorderMode ? 'Reordenar Rotinas' : 'Minhas Rotinas',
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
                icon: Icon(
                  Icons.reorder,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Reordenar',
              ),
            if (_isReorderMode)
              IconButton(
                onPressed: () async {
                  await _saveRoutineOrder();
                  _exitReorderMode();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: const Text('Ordem salva')));
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

  Widget _buildReorderableList() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
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
                            routine.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (routine.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              routine.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
          return _buildRoutineCard(routine, theme);
        },
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine, ThemeData theme) {
    return Container(
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoutineDetailScreen(routine: routine),
              ),
            ).then((_) => _loadRoutines());
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    _buildPopupMenu(routine, theme),
                  ],
                ),
                if (routine.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    routine.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatusBadge(routine, theme),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
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
                  SnackBar(content: Text('Rotina "${routine.name}" excluída!')),
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
