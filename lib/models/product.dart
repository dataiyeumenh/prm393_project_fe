import 'package:flutter/material.dart';

enum PetType { dog, cat, bird, fish, smallPet }

extension PetTypeX on PetType {
  String get label {
    switch (this) {
      case PetType.dog:
        return 'Dog';
      case PetType.cat:
        return 'Cat';
      case PetType.bird:
        return 'Bird';
      case PetType.fish:
        return 'Fish';
      case PetType.smallPet:
        return 'Small Pet';
    }
  }

  IconData get icon {
    switch (this) {
      case PetType.dog:
        return Icons.pets;
      case PetType.cat:
        return Icons.pets;
      case PetType.bird:
        return Icons.flutter_dash;
      case PetType.fish:
        return Icons.set_meal;
      case PetType.smallPet:
        return Icons.cruelty_free;
    }
  }
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.petType,
    this.subtitle,
  });

  final String id;
  final String name;
  final PetType petType;
  final String? subtitle;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.categoryId,
    required this.petType,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.brand,
    required this.weightGrams,
    required this.stock,
    this.badges = const [],
    this.colorways = const [],
    this.description = '',
    this.ingredients = '',
    this.nutrition = const {},
  });

  final String id;
  final String name;
  final String subtitle;
  final String categoryId;
  final PetType petType;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final String brand;
  final int weightGrams;
  final int stock;
  final List<String> badges;
  final List<String> colorways;
  final String description;
  final String ingredients;
  final Map<String, String> nutrition;

  bool get onSale => originalPrice != null && originalPrice! > price;

  int? get discountPercent {
    if (!onSale) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  double get lowestPrice => price;
}
