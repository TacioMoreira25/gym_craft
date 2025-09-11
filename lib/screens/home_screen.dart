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

  // Método para lidar com o botão voltar
  Future<bool> _onWillPop() async {
    if (_isReorderMode) {
      _exitReorderMode();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isReorderMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isReorderMode) {
          _exitReorderMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isReorderMode ? 'Reordenar Rotinas' : 'Minhas Rotinas'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: _isReorderMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitReorderMode,
                )
              : null,
          actions: [
            if (!_isReorderMode && _routines.isNotEmpty)
              IconButton(
                onPressed: () {
                  setState(() => _isReorderMode = true);
                },
                icon: const Icon(Icons.reorder),
                tooltip: 'Reordenar Rotinas',
              ),
            if (_isReorderMode)
              IconButton(
                onPressed: () async {
                  await _saveRoutineOrder();
                  _exitReorderMode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ordem das rotinas salva!'),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                tooltip: 'Salvar Ordem',
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
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                icon: const Icon(Icons.add),
                label: const Text('Nova Rotina'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
    );
  }

  Widget _buildReorderableList() {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
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
        return Card(
          key: ValueKey('routine_${routine.id}'),
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Indicador de posição
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informações da rotina
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (routine.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          routine.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: routine.isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          routine.isActive ? 'ATIVA' : 'INATIVA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: routine.isActive
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Handle para arrastar
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        Text(
                          'Arraste',
                          style: TextStyle(
                            fontSize: 10,
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 120,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Bem-vindo ao seu app de treinos!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Crie sua primeira rotina de treinos para começar',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dica:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uma rotina pode conter vários treinos (ex: Treino A, Treino B, Push, Pull, etc.)',
                    style: TextStyle(
                      fontSize: 14,
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
    );
  }

  Widget _buildRoutinesList() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: theme.colorScheme.surface,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: theme.colorScheme.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
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
                        ),
                      ],
                    ),
                    if (routine.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        routine.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: routine.isActive
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            routine.isActive ? 'ATIVA' : 'INATIVA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: routine.isActive
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(routine.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

  void _showDeleteDialog(Routine routine) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Confirmar Exclusão',
            style: TextStyle(color: theme.colorScheme.onSurface),
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Todos os treinos e exercícios desta rotina serão excluídos permanentemente.',
                        style: TextStyle(
                          fontSize: 12,
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
              child: Text(
                'Cancelar',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.routines.deleteRoutine(routine.id!);
                _loadRoutines();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rotina "${routine.name}" excluída com sucesso!'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
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
