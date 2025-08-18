import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../database/database_helper.dart';
import '../widgets/exercise_image_widget.dart';

class AddExerciseScreen extends StatefulWidget {
  final Exercise? exercise;

  const AddExerciseScreen({super.key, this.exercise});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Peito';
  bool _isLoading = false;

  final List<String> _categories = [
    'Peito',
    'Costas',
    'Quadríceps',
    'Posterior',
    'Panturrilhas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdomen',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.name;
      _descriptionController.text = widget.exercise!.description ?? '';
      _instructionsController.text = widget.exercise!.instructions ?? '';
      _imageUrlController.text = widget.exercise!.imageUrl ?? '';
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

  bool _isValidUrl(String url) {
    if (url.isEmpty) return true; 
    return Uri.tryParse(url) != null && 
           (url.startsWith('http://') || url.startsWith('https://'));
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final exercise = Exercise(
        id: widget.exercise?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        category: _selectedCategory,
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        createdAt: widget.exercise?.createdAt ?? DateTime.now(),
        isCustom: widget.exercise?.isCustom ?? true,
      );

      if (widget.exercise == null) {
        await DatabaseHelper().insertExercise(exercise);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercício adicionado com sucesso!')),
        );
      } else {
        await DatabaseHelper().updateExercise(exercise);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercício atualizado com sucesso!')),
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar exercício: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? 'Adicionar Exercício' : 'Editar Exercício'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveExercise,
              child: const Text('SALVAR'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview da imagem
            if (_imageUrlController.text.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExerciseImageWidget(
                    imageUrl: _imageUrlController.text,
                    width: 120,
                    height: 120,
                    category: _selectedCategory,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            // Campo Nome
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Exercício *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, informe o nome do exercício';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campo Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),

            const SizedBox(height: 16),

            // Campo URL da Imagem
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL da Imagem (opcional)',
                border: OutlineInputBorder(),
                hintText: 'https://exemplo.com/imagem.jpg',
                prefixIcon: Icon(Icons.image),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !_isValidUrl(value)) {
                  return 'Por favor, informe uma URL válida';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Atualizar preview
              },
            ),

            const SizedBox(height: 8),

            // Dica sobre imagem
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Como adicionar imagem:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Procure a imagem no Google Images\n'
                    '2. Clique com botão direito na imagem\n'
                    '3. Selecione "Copiar endereço da imagem"\n'
                    '4. Cole aqui no campo acima',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Campo Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Campo Instruções
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instruções',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}