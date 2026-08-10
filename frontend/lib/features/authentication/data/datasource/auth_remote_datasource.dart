import '../models/user_model.dart';

class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'admin@gmail.com' &&
        password == '123456') {
      return const UserModel(
        id: 1,
        name: 'Admin',
        email: 'admin@gmail.com',
      );
    }

    throw Exception('Invalid email or password');
  }
}