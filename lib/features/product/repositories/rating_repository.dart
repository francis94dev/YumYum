import 'package:dio/dio.dart';
import '../../../models/rating_model.dart';
import '../../../core/network/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class RatingRepository {
  Future<List<RatingModel>> getRatings(String targetId);
  Future<void> addRating(RatingModel rating);
}

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return ApiRatingRepository();
});

final ratingsProvider = FutureProvider.family<List<RatingModel>, String>((ref, targetId) {
  return ref.watch(ratingRepositoryProvider).getRatings(targetId);
});

class ApiRatingRepository implements RatingRepository {
  // ... (keeping existing implementation)
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  @override
  Future<List<RatingModel>> getRatings(String targetId) async {
    try {
      final response = await _dio.get('/ratings/$targetId');
      final List<dynamic> data = response.data;
      return data.map((json) => RatingModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addRating(RatingModel rating) async {
    try {
      await _dio.post('/ratings', data: rating.toJson());
    } catch (e) {
      throw Exception('Error al enviar valoración');
    }
  }
}

class MockRatingRepository implements RatingRepository {
  final List<RatingModel> _ratings = [];

  @override
  Future<List<RatingModel>> getRatings(String targetId) async {
    return _ratings.where((r) => r.targetId == targetId).toList();
  }

  @override
  Future<void> addRating(RatingModel rating) async {
    _ratings.add(rating);
  }
}
