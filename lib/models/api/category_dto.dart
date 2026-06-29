class CategoryDTO {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  CategoryDTO({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory CategoryDTO.fromJson(Map<String, dynamic> json) {
    return CategoryDTO(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
