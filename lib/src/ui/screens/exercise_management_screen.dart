import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import '../widgets/edit_exercise_dialog.dart';
import '../widgets/exercise_image_widget.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../../shared/constants/constants.dart';
import '../controllers/exercise_management_controller.dart';

class ExerciseManagementScreen extends StatelessWidget {
  const ExerciseManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExerciseManagementController()..loadExercises(),
      child: const _ExerciseManagementView(),
    );
  }
}

class _ExerciseManagementView extends StatelessWidget {
  const _ExerciseManagementView();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseManagementController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: _buildAppBar(context, controller, theme),
          body: _buildBody(context, controller, theme),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ExerciseManagementController controller,
    ThemeData theme,
  ) {
    return AppBar(
      title: Text(
        'Gerenciar Exercícios',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(true),
      ),
      actions: [
        IconButton(
          onPressed: () => _addExercise(context, controller),
          icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
          tooltip: 'Adicionar Exercício',
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ExerciseManagementController controller,
    ThemeData theme,
  ) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadExercises(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFiltersSection(controller, theme),
        Expanded(child: _buildExercisesList(context, controller, theme)),
      ],
    );
  }

  Widget _buildFiltersSection(
    ExerciseManagementController controller,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            controller: controller.searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar exercícios...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => controller.onSearchChanged(),
          ),
          const SizedBox(height: 12),

          // Filtro de categoria
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                final isSelected = category == controller.selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) =>
                        controller.setSelectedCategory(category),
                    selectedColor: controller
                        .getCategoryColor(category)
                        .withOpacity(0.2),
                    checkmarkColor: controller.getCategoryColor(category),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? controller.getCategoryColor(category)
                          : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
    BuildContext context,
    ExerciseManagementController controller,
    ThemeData theme,
  ) {
    if (!controller.hasFilteredExercises) {
      return _buildEmptyState(context, controller, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = controller.filteredExercises[index];
        return _buildExerciseCard(context, controller, exercise, theme);
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ExerciseManagementController controller,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar exercícios',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addExercise(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Exercício'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseManagementController controller,
    Exercise exercise,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ExerciseImageWidget(
          imageUrl: exercise.imageUrl,
          width: 50,
          height: 50,
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.description?.isNotEmpty == true)
              Text(
                exercise.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.getMuscleGroupColor(
                      exercise.category,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        exercise.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.getMuscleGroupColor(
                            exercise.category,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (exercise.isCustom) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Personalizado',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editExercise(context, controller, exercise);
                break;
              case 'delete':
                _deleteExercise(context, controller, exercise);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _editExercise(context, controller, exercise),
      ),
    );
  }

  // Métodos de interação
  void _addExercise(
    BuildContext context,
    ExerciseManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditExerciseDialog(
        exercise: null,
        onUpdated: () => controller.onExerciseUpdated(),
      ),
    );
  }

  void _editExercise(
    BuildContext context,
    ExerciseManagementController controller,
    Exercise exercise,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditExerciseDialog(
        exercise: exercise,
        onUpdated: () => controller.onExerciseUpdated(),
      ),
    );
  }

  Future<void> _deleteExercise(
    BuildContext context,
    ExerciseManagementController controller,
    Exercise exercise,
  ) async {
    // Verificar se pode deletar
    final canDelete = await controller.canDeleteExercise(exercise.id!);

    if (!context.mounted) return;

    if (!canDelete) {
      SnackBarUtils.showWarning(
        context,
        'Não é possível excluir este exercício pois ele está sendo usado em treinos',
      );
      return;
    }

    // Confirmar exclusão
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o exercício "${exercise.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.deleteExercise(exercise);
      if (context.mounted) {
        if (controller.hasError) {
          SnackBarUtils.showError(context, controller.errorMessage!);
        } else {
          SnackBarUtils.showSuccess(context, 'Exercício excluído com sucesso!');
        }
      }
    }
  }
}
