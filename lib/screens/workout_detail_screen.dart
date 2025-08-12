import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/workout.dart';
import '../utils/constants.dart';
import 'add_exercise_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    final exercises = await _databaseHelper.getWorkoutExercises(widget.workout.id!);
    
    setState(() {
      _exercises = exercises;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExerciseScreen(workout: widget.workout),
                ),
              ).then((_) => _loadExercises());
            },
            tooltip: 'Adicionar Exercício',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do treino
                  _buildWorkoutInfo(),
                  SizedBox(height: 20),
                  
                  // Lista de exercícios
                  _buildExercisesList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExerciseScreen(workout: widget.workout),
            ),
          ).then((_) => _loadExercises());
        },
        icon: Icon(Icons.add),
        label: Text('Adicionar Exercício'),
        backgroundColor: Colors.indigo[700],
      ),
    );
  }

  Widget _buildWorkoutInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo[600]),
                SizedBox(width: 8),
                Text(
                  'Informações do Treino',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (widget.workout.description != null && widget.workout.description!.isNotEmpty) ...[
              Text(
                widget.workout.description!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${_exercises.length} exercícios',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  'Criado em ${_formatDate(widget.workout.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercícios (${_exercises.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        if (_exercises.isEmpty)
          _buildEmptyExercises()
        else
          ...List.generate(_exercises.length, (index) {
            final exercise = _exercises[index];
            return _buildExerciseCard(exercise, index);
          }),
      ],
    );
  }

  Widget _buildEmptyExercises() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.sports_gymnastics, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Nenhum exercício adicionado ainda',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toque no + para adicionar exercícios a este treino',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final muscleGroup = exercise['muscle_group'];
    final color = AppConstants.muscleGroupColors[muscleGroup] ?? Colors.grey;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do exercício
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${exercise['exercise_name']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          muscleGroup,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
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
                      _showDeleteExerciseDialog(exercise);
                    } else if (value == 'edit') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edição em desenvolvimento')),
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Informações de séries, reps, peso
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.repeat,
                  label: '${exercise['sets']} séries',
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.fitness_center,
                  label: '${exercise['reps']} reps',
                  color: Colors.green,
                ),
                if (exercise['weight'] != null) ...[
                  SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.monitor_weight,
                    label: '${exercise['weight']}kg',
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
            
            // Tempo de descanso e notas
            if (exercise['rest_time'] != null || (exercise['notes'] != null && exercise['notes'].isNotEmpty)) ...[
              SizedBox(height: 8),
              if (exercise['rest_time'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Descanso: ${_formatRestTime(exercise['rest_time'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
              ],
              if (exercise['notes'] != null && exercise['notes'].isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        exercise['notes'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteExerciseDialog(Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja remover "${exercise['exercise_name']}" deste treino?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseHelper.deleteWorkoutExercise(exercise['id']);
                _loadExercises();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exercício removido do treino!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatRestTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return minutes > 0 
        ? '${minutes}min ${remainingSeconds}s'
        : '${remainingSeconds}s';
  }
}