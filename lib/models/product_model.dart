import 'dart:typed_data';
import 'dart:math';
import 'user_model.dart';
import 'package:latlong2/latlong.dart';
class ProductModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final UserModel owner;
  final DateTime createdAt;
  final String type; // 'exchange' or 'sell'
  final double? price; // if type is 'sell'
  final LatLng location; // Mock location
  final List<String> allergens;
  final Uint8List? webImageBytes;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.owner,
    required this.createdAt,
    required this.type,
    this.price,
    required this.location,
    this.allergens = const [],
    this.webImageBytes,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      owner: json['owner'] != null 
        ? UserModel.fromJson(json['owner']) 
        : UserModel(id: json['userId'] ?? '0', name: 'Usuario', email: '', profileImageUrl: ''),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      type: json['type'] as String? ?? 'exchange',
      price: (json['price'] == null || json['price'] == '') 
          ? null 
          : (json['price'] is String ? double.tryParse(json['price']) : (json['price'] as num).toDouble()),
      location: LatLng(40.4168 + (Random().nextDouble() - 0.5) * 0.02, -3.7038 + (Random().nextDouble() - 0.5) * 0.02),

      allergens: (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'userId': owner.id,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'price': price,
      'allergens': allergens,
    };
  }
}
