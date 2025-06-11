import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  // Хешируем пароль для безопасности (это лучше, чем хранить в открытом виде)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем, не занят ли уже такой username
    if (prefs.containsKey('user_$username')) {
      return false; // Пользователь уже существует
    }

    final hashedPassword = _hashPassword(password);
    await prefs.setString('user_$username', hashedPassword);
    return true;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPasswordHash = prefs.getString('user_$username');

    if (storedPasswordHash == null) {
      return false; // Пользователь не найден
    }

    final hashedPassword = _hashPassword(password);
    if (storedPasswordHash == hashedPassword) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('current_user', username);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('current_user');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }
}