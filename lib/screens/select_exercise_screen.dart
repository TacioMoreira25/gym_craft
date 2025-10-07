import 'package:flutter/material.dart';
import 'package:gym_craft/utils/constants.dart';
import 'exercise_management_screen.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../widgets/exercise_image_widget.dart';
import '../mixins/filter_mixin.dart';
import '../utils/snackbar_utils.dart';

class SelectExerciseScreen extends StatefulWidget {
  final List<int> excludeExerciseIds;

  const SelectExerciseScreen({Key? key, this.excludeExerciseIds = const []})
    : super(key: key);

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen>
    with FilterMixin {
  final DatabaseService _databaseService = DatabaseService();

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  String searchQuery = '';
  String _selectedCategory = 'Todos';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Implementação do FilterMixin
  @override
  List<Exercise> get allExercises => _exercises;

  @override
  List<Exercise> get filteredExercises => _filteredExercises;

  @override
  String get selectedCategory => _selectedCategory;

  @override
  TextEditingController get searchController => _searchController;

  @override
  set filteredExercises(List<Exercise> value) => _filteredExercises = value;

  @override
  set selectedCategory(String value) => _selectedCategory = value;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Color _getCategoryColor(String category) {
    if (category == 'Todos') {
      return Colors.indigo;
    }
    return AppConstants.getMuscleGroupColor(category);
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _navigateToExerciseManagement,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Campo de busca
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar exercícios...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => applyFilters(),
              ),
              const SizedBox(height: 12),

              // Filtro por categoria
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                            applyFilters();
                          });
                        },
                        selectedColor: _getCategoryColor(
                          category,
                        ).withOpacity(0.2),
                        checkmarkColor: _getCategoryColor(category),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? _getCategoryColor(category)
                              : Colors.grey[700],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Lista de exercícios
        Expanded(
          child: _filteredExercises.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
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
                                color: AppConstants.getMuscleGroupColor(
                                  exercise.category,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, exercise),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício encontrado',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou criar um novo exercício',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToExerciseManagement,
            icon: const Icon(Icons.add),
            label: const Text('Criar Exercício'),
          ),
        ],
      ),
    );
  }

  void _navigateToExerciseManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseManagementScreen()),
    );
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _databaseService.exercises.getAllExercises();
      setState(() {
        _exercises = exercises;
        applyFilters(); // Usando método do FilterMixin
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showOperationError(
          context,
          'carregar exercícios',
          e.toString(),
        );
      }
    }
  }
}
