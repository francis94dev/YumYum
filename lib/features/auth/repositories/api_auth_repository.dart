import 'package:dio/dio.dart';
import '../../../models/user_model.dart';
import '../../../core/network/api_constants.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  UserModel? _currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final user = UserModel.fromJson(response.data['user']);
      _currentUser = user;
      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Error al iniciar sesión');
    } catch (e) {
      throw Exception('Error de conexión con el servidor');
    }
  }

  @override
  Future<UserModel> signUp(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final user = UserModel.fromJson(response.data['user']);
      _currentUser = user;
      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Error al registrarse');
    } catch (e) {
      throw Exception('Error de conexión con el servidor');
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }
}
