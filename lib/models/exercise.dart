class Exercise {
  int? id;
  String name;
  String? description; 
  String category;
  String? instructions;
  bool isCustom; 
  DateTime createdAt;

  Exercise({
    this.id,
    required this.name,
    this.description,
    required this.category,
    this.instructions,
    this.isCustom = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'instructions': instructions,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      instructions: map['instructions'],
      isCustom: map['is_custom'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}