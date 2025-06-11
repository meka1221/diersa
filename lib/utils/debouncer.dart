// lib/utils/debouncer.dart

import 'dart:async';
import 'package:flutter/foundation.dart'; // Для @visibleForTesting, если понадобится

class Debouncer {
  final Duration delay; // Задержка перед выполнением действия
  Timer? _timer;       // Таймер

  Debouncer({required this.delay});

  // Метод для выполнения действия
  void run(VoidCallback action) {
    _timer?.cancel(); // Отменяем предыдущий таймер, если он есть
    _timer = Timer(delay, action); // Устанавливаем новый таймер
  }

  // Метод для отмены текущего таймера (например, при уничтожении виджета)
  void dispose() {
    _timer?.cancel();
  }
}