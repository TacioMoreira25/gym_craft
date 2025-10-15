import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../data/services/database_service.dart';
import 'exercise_image_widget.dart';
import '../../shared/constants/constants.dart';
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/snackbar_utils.dart';

class EditExerciseDialog extends StatefulWidget {
  final Exercise? exercise;
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
  late TextEditingController _imageUrlController;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String _selectedCategory = 'Peito';

  final List<String> _categories = ['Todos', ...AppConstants.muscleGroups];

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.exercise?.description ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.exercise?.instructions ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.exercise?.imageUrl ?? '',
    );

    if (widget.exercise != null) {
      _selectedCategory = widget.exercise!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
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
        imageUrl:
            _imageUrlController.text
                .trim()
                .isEmpty // Novo campo
            ? null
            : _imageUrlController.text.trim(),
        createdAt: widget.exercise?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _databaseService.exercises.updateExercise(exercise);
      } else {
        await _databaseService.exercises.insertExercise(exercise);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdated();
        SnackBarUtils.showSuccess(
          context,
          _isEditing
              ? 'Exercício atualizado com sucesso!'
              : 'Exercício criado com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showOperationError(
          context,
          '${_isEditing ? 'atualizar' : 'criar'} exercício',
          e.toString(),
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
          Icon(_isEditing ? Icons.edit : Icons.add, color: Colors.indigo),
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
                // Preview da imagem
                if (_imageUrlController.text.isNotEmpty) ...[
                  Center(
                    child: ExerciseImageWidget(
                      imageUrl: _imageUrlController.text,
                      width: 100,
                      height: 100,
                      category: _selectedCategory,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Campo Nome
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Exercício',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  validator: ValidationUtils.validateExerciseName,
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
                        children: [const SizedBox(width: 8), Text(category)],
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

                // Campo URL da Imagem - NOVO
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                    hintText: 'https://exemplo.com/imagem.jpg',
                  ),
                  validator: ValidationUtils.validateImageUrl,
                  onChanged: (value) {
                    setState(() {}); // Atualizar preview
                  },
                ),
                const SizedBox(height: 8),

                // Dica sobre imagem - NOVO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '💡 Dica: Clique direito na imagem → "Copiar endereço da imagem"',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
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
                  maxLines: 3,
                ),

                // Informação sobre exercício personalizado
                if (_isEditing &&
                    widget.exercise != null &&
                    !widget.exercise!.isCustom) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
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
}
