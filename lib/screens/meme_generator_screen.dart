import 'package:flutter/material.dart';
import 'package:dearsa/api/translator_api.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class MemeGeneratorScreen extends StatefulWidget {
  const MemeGeneratorScreen({super.key});

  @override
  State<MemeGeneratorScreen> createState() => _MemeGeneratorScreenState();
}

class _MemeGeneratorScreenState extends State<MemeGeneratorScreen> {
  final TextEditingController _controller = TextEditingController();
  String _translatedText = '';
  bool _isLoading = false;
  final TranslatorApi _translatorApi = TranslatorApi();
  String _selectedLang = 'en';
  final GlobalKey _memeKey = GlobalKey();

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'de', 'name': 'Deutsch'},
  ];

  Future<void> _generateMeme() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    if (_selectedLang == 'en') {
      setState(() {
        _translatedText = _controller.text.trim();
        _isLoading = false;
      });
      return;
    }
    final translated = await _translatorApi.translate(
      _controller.text.trim(),
      'auto',
      _selectedLang,
    );
    setState(() {
      _translatedText = translated;
      _isLoading = false;
    });
  }

  Future<void> _saveAndShareMeme() async {
    try {
      RenderRepaintBoundary boundary =
          _memeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/meme.png').create();
      await file.writeAsBytes(pngBytes);
      if (!mounted) return;
      await Share.shareFiles([file.path], text: 'Мой мем!');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении/отправке: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Генератор мемов: Котик')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/animations/memes/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Введите фразу для мема',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Язык подписи:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedLang,
                        items: _languages
                            .map((lang) => DropdownMenuItem<String>(
                                  value: lang['code'],
                                  child: Text(lang['name']!),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedLang = val!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _generateMeme,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Сгенерировать мем'),
                  ),
                  const SizedBox(height: 24),
                  if (_translatedText.isNotEmpty)
                    Column(
                      children: [
                        RepaintBoundary(
                          key: _memeKey,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Фон
                              Image.asset(
                                'assets/animations/memes/background.png',
                                width: 320,
                                height: 320,
                                fit: BoxFit.cover,
                              ),
                              // Котик поверх фона
                              Opacity(
                                opacity: 0.95,
                                child: Image.asset(
                                  'assets/animations/memes/cat_meme.jpg',
                                  width: 220,
                                  height: 220,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Текст
                              Positioned(
                                bottom: 24,
                                left: 10,
                                right: 10,
                                child: Text(
                                  _translatedText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _saveAndShareMeme,
                          icon: const Icon(Icons.share),
                          label: const Text('Сохранить или поделиться'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
