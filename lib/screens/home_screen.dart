import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final routines = await _databaseService.routines.getAllRoutines();
    setState(() {
      _routines = routines;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Rotinas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Botão de configurações
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
              : _buildRoutinesList(),
      floatingActionButton: FloatingActionButton.extended(
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