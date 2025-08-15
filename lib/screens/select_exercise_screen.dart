// screens/select_exercise_screen.dart
import 'package:flutter/material.dart';
import 'exercise_management_screen.dart';
import '../models/exercise.dart';
import '../database/database_helper.dart';
class SelectExerciseScreen extends StatefulWidget {
  final List<int> excludeExerciseIds;

  const SelectExerciseScreen({
    Key? key,
    this.excludeExerciseIds = const [],
  }) : super(key: key);

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> 
{
  final _databaseHelper =DatabaseHelper();

  List<Exercise> allExercises = [];
  List<Exercise> filteredExercises = [];
  String searchQuery = '';
  String? selectedCategory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Exercício'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToExerciseManagement,
          ),
        ],
      ),
      body: isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
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
                decoration: const InputDecoration(
                  hintText: 'Buscar exercícios...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    _filterExercises();
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Filtro por categoria
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por categoria',
                  border: OutlineInputBorder(),
                ),
                items: _getCategories().map((category) {
                  return DropdownMenuItem(
                    value: category == 'Todas' ? null : category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                    _filterExercises();
                  });
                },
              ),
            ],
          ),
        ),
        
        // Lista de exercícios
        Expanded(
          child: filteredExercises.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(
                          exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise.category),
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
                                  style: TextStyle(fontSize: 10, color: Colors.blue),
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
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou criar um novo exercício',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
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
      MaterialPageRoute(
        builder: (context) => const ExerciseManagementScreen(),
      ),
    );
    _loadExercises(); // Recarregar exercícios
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await _databaseHelper.getAllExercises();
      final availableExercises = exercises
          .where((e) => !widget.excludeExerciseIds.contains(e.id))
          .toList();
      
      if (mounted) {
        setState(() {
          allExercises = availableExercises;
          isLoading = false;
        });
        _filterExercises();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar exercícios: $e')),
        );
      }
    }
  }

  void _filterExercises() {
    filteredExercises = allExercises.where((exercise) {
      final matchesSearch = exercise.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                           (exercise.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      final matchesCategory = selectedCategory == null || exercise.category == selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> _getCategories() {
    final categories = allExercises.map((e) => e.category).toSet().toList();
    categories.sort();
    return ['Todas', ...categories];
  }
}