// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dearsa/api/translator_api.dart';
import 'package:dearsa/models/language_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:dearsa/models/translation_entry.dart';
import 'package:dearsa/services/favorites_service.dart';
import 'package:dearsa/screens/favorites_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:dearsa/utils/debouncer.dart';
import 'package:dearsa/services/translation_history_service.dart';
import 'package:dearsa/screens/translation_history_screen.dart';
import 'package:dearsa/screens/theme_settings_screen.dart';
import 'package:dearsa/widgets/speech_to_text_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:dearsa/screens/phrasebook_screen.dart';
import 'package:dearsa/screens/meme_generator_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TranslatorApi _translatorApi = TranslatorApi();
  List<Language> _availableLanguages = [];
  Language? _selectedSourceLanguage;
  Language? _selectedTargetLanguage;
  TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  bool _isCurrentTranslationFavorite = false;
  TranslationEntry? _currentTranslationEntry;
  final FavoritesService _favoritesService = FavoritesService();
  TranslationHistoryService? _historyService;
  final Uuid _uuid = Uuid();

  late FlutterTts flutterTts;
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _initializeTts();
    _checkIfCurrentTranslationIsFavorite();
    _initializeHistoryService();

    _debouncer = Debouncer(delay: Duration(milliseconds: 700));
    _textController.addListener(_onTextInputChanged);
  }

  Future<void> _initializeHistoryService() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyService = TranslationHistoryService(prefs);
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextInputChanged); // Удаляем слушателя
    _textController.dispose();
    flutterTts.stop();
    _debouncer.dispose(); // <--- Важно: очищаем Debouncer
    super.dispose();
  }

  // --- НОВЫЙ МЕТОД: Обработка изменения текста ---
  void _onTextInputChanged() {
    // Если текст пустой, то очищаем перевод и сбрасываем статус избранного
    if (_textController.text.isEmpty) {
      setState(() {
        _translatedText = '';
        _isCurrentTranslationFavorite = false;
        _currentTranslationEntry = null;
      });
      _debouncer
          .dispose(); // Отменяем любой ожидающий перевод, если поле очищено
      return;
    }

    // Запускаем Debouncer. _performTranslation будет вызван только после
    // того, как пользователь перестанет печатать на 700 мс.
    _debouncer.run(() {
      _performTranslation();
    });
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts
        .setLanguage(_selectedTargetLanguage?.code.toLowerCase() ?? 'en-US');
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("Error: $msg");
      });
    });
  }

  Future _speakTranslatedText() async {
    if (_translatedText.isNotEmpty) {
      String ttsLangCode = _selectedTargetLanguage?.code.toLowerCase() ?? 'en';
      if (ttsLangCode == 'en')
        ttsLangCode = 'en-US';
      else if (ttsLangCode == 'ru')
        ttsLangCode = 'ru-RU';
      else if (ttsLangCode == 'de')
        ttsLangCode = 'de-DE';
      else if (ttsLangCode == 'fr')
        ttsLangCode = 'fr-FR';
      else if (ttsLangCode == 'es') ttsLangCode = 'es-ES';

      List<dynamic> languages = await flutterTts.getLanguages;
      if (languages.contains(ttsLangCode)) {
        await flutterTts.setLanguage(ttsLangCode);
      } else {
        print("TTS language $ttsLangCode not available. Using default.");
        await flutterTts.setLanguage('en-US');
      }

      await flutterTts.speak(_translatedText);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No translated text to speak.')),
      );
    }
  }

  void _copyTranslatedText() {
    if (_translatedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _translatedText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translated text copied to clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No translated text to copy.')),
      );
    }
  }

  Future<void> _pasteIntoInput() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
        // После вставки, запускаем debounce, чтобы перевести вставленный текст
        _onTextInputChanged();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text pasted from clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clipboard is empty or does not contain text.')),
      );
    }
  }

  void _clearInputText() {
    setState(() {
      _textController.clear();
      _translatedText = '';
      _isCurrentTranslationFavorite = false;
      _currentTranslationEntry = null;
    });
    _debouncer.dispose(); // Отменяем любой ожидающий перевод
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Input and translated text cleared.')),
    );
  }

  Future<void> _checkIfCurrentTranslationIsFavorite() async {
    if (_currentTranslationEntry != null) {
      bool isFav =
          await _favoritesService.isFavorite(_currentTranslationEntry!.id);
      setState(() {
        _isCurrentTranslationFavorite = isFav;
      });
    } else {
      setState(() {
        _isCurrentTranslationFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_translatedText.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Translate something first to add to favorites.')),
      );
      return;
    }

    if (_isCurrentTranslationFavorite) {
      if (_currentTranslationEntry != null) {
        await _favoritesService.removeFavorite(_currentTranslationEntry!.id);
        setState(() {
          _isCurrentTranslationFavorite = false;
          _currentTranslationEntry = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from favorites.')),
        );
      }
    } else {
      final newEntry = TranslationEntry(
        id: _uuid.v4(),
        originalText: _textController.text,
        translatedText: _translatedText,
        sourceLanguageCode: _selectedSourceLanguage?.code ?? 'auto',
        targetLanguageCode: _selectedTargetLanguage?.code ?? 'unknown',
        timestamp: DateTime.now(),
      );
      await _favoritesService.addFavorite(newEntry);
      setState(() {
        _isCurrentTranslationFavorite = true;
        _currentTranslationEntry = newEntry;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to favorites!')),
      );
    }
  }

  void _loadLanguages() {
    setState(() {
      _availableLanguages = [
        Language(code: 'sq', name: 'Albanian'),
        Language(code: 'ar', name: 'Arabic'),
        Language(code: 'bg', name: 'Bulgarian'),
        Language(code: 'zh', name: 'Chinese'),
        Language(code: 'hr', name: 'Croatian'),
        Language(code: 'cs', name: 'Czech'),
        Language(code: 'da', name: 'Danish'),
        Language(code: 'nl', name: 'Dutch'),
        Language(code: 'en', name: 'English'),
        Language(code: 'et', name: 'Estonian'),
        Language(code: 'fi', name: 'Finnish'),
        Language(code: 'fr', name: 'French'),
        Language(code: 'de', name: 'German'),
        Language(code: 'el', name: 'Greek'),
        Language(code: 'iw', name: 'Hebrew'),
        Language(code: 'hi', name: 'Hindi'),
        Language(code: 'hu', name: 'Hungarian'),
        Language(code: 'id', name: 'Indonesian'),
        Language(code: 'ga', name: 'Irish'),
        Language(code: 'it', name: 'Italian'),
        Language(code: 'ja', name: 'Japanese'),
        Language(code: 'ko', name: 'Korean'),
        Language(code: 'lv', name: 'Latvian'),
        Language(code: 'lt', name: 'Lithuanian'),
        Language(code: 'mk', name: 'Macedonian'),
        Language(code: 'ms', name: 'Malay'),
        Language(code: 'mt', name: 'Maltese'),
        Language(code: 'no', name: 'Norwegian'),
        Language(code: 'fa', name: 'Persian'),
        Language(code: 'pl', name: 'Polish'),
        Language(code: 'pt', name: 'Portuguese'),
        Language(code: 'ro', name: 'Romanian'),
        Language(code: 'ru', name: 'Russian'),
        Language(code: 'sr', name: 'Serbian'),
        Language(code: 'sk', name: 'Slovak'),
        Language(code: 'sl', name: 'Slovenian'),
        Language(code: 'es', name: 'Spanish'),
        Language(code: 'sv', name: 'Swedish'),
        Language(code: 'tl', name: 'Tagalog'),
        Language(code: 'th', name: 'Thai'),
        Language(code: 'tr', name: 'Turkish'),
        Language(code: 'uk', name: 'Ukrainian'),
        Language(code: 'ur', name: 'Urdu'),
        Language(code: 'vi', name: 'Vietnamese'),
        Language(code: 'cy', name: 'Welsh'),
        Language(code: 'yi', name: 'Yiddish'),
      ];

      _availableLanguages.insert(
          0, Language(code: 'auto', name: 'Detect Language'));

      _selectedSourceLanguage = _availableLanguages.firstWhere(
        (lang) => lang.code == 'auto',
        orElse: () => _availableLanguages.first,
      );
      _selectedTargetLanguage = _availableLanguages.firstWhere(
        (lang) => lang.code == 'ru',
        orElse: () => _availableLanguages.last,
      );
    });
  }

  Future<void> _performTranslation() async {
    if (_textController.text.isEmpty) return;

    try {
      final translatedText = await _translatorApi.translate(
        _textController.text,
        _selectedSourceLanguage?.code ?? 'auto',
        _selectedTargetLanguage?.code ?? 'en',
      );

      setState(() {
        _translatedText = translatedText;
      });

      // Сохраняем перевод в историю, если сервис инициализирован
      if (_historyService != null) {
        await _historyService!.addTranslation(
          sourceText: _textController.text,
          translatedText: translatedText,
          sourceLanguage: _selectedSourceLanguage?.name ?? 'Auto',
          targetLanguage: _selectedTargetLanguage?.name ?? 'English',
        );
      }

      // Создаем новую запись для избранного
      _currentTranslationEntry = TranslationEntry(
        id: _uuid.v4(),
        originalText: _textController.text,
        translatedText: translatedText,
        sourceLanguageCode: _selectedSourceLanguage?.code ?? 'auto',
        targetLanguageCode: _selectedTargetLanguage?.code ?? 'en',
        timestamp: DateTime.now(),
      );

      // Проверяем, есть ли этот перевод в избранном
      await _checkIfCurrentTranslationIsFavorite();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error translating text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _swapLanguages() {
    setState(() {
      final Language? temp = _selectedSourceLanguage;
      _selectedSourceLanguage = _selectedTargetLanguage;

      if (temp?.code == 'auto') {
        _selectedTargetLanguage = _availableLanguages.firstWhere(
            (lang) => lang.code == 'en',
            orElse: () =>
                _availableLanguages.firstWhere((lang) => lang.code != 'auto'));
      } else {
        _selectedTargetLanguage = temp;
      }

      _translatedText = '';
      _textController.clear();
      _isCurrentTranslationFavorite = false;
      _currentTranslationEntry = null;
      _initializeTts();
    });
    // Запускаем новый перевод после смены языка, если поле ввода не пустое
    _onTextInputChanged();
  }

  // --- Новый метод: Распознавание текста с фото ---
  Future<void> _pickAndRecognizeText() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    if (recognizedText.text.trim().isNotEmpty) {
      setState(() {
        _textController.text = recognizedText.text.trim();
      });
      _onTextInputChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Текст с фото распознан!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Текст на фото не найден.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dearsa Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Разговорник',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhrasebookScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mood),
            tooltip: 'Генератор мемов',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemeGeneratorScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _historyService == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TranslationHistoryScreen(
                          historyService: _historyService!,
                        ),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/animations/memes/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4), // затемнение
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInputField(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _performTranslation,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Translate (Manual)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Text(
                          _translatedText,
                          style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(context).colorScheme.onBackground),
                        ),
                      ),
                      if (_translatedText.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FloatingActionButton(
                                mini: true,
                                onPressed: _speakTranslatedText,
                                child: Icon(Icons.volume_up),
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                tooltip: 'Speak translated text',
                              ),
                              SizedBox(width: 8),
                              FloatingActionButton(
                                mini: true,
                                onPressed: _copyTranslatedText,
                                child: Icon(Icons.copy),
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                tooltip: 'Copy translated text',
                              ),
                              SizedBox(width: 8),
                              FloatingActionButton(
                                mini: true,
                                onPressed: _toggleFavorite,
                                child: Icon(
                                  _isCurrentTranslationFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isCurrentTranslationFavorite
                                      ? Colors.redAccent
                                      : null,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                tooltip: _isCurrentTranslationFavorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter text to translate',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.paste, size: 20),
                        onPressed: _pasteIntoInput,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Вставить',
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearInputText,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Очистить',
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_camera, size: 20),
                        onPressed: _pickAndRecognizeText,
                        tooltip: 'Распознать текст с фото',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 2, top: 2),
                        child: SpeechToTextButton(
                          onTextRecognized: (text) {
                            setState(() {
                              _textController.text = text;
                            });
                          },
                          language: _selectedSourceLanguage?.code ?? 'en',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<Language>(
                value: _selectedSourceLanguage,
                hint: const Text('From'),
                items: _availableLanguages.map((Language language) {
                  return DropdownMenuItem<Language>(
                    value: language,
                    child: Text(language.name),
                  );
                }).toList(),
                onChanged: (Language? newValue) {
                  setState(() {
                    _selectedSourceLanguage = newValue;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: _swapLanguages,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              DropdownButton<Language>(
                value: _selectedTargetLanguage,
                hint: const Text('To'),
                items: _availableLanguages.map((Language language) {
                  return DropdownMenuItem<Language>(
                    value: language,
                    child: Text(language.name),
                  );
                }).toList(),
                onChanged: (Language? newValue) {
                  setState(() {
                    _selectedTargetLanguage = newValue;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
