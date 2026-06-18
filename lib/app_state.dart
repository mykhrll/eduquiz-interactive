import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global state notifiers
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('id', 'ID'));
final ValueNotifier<bool> showChatbot = ValueNotifier(false);

// Initialize preferences
Future<void> initAppState() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Load Theme
  final themeStr = prefs.getString('themeMode') ?? 'light';
  if (themeStr == 'dark') {
    appThemeMode.value = ThemeMode.dark;
  } else if (themeStr == 'system') {
    appThemeMode.value = ThemeMode.system;
  } else {
    appThemeMode.value = ThemeMode.light;
  }

  // Load Locale
  final localeStr = prefs.getString('locale') ?? 'id';
  if (localeStr == 'en') {
    appLocale.value = const Locale('en', 'US');
  } else {
    appLocale.value = const Locale('id', 'ID');
  }

  // Add listeners to save automatically
  appThemeMode.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('themeMode', appThemeMode.value.name);
  });

  appLocale.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('locale', appLocale.value.languageCode);
  });
}

// Simple i18n helper function
String tr(String idText, String enText) {
  return appLocale.value.languageCode == 'en' ? enText : idText;
}
