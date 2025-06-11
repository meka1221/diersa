import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextButton extends StatefulWidget {
  final Function(String) onTextRecognized;
  final String language;

  const SpeechToTextButton({
    super.key,
    required this.onTextRecognized,
    required this.language,
  });

  @override
  State<SpeechToTextButton> createState() => _SpeechToTextButtonState();
}

class _SpeechToTextButtonState extends State<SpeechToTextButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          if (_text.isNotEmpty) {
            widget.onTextRecognized(_text);
            _text = '';
          }
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка распознавания речи: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = '';
        });
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
          localeId: widget.language,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Распознавание речи недоступно'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      if (_text.isNotEmpty) {
        widget.onTextRecognized(_text);
        _text = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _text.isEmpty ? 'Слушаю...' : _text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        FloatingActionButton(
          onPressed: _isListening ? _stopListening : _startListening,
          child: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 20),
          mini: true,
          elevation: 2,
        ),
      ],
    );
  }
}
