// lib/services/favorites_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dearsa/models/translation_entry.dart'; // Убедитесь, что этот путь правильный

class FavoritesService {
  // Ключ для хранения в SharedPreferences (теперь публичный, без подчеркивания)
  static const String favoritesKey = 'favoriteTranslations';

  // Загружает все избранные переводы
  Future<List<TranslationEntry>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(favoritesKey); // Используем публичный ключ

    if (favoritesJson == null) {
      return []; // Если ничего не сохранено, возвращаем пустой список
    }

    // Декодируем JSON-строку в список Map'ов
    final List<dynamic> jsonList = json.decode(favoritesJson);
    // Преобразуем каждый Map обратно в TranslationEntry
    return jsonList.map((json) => TranslationEntry.fromJson(json)).toList();
  }

  // Сохраняет список избранных переводов
  Future<void> _saveFavorites(List<TranslationEntry> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    // Преобразуем список TranslationEntry в список Map'ов, затем в JSON-строку
    final String favoritesJson = json.encode(favorites.map((entry) => entry.toJson()).toList());
    await prefs.setString(favoritesKey, favoritesJson); // Используем публичный ключ
  }

  // Добавляет перевод в избранное
  Future<void> addFavorite(TranslationEntry entry) async {
    final List<TranslationEntry> favorites = await loadFavorites();
    // Проверяем, нет ли уже такого перевода (по ID)
    if (!favorites.any((fav) => fav.id == entry.id)) {
      favorites.add(entry);
      await _saveFavorites(favorites);
    }
  }

  // Удаляет перевод из избранного по ID
  Future<void> removeFavorite(String entryId) async {
    List<TranslationEntry> favorites = await loadFavorites();
    favorites.removeWhere((entry) => entry.id == entryId);
    await _saveFavorites(favorites);
  }

  // Проверяет, находится ли перевод в избранном
  Future<bool> isFavorite(String entryId) async {
    final List<TranslationEntry> favorites = await loadFavorites();
    return favorites.any((fav) => fav.id == entryId);
  }
}