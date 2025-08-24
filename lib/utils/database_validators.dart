
class DatabaseValidators {
  
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
  
  static String? validateRoutineDescription(String? description) {
    if (description != null && description.length > 500) {
      return 'Descrição não pode ter mais de 500 caracteres';
    }
    return null;
  }
  
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
  
  static String? validateRepetitions(int? repetitions) {
    if (repetitions != null && (repetitions < 0 || repetitions > 999)) {
      return 'Repetições devem estar entre 0 e 999';
    }
    return null;
  }
  
  static String? validateWeight(double? weight) {
    if (weight != null && (weight < 0 || weight > 9999)) {
      return 'Peso deve estar entre 0 e 9999kg';
    }
    return null;
  }
  
  static String? validateRestSeconds(int? restSeconds) {
    if (restSeconds != null && (restSeconds < 0 || restSeconds > 3600)) {
      return 'Descanso deve estar entre 0 e 3600 segundos';
    }
    return null;
  }
  
  static String? validateImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return 'URL da imagem inválida';
    }
    
    final allowedSchemes = ['http', 'https'];
    if (!allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return 'URL deve usar protocolo HTTP ou HTTPS';
    }
    
    return null;
  }
}