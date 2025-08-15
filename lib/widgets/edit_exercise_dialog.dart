import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../database/database_helper.dart';

class EditExerciseDialog extends StatefulWidget {
  final Exercise? exercise; // null para criar novo
  final VoidCallback onUpdated;

  const EditExerciseDialog({
    Key? key,
    required this.exercise,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<EditExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  String _selectedCategory = 'Peito';

  final List<String> _categories = [
    'Peito',
    'Costas', 
    'Ombros',
    'Braços',
    'Pernas',
    'Abdomen',
    'Cardio',
    'Outros',
  ];

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _descriptionController = TextEditingController(text: widget.exercise?.description ?? '');
    _instructionsController = TextEditingController(text: widget.exercise?.instructions ?? '');
    
    if (widget.exercise != null) {
      _selectedCategory = widget.exercise!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final exercise = Exercise(
        id: widget.exercise?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
        isCustom: true, // Exercícios criados pelo usuário são sempre personalizados
        createdAt: widget.exercise?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _dbHelper.updateExercise(exercise);
      } else {
        await _dbHelper.insertExercise(exercise);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Exercício atualizado com sucesso!' 
                : 'Exercício criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao ${_isEditing ? 'atualizar' : 'criar'} exercício: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.add,
            color: Colors.indigo,
          ),
          const SizedBox(width: 8),
          Text(_isEditing ? 'Editar Exercício' : 'Novo Exercício'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo Nome
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Exercício',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    if (value.trim().length < 2) {
                      return 'Nome deve ter pelo menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Dropdown Categoria
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(category), size: 20),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Campo Descrição (opcional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    hintText: 'Breve descrição do exercício',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Campo Instruções (opcional)
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instruções (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list),
                    hintText: 'Como executar o exercício',
                  ),
                  maxLines: 4,
                ),
                
                // Informação sobre exercício personalizado
                if (_isEditing && !widget.exercise!.isCustom) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este é um exercício da biblioteca padrão. Suas alterações criarão uma cópia personalizada.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveExercise,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isEditing ? Icons.save : Icons.add, size: 18),
                    const SizedBox(width: 4),
                    Text(_isEditing ? 'Salvar' : 'Criar'),
                  ],
                ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'peito':
        return Icons.fitness_center;
      case 'costas':
        return Icons.back_hand;
      case 'ombros':
        return Icons.keyboard_arrow_up;
      case 'braços':
        return Icons.sports_martial_arts;
      case 'pernas':
        return Icons.directions_run;
      case 'abdomen':
        return Icons.center_focus_strong;
      case 'cardio':
        return Icons.favorite;
      default:
        return Icons.sports_gymnastics;
    }
  }
}