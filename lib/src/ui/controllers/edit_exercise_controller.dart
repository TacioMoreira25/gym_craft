import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exercise.dart';
import '../../data/services/database_service.dart';
import '../../shared/constants/constants.dart';
import 'base_controller.dart';
import 'package:gym_craft/src/ui/screens/in_app_webview_screen.dart';

class EditExerciseController extends BaseController {
  final Exercise? exercise;
  final VoidCallback onUpdated;
  final DatabaseService _databaseService = DatabaseService();

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final imageUrlController = TextEditingController();
  final descriptionController = TextEditingController();
  final instructionsController = TextEditingController();

  String _selectedCategory = 'Peito';

  String? _clipboardImageUrl;
  bool _isCheckingClipboard = false;

  EditExerciseController({required this.exercise, required this.onUpdated}) {
    _initializeFields();
    _startClipboardMonitoring();
  }

  String get selectedCategory => _selectedCategory;
  bool get isEditing => exercise != null;
  bool get hasImageUrl => imageUrlController.text.isNotEmpty;
  bool get shouldShowCustomInfo => isEditing && exercise!.isCustom;
  String get dialogTitle => isEditing ? 'Editar Exercício' : 'Novo Exercício';
  String get buttonText => isEditing ? 'Salvar' : 'Criar';
  String get successMessage => isEditing
      ? 'Exercício atualizado com sucesso!'
      : 'Exercício criado com sucesso!';

  String? get clipboardImageUrl => _clipboardImageUrl;
  bool get isCheckingClipboard => _isCheckingClipboard;
  bool get hasClipboardImage => _clipboardImageUrl != null;

  List<String> get categories => AppConstants.muscleGroups;

  void _initializeFields() {
    if (exercise != null) {
      nameController.text = exercise!.name;
      imageUrlController.text = exercise!.imageUrl ?? '';
      descriptionController.text = exercise!.description ?? '';
      instructionsController.text = exercise!.instructions ?? '';
      _selectedCategory = exercise!.category;
    }
  }

  void _startClipboardMonitoring() {
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    if (_isCheckingClipboard) return;

    try {
      _isCheckingClipboard = true;
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text != null && text.isNotEmpty && _isValidImageUrl(text)) {
        if (_clipboardImageUrl != text) {
          _clipboardImageUrl = text;
          notifyListeners();
        }
      } else if (_clipboardImageUrl != null) {
        _clipboardImageUrl = null;
        notifyListeners();
      }
    } catch (e) {
      // Silently handle clipboard errors
    } finally {
      _isCheckingClipboard = false;
    }
  }

  bool _isValidImageUrl(String url) {
    if (!url.startsWith('http')) return false;

    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    final lowerUrl = url.toLowerCase();

    final hasImageExtension = imageExtensions.any(
      (ext) => lowerUrl.contains(ext),
    );
    final isImageDomain = [
      'googleusercontent.com',
      'imgur.com',
      'pixabay.com',
      'unsplash.com',
      'pexels.com',
      'freepik.com',
      'shutterstock.com',
      'istockphoto.com',
      'gettyimages.com',
    ].any((domain) => lowerUrl.contains(domain));

    return hasImageExtension || isImageDomain;
  }

  Future<void> searchImageOnGoogle(BuildContext context) async {
    try {
      final exerciseName = nameController.text.trim();
      final baseQuery =
          (exerciseName.isNotEmpty ? exerciseName : 'exercicio academia')
              .trim();

      // 1) Construir URL de forma segura e 100% escapada
      final googleUri = Uri.https('www.google.com', '/search', {
        'tbm': 'isch',
        'q': baseQuery,
      });

      // 2) Alternativas (fallbacks) caso a primeira falhe em alguns devices/ROMs
      final googleAltUri = Uri.https('images.google.com', '/search', {
        'q': baseQuery,
      });
      final duckDuckGoImages = Uri.https('duckduckgo.com', '/', {
        'q': baseQuery,
        'iax': 'images',
        'ia': 'images',
      });

      Future<bool> tryLaunch(Uri uri, [LaunchMode? mode]) async {
        try {
          if (await canLaunchUrl(uri)) {
            return await launchUrl(
              uri,
              mode: mode ?? LaunchMode.platformDefault,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
              ),
            );
          }
        } catch (_) {}
        return false;
      }

      // Tentar em ordem: padrão -> externo -> in-app
      bool launched =
          await tryLaunch(googleUri, LaunchMode.platformDefault) ||
          await tryLaunch(googleUri, LaunchMode.externalApplication) ||
          await tryLaunch(googleUri, LaunchMode.inAppWebView) ||
          // Fallbacks de domínio
          await tryLaunch(googleAltUri, LaunchMode.platformDefault) ||
          await tryLaunch(googleAltUri, LaunchMode.externalApplication) ||
          await tryLaunch(googleAltUri, LaunchMode.inAppWebView) ||
          // Fallback final para garantir alguma experiência
          await tryLaunch(duckDuckGoImages, LaunchMode.platformDefault) ||
          await tryLaunch(duckDuckGoImages, LaunchMode.externalApplication) ||
          await tryLaunch(duckDuckGoImages, LaunchMode.inAppWebView);

      if (launched) {
        await Future.delayed(const Duration(seconds: 2));
        _startFrequentClipboardCheck();
      } else {
        if (context.mounted) {
          final uriToOpen = googleUri;
          final selected = await Navigator.of(context).push<String>(
            MaterialPageRoute(
              builder: (_) => InAppWebViewScreen(
                uri: uriToOpen,
                title: 'Buscar imagem',
                captureImageTap: true,
              ),
            ),
          );
          if (selected != null && selected.isNotEmpty) {
            imageUrlController.text = selected;
            onImageUrlChanged();
            notifyListeners();
          }
          _startFrequentClipboardCheck();
        } else {
          setError(
            'Não foi possível abrir uma busca de imagens no dispositivo.',
          );
        }
      }
    } catch (e) {
      setError('Erro ao abrir busca de imagens. Tente novamente.');
    }
  }

  void _startFrequentClipboardCheck() {
    int attempts = 0;
    const maxAttempts = 30;

    void checkFrequently() async {
      if (attempts >= maxAttempts) return;

      await _checkClipboard();
      attempts++;

      if (attempts < maxAttempts) {
        Future.delayed(const Duration(seconds: 1), checkFrequently);
      }
    }

    checkFrequently();
  }

  void useClipboardImage() {
    if (_clipboardImageUrl != null) {
      imageUrlController.text = _clipboardImageUrl!;
      _clipboardImageUrl = null;
      onImageUrlChanged();
      notifyListeners();
    }
  }

  void dismissClipboardSuggestion() {
    _clipboardImageUrl = null;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void onImageUrlChanged() {
    notifyListeners();
  }

  Future<bool> saveExercise() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    try {
      setLoading(true);
      clearError();

      final exerciseData = Exercise(
        id: isEditing ? exercise!.id : null,
        name: nameController.text.trim(),
        category: selectedCategory,
        imageUrl: imageUrlController.text.trim().isEmpty
            ? null
            : imageUrlController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        instructions: instructionsController.text.trim().isEmpty
            ? null
            : instructionsController.text.trim(),
        isCustom: isEditing ? exercise!.isCustom : false,
        createdAt: isEditing ? exercise!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await _databaseService.exercises.updateExercise(exerciseData);
      } else {
        await _databaseService.exercises.insertExercise(exerciseData);
      }

      onUpdated();
      return true;
    } catch (e) {
      setError('Erro ao salvar exercício: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    imageUrlController.dispose();
    descriptionController.dispose();
    instructionsController.dispose();
    super.dispose();
  }
}
