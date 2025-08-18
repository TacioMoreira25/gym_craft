class Exercise {
  int? id;
  String name;
  String? description; 
  String category;
  String? instructions;
  bool isCustom; 
  DateTime createdAt;
  String? imageUrl;

  Exercise({
    this.id,
    required this.name,
    this.description,
    required this.category,
    this.instructions,
    this.isCustom = false,
    this.imageUrl,
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
      'image_url': imageUrl,
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
      imageUrl: map['image_url'], 
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}