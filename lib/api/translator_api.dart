import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:dearsa/models/language_model.dart'; // Этот импорт не нужен здесь, если Language не используется напрямую в этом файле

class TranslatorApi {
  final String _baseUrl = "https://api.mymemory.translated.net";

  // !!! ВАШ EMAIL АДРЕС ДЛЯ MYMEMORY API !!!
  // Укажите здесь ваш реальный email, чтобы получить лимит в 1000 запросов/день.
  // Без него лимит будет 100 запросов/день, и они могут закончиться очень быстро.
  // В реальном приложении не храните email так, используйте .env файлы или другие более безопасные способы.
  final String _email = "saikalesbolotova@gmail.com"; // <-- ЗАМЕНИТЕ НА ВАШ EMAIL

  // MyMemory API предоставляет эндпоинт для получения списка языков,
  // но он не такой простой, как у LibreTranslate, и часто используется для проверки кодов.
  // Для простоты UI, я рекомендую оставить статический список языков в HomeScreen.
  // Но если вам очень нужно получать список языков, это можно реализовать.
  // Пока оставим метод getLanguages() удаленным, как и с DeepL.

  Future<String> translate(String text, String sourceLang, String targetLang) async {
    // MyMemory API ожидает коды языков в формате "source|target" (e.g., "en|ru")
    // и обычно принимает как строчные, так и заглавные буквы.
    // Если sourceLang пустой или 'auto', MyMemory может попытаться автоопределить.
    final String langpair = sourceLang.isEmpty || sourceLang.toLowerCase() == 'auto'
        ? targetLang.toLowerCase() // Если авто, просто целевой язык
        : "${sourceLang.toLowerCase()}|${targetLang.toLowerCase()}";

    // Строим URL с параметрами
    // Параметр q: текст для перевода
    // Параметр langpair: пара языков (source|target)
    // Параметр de: ваш email для увеличения лимита (для dev/test)
    final Uri uri = Uri.parse('$_baseUrl/get').replace(queryParameters: {
      'q': text,
      'langpair': langpair,
      'de': _email, // Ваш email
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['responseData'] != null && data['responseData']['translatedText'] != null) {
        // MyMemory возвращает результат в responseData.translatedText
        return data['responseData']['translatedText'];
      } else {
        // Проверяем наличие 'error' сообщения
        if (data['responseData'] != null && data['responseData']['error'] != null) {
          throw Exception('MyMemory API error: ${data['responseData']['error']}');
        }
        throw Exception('MyMemory API did not return a valid translation.');
      }
    } else {
      print('MyMemory Error Status Code: ${response.statusCode}');
      print('MyMemory Error Body: ${utf8.decode(response.bodyBytes)}');
      // Попробуем получить сообщение об ошибке из ответа MyMemory
      try {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Failed to translate text with MyMemory: ${errorData['responseDetails'] ?? 'Unknown MyMemory error'}');
      } catch (e) {
        // Если тело ответа не является JSON
        throw Exception('Failed to translate text with MyMemory. Raw error: ${utf8.decode(response.bodyBytes)}');
      }
    }
  }
}