// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Для проверки состояния регистрации
import 'package:provider/provider.dart';
import 'services/theme_provider.dart';

import 'package:dearsa/screens/home_screen.dart';
import 'package:dearsa/screens/onboarding_screen.dart'; // <--- ИЗМЕНЕНО: Используем OnboardingScreen
import 'package:dearsa/screens/registration_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('isRegistered') ??
        false; // Или 'isLoggedIn', если у вас такой флаг
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final settings = themeProvider.settings;
        return MaterialApp(
          title: 'Dearsa',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness:
                settings.isDarkMode ? Brightness.dark : Brightness.light,
            primaryColor: settings.primaryColor,
            colorScheme: ColorScheme(
              brightness:
                  settings.isDarkMode ? Brightness.dark : Brightness.light,
              primary: settings.primaryColor,
              secondary: settings.accentColor,
              surface: settings.isDarkMode ? Colors.grey[900]! : Colors.white,
              background:
                  settings.isDarkMode ? Colors.grey[900]! : Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onSurface: settings.isDarkMode ? Colors.white70 : Colors.black87,
              onBackground:
                  settings.isDarkMode ? Colors.white70 : Colors.black87,
              error: Colors.red.shade700,
              onError: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: FutureBuilder<bool>(
            future:
                _checkUserStatus(), // Выполняем проверку статуса пользователя
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Пока данные загружаются, показываем индикатор загрузки
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                // Если произошла ошибка при загрузке данных
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }
                // Если пользователь "зарегистрирован" / "вошел"
                else if (snapshot.data == true) {
                  return HomeScreen(); // Показываем основной экран
                }

                else {

                  return OnboardingScreen();

                }
              }
            },
          ),
        );
      },
    );
  }
}
