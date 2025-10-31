import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_craft/src/shared/constants/constants.dart';
import '../controllers/select_exercise_controller.dart';
import 'exercise_management_screen.dart';
import '../../models/exercise.dart';
import '../widgets/exercise_image_widget.dart';

class SelectExerciseScreen extends StatelessWidget {
  final List<int> excludeExerciseIds;

  const SelectExerciseScreen({Key? key, this.excludeExerciseIds = const []})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          SelectExerciseController(excludeExerciseIds: excludeExerciseIds)
            ..loadExercises(),
      child: const _SelectExerciseView(),
    );
  }
}

class _SelectExerciseView extends StatelessWidget {
  const _SelectExerciseView();

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectExerciseController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Selecionar Exercício'),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    _navigateToExerciseManagement(context, controller),
              ),
            ],
          ),
          body: _buildBody(context, controller, theme),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    SelectExerciseController controller,
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
        _buildExercisesList(context, controller, theme),
      ],
    );
  }

  Widget _buildFiltersSection(
    SelectExerciseController controller,
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
          ),
          const SizedBox(height: 12),

          // Filtro por categoria
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
    SelectExerciseController controller,
    ThemeData theme,
  ) {
    return Expanded(
      child: controller.filteredExercises.isEmpty
          ? _buildEmptyState(context, controller, theme)
          : ListView.builder(
              itemCount: controller.filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = controller.filteredExercises[index];
                return _buildExerciseCard(context, exercise, theme);
              },
            ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            Text(
              exercise.category,
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.getMuscleGroupColor(exercise.category),
              ),
            ),
            if (exercise.description?.isNotEmpty == true)
              Text(
                exercise.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: exercise.isCustom
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Personalizado',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => Navigator.pop(context, exercise),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    SelectExerciseController controller,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício encontrado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou criar um novo exercício',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToExerciseManagement(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Criar Exercício'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToExerciseManagement(
    BuildContext context,
    SelectExerciseController controller,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseManagementScreen()),
    );

    if (result == true || context.mounted) {
      controller.loadExercises();
    }
  }
}
