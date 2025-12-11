import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/constants/constants.dart';
import 'ImageViewerDialog.dart';

class ExerciseImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final String? category;
  final BorderRadius? borderRadius;
  final bool enableTap;
  final String? exerciseName;

  const ExerciseImageWidget({
    super.key,
    this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.category,
    this.borderRadius,
    this.enableTap = false,
    this.exerciseName,
  });

  Color _getCategoryColor(String? category) {
    return AppConstants.getMuscleGroupColor(category ?? '');
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
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildImageWidget() {
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

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildImageWidget();

    if (enableTap && imageUrl != null && imageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          ImageViewerDialog.show(
            context: context,
            imageUrl: imageUrl,
            exerciseName: exerciseName ?? 'Exercício',
          );
        },
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
