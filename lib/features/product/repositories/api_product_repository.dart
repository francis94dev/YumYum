import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../models/product_model.dart';
import '../../../core/network/api_constants.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _dio.get('/recipes');
      final List<dynamic> data = response.data;
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      return []; // Return empty list on error for now
    }
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      print('DEBUG: addProduct imageUrl: ${product.imageUrl}');
      
      final Map<String, dynamic> data = {
        'title': product.title,
        'description': product.description,
        'userId': product.owner.id,
        'type': product.type,
        'price': product.price?.toString() ?? '',
        'allergens': jsonEncode(product.allergens),
      };

      if (product.imageUrl.startsWith('http')) {
        data['imageUrl'] = product.imageUrl;
      }

      final isFile = !product.imageUrl.startsWith('http') && product.imageUrl.isNotEmpty;
      
      FormData formData;
      if (isFile && kIsWeb && product.webImageBytes != null) {
        // En Web, usamos fromBytes para máxima compatibilidad
        formData = FormData.fromMap({
          ...data,
          'image': MultipartFile.fromBytes(
            product.webImageBytes!,
            filename: 'upload.jpg',
          ),
        });
      } else {
        formData = FormData.fromMap({
          ...data,
          if (isFile)
            'image': await MultipartFile.fromFile(product.imageUrl, filename: p.basename(product.imageUrl)),
        });
      }

      final response = await _dio.post('/recipes', data: formData);
      return ProductModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al publicar producto: $e');
    }
  }
}
