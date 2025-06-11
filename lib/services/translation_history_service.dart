import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/translation_history.dart';

class TranslationHistoryService {
  static const String _historyKey = 'translation_history';
  final SharedPreferences _prefs;
  final _uuid = const Uuid();
  static const int _maxRetries = 3;

  TranslationHistoryService(this._prefs);

  Future<List<TranslationHistory>> getHistory() async {
    try {
      final String? historyJson = _prefs.getString(_historyKey);
      if (historyJson == null) return [];

      final List<dynamic> historyList = json.decode(historyJson);
      return historyList
          .map((item) => TranslationHistory.fromJson(item))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading translation history: $e');
      return [];
    }
  }

  Future<void> addTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final history = await getHistory();
      final newTranslation = TranslationHistory(
        id: _uuid.v4(),
        sourceText: sourceText,
        translatedText: translatedText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        timestamp: DateTime.now(),
      );

      history.insert(0, newTranslation);
      await _saveHistoryWithRetry(history);
    } catch (e) {
      print('Error adding translation to history: $e');
      // Don't rethrow the error to prevent app crashes
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final history = await getHistory();
      final index = history.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = history[index];
        history[index] = item.copyWith(isFavorite: !item.isFavorite);
        await _saveHistoryWithRetry(history);
      }
    } catch (e) {
      print('Error toggling favorite status: $e');
    }
  }

  Future<void> deleteTranslation(String id) async {
    try {
      final history = await getHistory();
      history.removeWhere((item) => item.id == id);
      await _saveHistoryWithRetry(history);
    } catch (e) {
      print('Error deleting translation: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  Future<List<TranslationHistory>> getFavorites() async {
    try {
      final history = await getHistory();
      return history.where((item) => item.isFavorite).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  Future<void> _saveHistoryWithRetry(List<TranslationHistory> history) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        await _saveHistory(history);
        return;
      } catch (e) {
        retryCount++;
        if (retryCount == _maxRetries) {
          print('Failed to save history after $_maxRetries attempts: $e');
          rethrow;
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 100 * (1 << retryCount)));
      }
    }
  }

  Future<void> _saveHistory(List<TranslationHistory> history) async {
    try {
      final historyJson =
          json.encode(history.map((item) => item.toJson()).toList());
      await _prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error saving history: $e');
      rethrow;
    }
  }
}
