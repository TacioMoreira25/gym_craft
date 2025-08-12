class Exercise {
  int? id;
  String name;
  String description;
  String muscleGroup;
  String? instructions;
  DateTime createdAt;
  bool isCustom; 

  Exercise({
    this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    this.instructions,
    required this.createdAt,
    this.isCustom = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'muscle_group': muscleGroup,
      'instructions': instructions,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      muscleGroup: map['muscle_group'],
      instructions: map['instructions'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      isCustom: map['is_custom'] == 1,
    );
  }
}