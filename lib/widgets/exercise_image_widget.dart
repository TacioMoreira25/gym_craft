import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExerciseImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final String? category;
  final BorderRadius? borderRadius;

  const ExerciseImageWidget({
    super.key,
    this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.category,
    this.borderRadius,
  });

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'peito':
        return Icons.fitness_center;
      case 'costas':
        return Icons.accessibility_new;
      case 'quadríceps':
      case 'posterior':
      case 'panturrilhas':
        return Icons.directions_run;
      case 'ombros':
        return Icons.sports_gymnastics;
      case 'bíceps':
      case 'tríceps':
        return Icons.sports_kabaddi;
      case 'abdomen':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'peito':
        return Colors.red;
      case 'costas':
        return Colors.blue;
      case 'quadríceps':
        return Colors.green;
      case 'posterior':
        return Colors.orange;
      case 'panturrilhas':
        return Colors.teal;
      case 'ombros':
        return Colors.purple;
      case 'bíceps':
        return Colors.indigo;
      case 'tríceps':
        return Colors.pink;
      case 'abdomen':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: _getCategoryColor(category).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _getCategoryIcon(category),
        size: width * 0.4,
        color: _getCategoryColor(category),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se não há URL de imagem, mostrar fallback
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackWidget();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildFallbackWidget(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}