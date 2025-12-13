import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import 'exercise_image_widget.dart';
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/edit_exercise_controller.dart';

class EditExerciseDialog extends StatelessWidget {
  final Exercise? exercise;
  final VoidCallback onUpdated;

  const EditExerciseDialog({
    Key? key,
    required this.exercise,
    required this.onUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          EditExerciseController(exercise: exercise, onUpdated: onUpdated),
      child: Consumer<EditExerciseController>(
        builder: (context, controller, child) {
          return AlertDialog(
            title: _buildTitle(controller),
            content: _buildContent(context, controller),
            actions: _buildActions(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildTitle(EditExerciseController controller) {
    return Row(
      children: [
        Icon(
          controller.isEditing ? Icons.edit : Icons.add,
          color: Colors.indigo,
        ),
        const SizedBox(width: 8),
        Text(controller.dialogTitle),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    EditExerciseController controller,
  ) {
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview da imagem
              if (controller.hasImageUrl) ...[
                Center(
                  child: ExerciseImageWidget(
                    imageUrl: controller.imageUrlController.text,
                    width: 100,
                    height: 100,
                    category: controller.selectedCategory,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo Nome
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Exercício',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateExerciseName,
              ),
              const SizedBox(height: 16),

              // Dropdown Categoria
              DropdownButtonFormField<String>(
                value: controller.selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: controller.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [const SizedBox(width: 8), Text(category)],
                    ),
                  );
                }).toList(),
                onChanged: (value) => controller.setSelectedCategory(value!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL da Imagem (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'https://exemplo.com/imagem.jpg',
                      ),
                      validator: ValidationUtils.validateImageUrl,
                      onChanged: (_) => controller.onImageUrlChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => controller.searchImageOnGoogle(context),
                    icon: const Icon(Icons.search),
                    tooltip: 'Buscar imagem no Google',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (controller.hasClipboardImage) ...[
                _buildClipboardSuggestion(controller),
                const SizedBox(height: 8),
              ],

              _buildImageTip(),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Breve descrição do exercício',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Campo Instruções
              TextFormField(
                controller: controller.instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instruções (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Como executar o exercício',
                ),
                maxLines: 3,
              ),

              // Informação sobre exercício personalizado
              if (controller.shouldShowCustomInfo) ...[
                const SizedBox(height: 16),
                _buildCustomInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClipboardSuggestion(EditExerciseController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.content_paste, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link de imagem detectado!',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  controller.clipboardImageUrl!.length > 50
                      ? '${controller.clipboardImageUrl!.substring(0, 50)}...'
                      : controller.clipboardImageUrl!,
                  style: TextStyle(color: Colors.green[600], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: controller.useClipboardImage,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: const Text('Usar', style: TextStyle(fontSize: 12)),
              ),
              IconButton(
                onPressed: controller.dismissClipboardSuggestion,
                icon: const Icon(Icons.close),
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                style: IconButton.styleFrom(foregroundColor: Colors.green[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.blue[700], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '1. Clique em "🔍" para buscar no Google Imagens',
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.content_copy, color: Colors.blue[700], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '2. Clique direito na imagem → "Copiar endereço da imagem"',
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: Colors.blue[700], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '3. O app detectará automaticamente e sugerirá o uso!',
                  style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    EditExerciseController controller,
  ) {
    return [
      TextButton(
        onPressed: controller.isLoading
            ? null
            : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () => _saveExercise(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: controller.isLoading
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
                  Icon(controller.isEditing ? Icons.save : Icons.add, size: 18),
                  const SizedBox(width: 4),
                  Text(controller.buttonText),
                ],
              ),
      ),
    ];
  }

  Future<void> _saveExercise(
    BuildContext context,
    EditExerciseController controller,
  ) async {
    final success = await controller.saveExercise();

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(context, controller.successMessage);
      } else if (controller.hasError) {
        SnackBarUtils.showError(context, controller.errorMessage!);
      }
    }
  }
}
