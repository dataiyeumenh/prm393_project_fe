class BrandDTO {
  final int id;
  final String name;
  final String? description;
  final String? logoUrl;

  const BrandDTO({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
  });

  factory BrandDTO.fromJson(Map<String, dynamic> json) {
    return BrandDTO(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['imageUrl'] as String?,
    );
  }
}
