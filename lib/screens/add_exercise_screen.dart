import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';
import '../utils/constants.dart';

class AddExerciseScreen extends StatefulWidget {
  final Workout workout;

  const AddExerciseScreen({super.key, required this.workout});

  @override
  _AddExerciseScreenState createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controladores para o novo exercício
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  
  // Controladores para configurações do treino
  final TextEditingController _setsController = TextEditingController(text: '3');
  final TextEditingController _repsController = TextEditingController(text: '12');
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _restTimeController = TextEditingController(text: '60');
  final TextEditingController _notesController = TextEditingController();

  String _selectedMuscleGroup = 'Peito';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Exercício'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExercise,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'SALVAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info do treino
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.indigo[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adicionando exercício para:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo[700],
                            ),
                          ),
                          Text(
                            widget.workout.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Informações do exercício
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Novo Exercício',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome do Exercício',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports_gymnastics),
                          hintText: 'Ex: Supino Reto, Agachamento...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Breve descrição do exercício...',
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Descrição é obrigatória';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedMuscleGroup,
                        decoration: InputDecoration(
                          labelText: 'Grupo Muscular',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.fitness_center),
                        ),
                        items: AppConstants.muscleGroups.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppConstants.muscleGroupColors[value],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(value),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMuscleGroup = newValue!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _instructionsController,
                        decoration: InputDecoration(
                          labelText: 'Instruções (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                          hintText: 'Como executar o exercício...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Configurações do treino
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurações do Treino',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _setsController,
                              decoration: InputDecoration(
                                labelText: 'Séries',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.repeat),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Obrigatório';
                                }
                                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _repsController,
                              decoration: InputDecoration(
                                labelText: 'Repetições',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.fitness_center),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Obrigatório';
                                }
                                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'Peso (kg) - Opcional',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monitor_weight),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _restTimeController,
                              decoration: InputDecoration(
                                labelText: 'Descanso (seg)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                          hintText: 'Observações sobre execução, progressão, etc...',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Aviso sobre biblioteca
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.green[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biblioteca automática:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ao salvar, este exercício será automaticamente adicionado à sua biblioteca para reuso em outros treinos.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
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
      ),
    );
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Criar ou buscar exercício na biblioteca
      final exerciseId = await _databaseHelper.getOrCreateExercise(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _selectedMuscleGroup,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
      );

      // Obter próximo order_index
      final existingExercises = await _databaseHelper.getWorkoutExercises(widget.workout.id!);
      final nextOrder = existingExercises.length;

      // Criar workout_exercise
      final workoutExercise = WorkoutExercise(
        workoutId: widget.workout.id!,
        exerciseId: exerciseId,
        sets: int.parse(_setsController.text),
        reps: int.parse(_repsController.text),
        weight: _weightController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_weightController.text),
        restTime: _restTimeController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_restTimeController.text),
        orderIndex: nextOrder,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      await _databaseHelper.insertWorkoutExercise(workoutExercise);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exercício adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar exercício: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}