import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../shared/constants/constants.dart';

/// Mixin para reutilizar lógica de filtros de exercícios
mixin FilterMixin<T extends StatefulWidget> on State<T> {
  // Variáveis de filtro que devem ser declaradas nas classes que usam o mixin
  List<Exercise> get allExercises;
  List<Exercise> get filteredExercises;
  String get selectedCategory;
  TextEditingController get searchController;

  set filteredExercises(List<Exercise> value);
  set selectedCategory(String value);

  // Lista de categorias padrão
  List<String> get categories => ['Todos', ...AppConstants.muscleGroups];

  /// Aplica filtros de categoria e busca aos exercícios
  void applyFilters() {
    setState(() {
      List<Exercise> filtered = allExercises;

      // Filtrar por categoria
      if (selectedCategory != 'Todos') {
        filtered = filtered
            .where((e) => e.category == selectedCategory)
            .toList();
      }

      // Filtrar por busca
      final searchQuery = searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where(
              (e) =>
                  e.name.toLowerCase().contains(searchQuery) ||
                  (e.description?.toLowerCase().contains(searchQuery) ?? false),
            )
            .toList();
      }

      filteredExercises = filtered;
    });
  }

  /// Limpa os filtros aplicados
  void clearFilters() {
    setState(() {
      selectedCategory = 'Todos';
      searchController.clear();
      filteredExercises = allExercises;
    });
  }

  /// Filtra por categoria específica
  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      applyFilters();
    });
  }

  /// Widget para construir chips de filtro de categoria
  Widget buildCategoryFilters({
    required Function(String) onCategorySelected,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    return Container(
      padding: padding,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) => onCategorySelected(category),
              selectedColor: _getCategoryColor(category).withOpacity(0.2),
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
    );
  }

  /// Widget para construir campo de busca
  Widget buildSearchField({
    String hintText = 'Buscar exercícios...',
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    applyFilters();
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => applyFilters(),
      ),
    );
  }

  /// Widget para mostrar contador de resultados
  Widget buildResultsCounter({
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  }) {
    return Container(
      padding: padding,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${filteredExercises.length} exercícios encontrados',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Widget para estado vazio com opções de limpeza de filtros
  Widget buildEmptyState({
    String emptyMessage = 'Nenhum exercício encontrado',
    String searchEmptyMessage = 'Nenhum resultado encontrado',
    String actionText = 'Limpar filtros',
    VoidCallback? onClearFilters,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              searchController.text.isEmpty ? emptyMessage : searchEmptyMessage,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tente ajustar sua pesquisa ou filtros',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
            if (selectedCategory != 'Todos' ||
                searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClearFilters ?? clearFilters,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper para obter cor da categoria
  Color _getCategoryColor(String category) {
    if (category == 'Todos') {
      return Colors.indigo;
    }
    return AppConstants.getMuscleGroupColor(category);
  }
}
