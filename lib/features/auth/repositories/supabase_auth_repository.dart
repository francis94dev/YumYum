import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_model.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final _client = Supabase.instance.client;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      
      if (user == null) throw Exception('Fallo al iniciar sesión');

      // Obtener datos extra desde la tabla 'users'
      final userData = await _client.from('users').select().eq('id', user.id).single();

      return UserModel(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        profileImageUrl: userData['profile_image_url'] ?? 'https://i.pravatar.cc/150?u=${userData['email']}',
      );
    } catch (e) {
      throw Exception('Error en Supabase login: $e');
    }
  }

  @override
  Future<UserModel> signUp(String name, String email, String password) async {
    try {
      // 1. Crear el usuario en Auth de Supabase
      final response = await _client.auth.signUp(email: email, password: password);
      final user = response.user;
      
      if (user == null) throw Exception('Fallo al crear usuario');

      // 2. Insertar su información pública en la tabla 'users'
      final Map<String, dynamic> data = {
        'id': user.id, // Emparejamos el UUID de auth con el id publico
        'name': name,
        'email': email,
        'profile_image_url': 'https://i.pravatar.cc/150?u=$email',
      };

      await _client.from('users').insert(data);

      return UserModel(
        id: data['id'],
        name: data['name'],
        email: data['email'],
        profileImageUrl: data['profile_image_url'],
      );
    } catch (e) {
      throw Exception('Error en Supabase signUp: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final userData = await _client.from('users').select().eq('id', user.id).single();
      return UserModel(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        profileImageUrl: userData['profile_image_url'] ?? 'https://i.pravatar.cc/150?u=${userData['email']}',
      );
    } catch (e) {
       // Si hay un error al obtener de la tabla (ej. no existe aún el perfil), cerramos sesión por seguridad
       await logout();
       return null;
    }
  }
}
