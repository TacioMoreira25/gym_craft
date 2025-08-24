class DatabaseException implements Exception {
  final String message;
  final String? details;
  
  const DatabaseException(this.message, [this.details]);
  
  @override
  String toString() {
    return details != null ? '$message: $details' : message;
  }
}

class ExerciseInUseException extends DatabaseException {
  const ExerciseInUseException() 
    : super('Não é possível excluir este exercício pois ele está sendo usado em treinos');
}

class RoutineNotFoundException extends DatabaseException {
  const RoutineNotFoundException(int id) 
    : super('Rotina com ID $id não encontrada');
}

class WorkoutNotFoundException extends DatabaseException {
  const WorkoutNotFoundException(int id) 
    : super('Treino com ID $id não encontrado');
}

class ExerciseNotFoundException extends DatabaseException {
  const ExerciseNotFoundException(int id) 
    : super('Exercício com ID $id não encontrado');
}