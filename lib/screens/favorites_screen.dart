// lib/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:dearsa/models/translation_entry.dart';
import 'package:dearsa/services/favorites_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<TranslationEntry> _favoriteTranslations = [];
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _initializeTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
  }

  Future<void> _loadFavorites() async {
    final loadedFavorites = await _favoritesService.loadFavorites();
    setState(() {
      _favoriteTranslations = loadedFavorites;
    });
  }

  Future<void> _removeFavorite(String id) async {
    await _favoritesService.removeFavorite(id);
    _loadFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Translation removed from favorites.')),
    );
  }

  Future _speakText(String text, String langCode) async {
    if (text.isNotEmpty) {
      String ttsLangCode = langCode.toLowerCase();
      if (ttsLangCode == 'en') ttsLangCode = 'en-US';
      else if (ttsLangCode == 'ru') ttsLangCode = 'ru-RU';
      else if (ttsLangCode == 'de') ttsLangCode = 'de-DE';
      else if (ttsLangCode == 'fr') ttsLangCode = 'fr-FR';
      else if (ttsLangCode == 'es') ttsLangCode = 'es-ES';

      List<dynamic> languages = await flutterTts.getLanguages;
      if (languages.contains(ttsLangCode)) {
        await flutterTts.setLanguage(ttsLangCode);
      } else {
        print("TTS language $ttsLangCode not available. Using default.");
        await flutterTts.setLanguage('en-US');
      }
      await flutterTts.speak(text);
    }
  }

  void _copyText(String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Clear All Favorites',
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Clear All Favorites?'),
                    content: const Text('Are you sure you want to remove all saved translations from favorites?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(FavoritesService.favoritesKey); // <--- ИЗМЕНЕНО: Используем геттер
                _loadFavorites();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All favorites cleared.')),
                );
              }
            },
          ),
        ],
      ),
      body: _favoriteTranslations.isEmpty
          ? Center(
        child: Text(
          'No favorite translations yet. Save some from the main screen!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _favoriteTranslations.length,
        itemBuilder: (context, index) {
          final entry = _favoriteTranslations[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.originalText} (${entry.sourceLanguageCode.toUpperCase()})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${entry.translatedText} (${entry.targetLanguageCode.toUpperCase()})',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Saved: ${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () => _speakText(entry.translatedText, entry.targetLanguageCode),
                        tooltip: 'Speak translation',
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () => _copyText(entry.translatedText),
                        tooltip: 'Copy translation',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _removeFavorite(entry.id),
                        tooltip: 'Remove from favorites',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}