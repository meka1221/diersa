import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки темы'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SwitchListTile(
                title: const Text('Темная тема'),
                value: themeProvider.settings.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Основной цвет',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorOption(context, themeProvider, Colors.blue),
                  _buildColorOption(context, themeProvider, Colors.red),
                  _buildColorOption(context, themeProvider, Colors.green),
                  _buildColorOption(context, themeProvider, Colors.purple),
                  _buildColorOption(context, themeProvider, Colors.orange),
                  _buildColorOption(context, themeProvider, Colors.teal),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Акцентный цвет',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAccentColorOption(
                      context, themeProvider, Colors.blueAccent),
                  _buildAccentColorOption(
                      context, themeProvider, Colors.redAccent),
                  _buildAccentColorOption(
                      context, themeProvider, Colors.greenAccent),
                  _buildAccentColorOption(
                      context, themeProvider, Colors.purpleAccent),
                  _buildAccentColorOption(
                      context, themeProvider, Colors.orangeAccent),
                  _buildAccentColorOption(
                      context, themeProvider, Colors.tealAccent),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorOption(
      BuildContext context, ThemeProvider themeProvider, Color color) {
    final isSelected = themeProvider.settings.primaryColor == color;
    return GestureDetector(
      onTap: () => themeProvider.updatePrimaryColor(color),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildAccentColorOption(
      BuildContext context, ThemeProvider themeProvider, Color color) {
    final isSelected = themeProvider.settings.accentColor == color;
    return GestureDetector(
      onTap: () => themeProvider.updateAccentColor(color),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
