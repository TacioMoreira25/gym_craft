/// Classe utilitária para validações comuns em formulários
class ValidationUtils {
  /// Valida nome de rotina
  static String? validateRoutineName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Nome da rotina é obrigatório';
    }
    if (name.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (name.trim().length > 100) {
      return 'Nome não pode ter mais de 100 caracteres';
    }
    return null;
  }

  /// Valida descrição de rotina
  static String? validateRoutineDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Descrição não pode ter mais de 500 caracteres';
    }
    return null;
  }

  /// Valida nome de treino
  static String? validateWorkoutName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Nome do treino é obrigatório';
    }
    if (name.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (name.trim().length > 100) {
      return 'Nome não pode ter mais de 100 caracteres';
    }
    return null;
  }

  /// Valida descrição de treino
  static String? validateWorkoutDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Descrição não pode ter mais de 500 caracteres';
    }
    return null;
  }

  /// Valida nome de exercício
  static String? validateExerciseName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Nome do exercício é obrigatório';
    }
    if (name.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (name.trim().length > 100) {
      return 'Nome não pode ter mais de 100 caracteres';
    }
    return null;
  }

  /// Valida descrição de exercício
  static String? validateExerciseDescription(String? description) {
    if (description != null && description.length > 1000) {
      return 'Descrição não pode ter mais de 1000 caracteres';
    }
    return null;
  }

  /// Valida instruções de exercício
  static String? validateExerciseInstructions(String? instructions) {
    if (instructions != null && instructions.length > 2000) {
      return 'Instruções não podem ter mais de 2000 caracteres';
    }
    return null;
  }

  /// Valida número de repetições
  static String? validateRepetitions(String? value) {
    if (value == null || value.isEmpty) {
      return 'Número de repetições é obrigatório';
    }

    final repetitions = int.tryParse(value);
    if (repetitions == null) {
      return 'Deve ser um número válido';
    }

    if (repetitions <= 0) {
      return 'Deve ser maior que 0';
    }

    if (repetitions > 999) {
      return 'Máximo 999 repetições';
    }

    return null;
  }

  /// Valida peso
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Peso é opcional
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Deve ser um número válido';
    }

    if (weight < 0) {
      return 'Peso não pode ser negativo';
    }

    if (weight > 9999) {
      return 'Peso máximo é 9999kg';
    }

    return null;
  }

  /// Valida tempo de descanso
  static String? validateRestTime(String? value, {bool isRequired = false}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Tempo de descanso é obrigatório' : null;
    }

    final restSeconds = int.tryParse(value);
    if (restSeconds == null) {
      return 'Deve ser um número válido';
    }

    if (restSeconds < 0) {
      return 'Tempo não pode ser negativo';
    }

    if (restSeconds > 3600) {
      return 'Máximo 3600 segundos (1 hora)';
    }

    return null;
  }

  /// Valida URL de imagem
  static String? validateImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null; // URL é opcional
    }

    final value = url.trim();

    final isHttp = value.startsWith('http://') || value.startsWith('https://');
    final isDataImage = value.startsWith('data:image/');

    if (isHttp || isDataImage) {
      return null;
    }

    return 'Informe uma URL válida iniciando com http:// ou https://';
  }

  /// Valida categoria de exercício
  static String? validateCategory(
    String? category,
    List<String> validCategories,
  ) {
    if (category == null || category.isEmpty) {
      return 'Categoria é obrigatória';
    }

    if (!validCategories.contains(category)) {
      return 'Categoria inválida';
    }

    return null;
  }

  /// Valida número inteiro genérico
  static String? validateInteger(
    String? value, {
    required String fieldName,
    int? min,
    int? max,
    bool isRequired = true,
  }) {
    if (value == null || value.isEmpty) {
      return isRequired ? '$fieldName é obrigatório' : null;
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName deve ser um número válido';
    }

    if (min != null && number < min) {
      return '$fieldName deve ser pelo menos $min';
    }

    if (max != null && number > max) {
      return '$fieldName não pode ser maior que $max';
    }

    return null;
  }

  /// Valida número decimal genérico
  static String? validateDouble(
    String? value, {
    required String fieldName,
    double? min,
    double? max,
    bool isRequired = true,
  }) {
    if (value == null || value.isEmpty) {
      return isRequired ? '$fieldName é obrigatório' : null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName deve ser um número válido';
    }

    if (min != null && number < min) {
      return '$fieldName deve ser pelo menos $min';
    }

    if (max != null && number > max) {
      return '$fieldName não pode ser maior que $max';
    }

    return null;
  }

  /// Valida texto genérico
  static String? validateText(
    String? value, {
    required String fieldName,
    int? minLength,
    int? maxLength,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$fieldName é obrigatório' : null;
    }

    final trimmedValue = value.trim();

    if (minLength != null && trimmedValue.length < minLength) {
      return '$fieldName deve ter pelo menos $minLength caracteres';
    }

    if (maxLength != null && trimmedValue.length > maxLength) {
      return '$fieldName não pode ter mais de $maxLength caracteres';
    }

    return null;
  }

  /// Valida que pelo menos um campo não está vazio
  static String? validateAtLeastOne(List<String?> values, String errorMessage) {
    final hasValue = values.any(
      (value) => value != null && value.trim().isNotEmpty,
    );
    return hasValue ? null : errorMessage;
  }
}
