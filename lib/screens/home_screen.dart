import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/routine.dart';
import 'create_routine_screen.dart';
import 'routine_detail_screen.dart';
import '../widgets/edit_routine_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Routine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final routines = await _databaseHelper.getAllRoutines();
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
        title: Text('Minhas Rotinas')
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
        icon: Icon(Icons.add),
        label: Text('Nova Rotina'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 120,
              color: Colors.grey[300],
            ),
            SizedBox(height: 24),
            Text(
              'Bem-vindo ao seu app de treinos!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Crie sua primeira rotina de treinos para começar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.lightbulb, color: Colors.indigo[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Dica:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Uma rotina pode conter vários treinos (ex: Treino A, Treino B, Push, Pull, etc.)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo[700],
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
    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                padding: EdgeInsets.all(20),
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
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteDialog(routine);
                            } else if (value == 'edit') {
                              _editRoutine(routine);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Edição em desenvolvimento')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    if (routine.description?.isNotEmpty == true) ...[
                      SizedBox(height: 8),
                      Text(
                        routine.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: routine.isActive ? Colors.green[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            routine.isActive ? 'ATIVA' : 'INATIVA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: routine.isActive ? Colors.green[700] : Colors.grey[700],
                            ),
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(routine.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tem certeza que deseja excluir a rotina:'),
              SizedBox(height: 8),
              Text(
                '"${routine.name}"',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Todos os treinos e exercícios desta rotina serão excluídos permanentemente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
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
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseHelper.deleteRoutine(routine.id!);
                _loadRoutines();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rotina "${routine.name}" excluída com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Excluir'),
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