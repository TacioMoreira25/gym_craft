import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../shared/utils/snackbar_utils.dart';
import '../controllers/create_workout_controller.dart';

class CreateWorkoutScreen extends StatelessWidget {
  final Routine routine;

  const CreateWorkoutScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateWorkoutController(routine: routine),
      child: const _CreateWorkoutView(),
    );
  }
}

class _CreateWorkoutView extends StatelessWidget {
  const _CreateWorkoutView();

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateWorkoutController>(
      builder: (context, controller, child) {
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Novo Treino'),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: controller.isLoading
                    ? null
                    : () => _saveWorkout(context, controller),
                child: Text(
                  'SALVAR',
                  style: TextStyle(
                    color: controller.isLoading
                        ? theme.colorScheme.onSurface.withOpacity(0.5)
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoutineInfo(controller, theme),
                  const SizedBox(height: 20),
                  _buildFormCard(context, controller, theme),
                  const SizedBox(height: 20),
                  _buildSuggestionsSection(controller, theme),
                  const SizedBox(height: 32),
                  _buildNextStepsCard(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoutineInfo(
    CreateWorkoutController controller,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionando treino para:',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  controller.routine.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    CreateWorkoutController controller,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Treino',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Treino',
                hintText: 'Ex: Treino A, Push, Peito e Tríceps',
                prefixIcon: Icon(
                  Icons.fitness_center_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Descreva o foco deste treino...',
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              maxLines: 2,
            ),
            if (controller.hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () => _saveWorkout(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text(
                        'Criar Treino',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(
    CreateWorkoutController controller,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sugestões de Nomes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.workoutSuggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () => controller.applySuggestion(suggestion),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                0.5,
              ),
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outlined, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'Após salvar:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Você poderá adicionar exercícios a este treino, definindo séries, repetições e peso para cada um.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout(
    BuildContext context,
    CreateWorkoutController controller,
  ) async {
    final success = await controller.saveWorkout();

    if (success && context.mounted) {
      SnackBarUtils.showSuccess(context, 'Treino criado com sucesso!');
      Navigator.of(context).pop();
    }
  }
}
