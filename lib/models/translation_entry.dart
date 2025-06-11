// lib/models/translation_entry.dart

import 'package:uuid/uuid.dart'; // Для генерации уникальных ID

// Импакт uuid. Для этого нужно добавить зависимость в pubspec.yaml:
// dependencies:
//   uuid: ^4.3.3  (или последняя версия)

class TranslationEntry {
  final String id; // Уникальный ID для каждой записи
  final String originalText;
  final String translatedText;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final DateTime timestamp; // Когда был сохранен перевод

  TranslationEntry({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.timestamp,
  });

  // Метод для преобразования объекта в Map (для сохранения в JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguageCode': sourceLanguageCode,
      'targetLanguageCode': targetLanguageCode,
      'timestamp':
          timestamp.toIso8601String(), // Сохраняем дату в строковом формате
    };
  }

  // Фабричный конструктор для создания объекта из Map (при загрузке из JSON)
  factory TranslationEntry.fromJson(Map<String, dynamic> json) {
    return TranslationEntry(
      id: json['id'],
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      sourceLanguageCode: json['sourceLanguageCode'],
      targetLanguageCode: json['targetLanguageCode'],
      timestamp: DateTime.parse(
          json['timestamp']), // Преобразуем строку обратно в DateTime
    );
  }
}
