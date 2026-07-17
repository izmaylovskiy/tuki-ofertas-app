import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final int? parentId;
  final String? icon;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.icon,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      parentId: json['parent_id'],
      icon: json['icon'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((e) => Category.fromJson(e))
              .toList()
          : [],
    );
  }

  IconData get iconData {
    switch (icon ?? slug) {
      case 'frutas':
      case 'fruits':
        return Icons.apple;
      case 'verduras':
      case 'vegetables':
        return Icons.eco;
      case 'carnes':
      case 'meat':
        return Icons.lunch_dining;
      case 'lacteos':
      case 'dairy':
        return Icons.egg;
      case 'bebidas':
      case 'drinks':
        return Icons.local_drink;
      case 'panaderia':
      case 'bakery':
        return Icons.bakery_dining;
      case 'limpieza':
      case 'cleaning':
        return Icons.cleaning_services;
      case 'cuidado_personal':
      case 'personal_care':
        return Icons.face;
      case 'snacks':
        return Icons.cookie;
      case 'congelados':
      case 'frozen':
        return Icons.ac_unit;
      case 'despensa':
      case 'pantry':
        return Icons.kitchen;
      case 'mascotas':
      case 'pets':
        return Icons.pets;
      default:
        return Icons.shopping_basket;
    }
  }
}
