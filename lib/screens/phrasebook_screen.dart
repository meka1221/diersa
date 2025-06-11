import 'package:flutter/material.dart';
import 'package:dearsa/models/phrase_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({Key? key}) : super(key: key);

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  final FlutterTts flutterTts = FlutterTts();

  final List<Phrase> greetings = [
    Phrase(
      category: 'Приветствия',
      text: 'Здравствуйте!',
      translation: 'Hello!',
      example: 'Здравствуйте! Как ваши дела?',
    ),
    Phrase(
      category: 'Приветствия',
      text: 'Доброе утро!',
      translation: 'Good morning!',
      example: 'Доброе утро! Как спалось?',
    ),
    Phrase(
      category: 'Приветствия',
      text: 'Добрый вечер!',
      translation: 'Good evening!',
      example: 'Добрый вечер! Рад вас видеть.',
    ),
    Phrase(
      category: 'Приветствия',
      text: 'До свидания!',
      translation: 'Goodbye!',
      example: 'До свидания! Увидимся завтра.',
    ),
  ];

  final List<Phrase> transport = [
    Phrase(
      category: 'Транспорт',
      text: 'Где находится ближайшая автобусная остановка?',
      translation: 'Where is the nearest bus stop?',
      example: 'Извините, где находится ближайшая автобусная остановка?',
    ),
    Phrase(
      category: 'Транспорт',
      text: 'Сколько стоит билет на поезд?',
      translation: 'How much is a train ticket?',
      example: 'Сколько стоит билет на поезд до центра города?',
    ),
    Phrase(
      category: 'Транспорт',
      text: 'Во сколько отправляется следующий автобус?',
      translation: 'What time does the next bus leave?',
      example: 'Во сколько отправляется следующий автобус до аэропорта?',
    ),
  ];

  final List<Phrase> restaurant = [
    Phrase(
      category: 'Ресторан',
      text: 'Можно мне меню, пожалуйста?',
      translation: 'Can I have the menu, please?',
      example: 'Можно мне меню, пожалуйста?',
    ),
    Phrase(
      category: 'Ресторан',
      text: 'Я вегетарианец.',
      translation: 'I am a vegetarian.',
      example: 'Я вегетарианец. Есть ли у вас вегетарианские блюда?',
    ),
    Phrase(
      category: 'Ресторан',
      text: 'Счет, пожалуйста.',
      translation: 'The bill, please.',
      example: 'Счет, пожалуйста. Спасибо за обслуживание!',
    ),
  ];

  Future<void> _speak(String text, String lang) async {
    await flutterTts.setLanguage(lang);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  Widget _buildCategory(String title, List<Phrase> phrases, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...phrases.map((phrase) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(phrase.text,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phrase.translation,
                        style: const TextStyle(color: Colors.blueAccent)),
                    const SizedBox(height: 4),
                    Text('Пример: ${phrase.example}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _speak(phrase.translation, lang),
                  tooltip: 'Прослушать перевод',
                ),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Разговорник для путешествий'),
      ),
      body: ListView(
        children: [
          _buildCategory('Приветствия', greetings, 'en-US'),
          _buildCategory('Транспорт', transport, 'en-US'),
          _buildCategory('Ресторан', restaurant, 'en-US'),
        ],
      ),
    );
  }
}
