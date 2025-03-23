// filepath: /Users/kristybock/neuse_news_rebuild/lib/providers/app_settings_provider.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/local_storage.dart';

/// Provider for app settings and preferences
class AppSettingsProvider extends ChangeNotifier {
  final LocalStorage _localStorage = LocalStorage();
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  String _preferredFontSize = 'medium';
  bool _initialized = false;
  PackageInfo? _packageInfo;

  AppSettingsProvider() {
    _initializeStorage();
  }

  /// Initialize storage and load settings
  Future<void> _initializeStorage() async {
    await _localStorage.initialize();
    await _loadSettings();
    _initialized = true;
  }

  /// Current theme mode (light, dark, system)
  ThemeMode get themeMode => _themeMode;

  /// Whether notifications are enabled
  bool get notificationsEnabled => _notificationsEnabled;

  /// Preferred font size
  String get preferredFontSize => _preferredFontSize;

  /// Whether the provider has been initialized
  bool get initialized => _initialized;

  /// The current app version (for analytics and error reporting)
  String get appVersion => _packageInfo?.version ?? '1.0.0';

  /// Load settings from local storage
  Future<void> _loadSettings() async {
    // Load theme preference
    final themePref = _localStorage.getString('theme_preference');
    if (themePref != null) {
      switch (themePref) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }

    // Load notification preference
    final notificationsPref = _localStorage.getBool('notifications_enabled');
    if (notificationsPref != null) {
      _notificationsEnabled = notificationsPref;
    }

    // Load font size preference
    final fontSizePref = _localStorage.getString('preferred_font_size');
    if (fontSizePref != null) {
      _preferredFontSize = fontSizePref;
    }

    notifyListeners();
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String value;

    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }

    await _localStorage.setString('theme_preference', value);
    notifyListeners();
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _localStorage.setBool('notifications_enabled', enabled);
    notifyListeners();
  }

  /// Set preferred font size
  Future<void> setFontSize(String size) async {
    _preferredFontSize = size;
    await _localStorage.setString('preferred_font_size', size);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _notificationsEnabled = true;
    _preferredFontSize = 'medium';

    await _localStorage.remove('theme_preference');
    await _localStorage.remove('notifications_enabled');
    await _localStorage.remove('preferred_font_size');

    notifyListeners();
  }

  /// Initialize package info
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }

    // Other initialization code
  }
}
