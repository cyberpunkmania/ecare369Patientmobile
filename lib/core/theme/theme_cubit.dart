import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/theme_config.dart';
import '../storage/local_storage.dart';

/// Manages light / dark theme toggle and persists preference.
class ThemeCubit extends Cubit<ThemeData> {
  final LocalStorage _localStorage;

  ThemeCubit({required LocalStorage localStorage})
    : _localStorage = localStorage,
      super(_initialTheme(localStorage));

  static ThemeData _initialTheme(LocalStorage ls) {
    final mode = ls.getThemeMode();
    return mode == 'dark' ? ThemeConfig.darkTheme : ThemeConfig.lightTheme;
  }

  bool get isDark => state.brightness == Brightness.dark;

  void toggleTheme() {
    if (isDark) {
      _localStorage.saveThemeMode('light');
      emit(ThemeConfig.lightTheme);
    } else {
      _localStorage.saveThemeMode('dark');
      emit(ThemeConfig.darkTheme);
    }
  }

  void setLight() {
    _localStorage.saveThemeMode('light');
    emit(ThemeConfig.lightTheme);
  }

  void setDark() {
    _localStorage.saveThemeMode('dark');
    emit(ThemeConfig.darkTheme);
  }
}
