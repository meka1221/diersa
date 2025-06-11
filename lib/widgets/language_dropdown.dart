import 'package:flutter/material.dart';
import 'package:dearsa/models/language_model.dart'; // Updated for dearsa
import 'package:dearsa/utils/app_colors.dart'; // Updated for dearsa

class LanguageDropdown extends StatelessWidget {
  final List<Language> languages;
  final Language? selectedLanguage;
  final Function(Language?) onChanged;
  final String hintText;

  const LanguageDropdown({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Language>(
          isExpanded: true,
          hint: Text(hintText, style: const TextStyle(color: AppColors.textLight)),
          value: selectedLanguage,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: languages.map<DropdownMenuItem<Language>>((Language lang) {
            return DropdownMenuItem<Language>(
              value: lang,
              child: Text(lang.name, style: const TextStyle(color: AppColors.textDark)),
            );
          }).toList(),
          onChanged: onChanged,
          // Сравнение объектов по коду языка
          selectedItemBuilder: (BuildContext context) {
            return languages.map<Widget>((Language lang) {
              return Text(
                selectedLanguage?.name ?? hintText,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
        ),
      ),
    );
  }
}