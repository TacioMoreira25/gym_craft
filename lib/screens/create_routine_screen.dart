import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/routine.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  _CreateRoutineScreenState createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _routineSuggestions = [
    'Push Pull Legs',
    'Upper Lower',
    'Full Body',
    'ABC Tradicional',
    'ABCD Split',
    'Ganho de Massa',
    'Definição',
    'Força',
    'Iniciante',
    'Avançado',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Rotina'),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: Text(
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
              // Informações da rotina
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações da Rotina',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome da Rotina',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.fitness_center),
                          hintText: 'Ex: Push Pull Legs',
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
                          hintText: 'Descreva o objetivo desta rotina...',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Descrição é obrigatória';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Sugestões de nomes
              Text(
                'Sugestões de Nomes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _routineSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _nameController.text = suggestion;
                      if (_descriptionController.text.isEmpty) {
                        _descriptionController.text = _getDescriptionSuggestion(suggestion);
                      }
                    },
                    backgroundColor: Colors.indigo[50],
                    labelStyle: TextStyle(color: Colors.indigo[700]),
                  );
                }).toList(),
              ),
              SizedBox(height: 32),

              // Informações sobre próximos passos
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          'Próximos passos:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Salve esta rotina\n'
                      '2. Adicione treinos (ex: Treino A, Push, Peito e Tríceps)\n'
                      '3. Em cada treino, adicione exercícios com séries e repetições',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
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

  String _getDescriptionSuggestion(String routineName) {
    switch (routineName) {
      case 'Push Pull Legs':
        return 'Rotina dividida em treinos de empurrar, puxar e pernas';
      case 'Upper Lower':
        return 'Divisão entre membros superiores e inferiores';
      case 'Full Body':
        return 'Treino completo trabalhando corpo todo';
      case 'ABC Tradicional':
        return 'Divisão clássica em três treinos diferentes';
      case 'ABCD Split':
        return 'Divisão em quatro treinos específicos';
      case 'Ganho de Massa':
        return 'Foco no desenvolvimento de massa muscular';
      case 'Definição':
        return 'Rotina voltada para definição e queima de gordura';
      case 'Força':
        return 'Treinamento focado no ganho de força';
      case 'Iniciante':
        return 'Rotina adequada para iniciantes';
      case 'Avançado':
        return 'Rotina para praticantes avançados';
      default:
        return 'Rotina personalizada de treinos';
    }
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final routine = Routine(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _databaseHelper.insertRoutine(routine);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rotina criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar rotina: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}