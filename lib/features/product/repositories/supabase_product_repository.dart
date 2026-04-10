import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/product_model.dart';
import '../../../models/user_model.dart';
import 'product_repository.dart';

class SupabaseProductRepository implements ProductRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      // Pedimos los productos e incluimos la informaciÃ³n del usuario relacionado
      final response = await _client
          .from('products')
          .select('*, users(*)');

      final List<ProductModel> products = [];
      for (var data in response) {
        
        final userMap = data['users'];
        UserModel ownerUser;
        if (userMap != null) {
           ownerUser = UserModel(
             id: userMap['id'], 
             name: userMap['name'] ?? 'Usuario', 
             email: userMap['email'] ?? '', 
             profileImageUrl: userMap['profile_image_url'] ?? 'https://i.pravatar.cc/150?img=5',
           );
        } else {
           ownerUser = UserModel(id: '0', name: 'Usuario Desconocido', email: '', profileImageUrl: '');
        }

        products.add(ProductModel(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          imageUrl: data['image_url'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
          owner: ownerUser,
          createdAt: DateTime.parse(data['created_at']),
          type: data['type'],
          price: data['price'] != null ? (data['price'] as num).toDouble() : null,
          allergens: List<String>.from((data['allergens'] as List?) ?? []),
          location: LatLng(data['latitude'] ?? 40.4168, data['longitude'] ?? -3.7038),
        ));
      }
      return products;
    } catch (e) {
      print('Error en Supabase getProducts: $e');
      rethrow;
    }
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      String finalImageUrl = product.imageUrl;

      // Si la URL es una ruta local (no empieza con http), la subimos a Supabase Storage
      if (finalImageUrl.isNotEmpty && !finalImageUrl.startsWith('http')) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${product.id}.jpg';
        
        if (kIsWeb && product.webImageBytes != null) {
          await _client.storage.from('product-images').uploadBinary(
            fileName, 
            product.webImageBytes!, 
            fileOptions: const FileOptions(contentType: 'image/jpeg')
          );
        } else {
          await _client.storage.from('product-images').upload(
            fileName, 
            File(finalImageUrl), 
            fileOptions: const FileOptions(contentType: 'image/jpeg')
          );
        }
        
        // Obtenemos la URL pública de la imagen recién subida
        finalImageUrl = _client.storage.from('product-images').getPublicUrl(fileName);
      }

      final Map<String, dynamic> dataToInsert = {
        'title': product.title,
        'description': product.description,
        'image_url': finalImageUrl,
        'user_id': product.owner.id,
        'type': product.type,
        'price': product.price,
        'allergens': product.allergens,
        'latitude': product.location.latitude,
        'longitude': product.location.longitude,
      };

      final response = await _client
          .from('products')
          .insert(dataToInsert)
          .select('*, users(*)')
          .single();

      final userMap = response['users'];
      UserModel ownerUser = product.owner; // Fallback
      if (userMap != null) {
         ownerUser = UserModel(
           id: userMap['id'], 
           name: userMap['name'] ?? 'Usuario', 
           email: userMap['email'] ?? '', 
           profileImageUrl: userMap['profile_image_url'] ?? 'https://i.pravatar.cc/150?img=5',
         );
      }

      return ProductModel(
          id: response['id'],
          title: response['title'],
          description: response['description'],
          imageUrl: response['image_url'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
          owner: ownerUser,
          createdAt: DateTime.parse(response['created_at']),
          type: response['type'],
          price: response['price'] != null ? (response['price'] as num).toDouble() : null,
          allergens: List<String>.from((response['allergens'] as List?) ?? []),
          location: LatLng(response['latitude'] ?? 40.4168, response['longitude'] ?? -3.7038),
      );
    } catch (e) {
      print('Error en Supabase addProduct: $e');
      rethrow;
    }
  }
}
