// filepath: /Users/kristybock/neuse_news_rebuild/lib/utils/local_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Utility for handling local storage operations
class LocalStorage {
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Initialize the storage
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Error initializing shared preferences: $e');
    }
  }

  /// Get a string value from storage
  Future<String?> getValue(String key) async {
    if (_prefs == null) await initialize();
    return _prefs?.getString(key);
  }

  /// Save a string value to storage
  Future<bool> saveValue(String key, String value) async {
    if (_prefs == null) await initialize();
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Save a boolean value to storage
  Future<bool> saveBool(String key, bool value) async {
    if (_prefs == null) await initialize();
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Get a boolean value from storage
  Future<bool?> getBoolAsync(String key) async {
    if (_prefs == null) await initialize();
    return _prefs?.getBool(key);
  }

  /// Save a list of strings to storage
  Future<bool> setStringList(String key, List<String> values) async {
    if (_prefs == null) await initialize();
    return await _prefs?.setStringList(key, values) ?? false;
  }

  /// Get a list of strings from storage
  Future<List<String>?> getStringList(String key) async {
    if (_prefs == null) await initialize();
    return _prefs?.getStringList(key);
  }

  /// Save favorite articles to local storage
  Future<bool> saveFavoriteArticles(List<String> articleIds) async {
    return setStringList('favorite_articles', articleIds);
  }

  /// Get favorite articles from local storage
  Future<List<String>?> getFavoriteArticles() async {
    return getStringList('favorite_articles');
  }

  /// Save read articles to local storage
  Future<bool> saveReadArticles(List<String> articleIds) async {
    return setStringList('read_articles', articleIds);
  }

  /// Get read articles from local storage
  Future<List<String>?> getReadArticles() async {
    return getStringList('read_articles');
  }

  /// Clear all data from storage
  Future<bool> clearAll() async {
    if (_prefs == null) await initialize();
    return await _prefs?.clear() ?? false;
  }

  /// Remove a specific key from storage
  Future<bool> remove(String key) async {
    if (_prefs == null) await initialize();
    return await _prefs?.remove(key) ?? false;
  }

  /// Store a secure string in encrypted storage
  Future<void> setSecureString(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  /// Get a secure string from encrypted storage
  Future<String?> getSecureString(String key) {
    return _secureStorage.read(key: key);
  }

  /// Remove a secure item from encrypted storage
  Future<void> removeSecure(String key) {
    return _secureStorage.delete(key: key);
  }

  /// Clear all secure storage
  Future<void> clearSecure() {
    return _secureStorage.deleteAll();
  }

  /// Store an object as JSON
  Future<bool> setObject(String key, Map<String, dynamic> value) {
    return _prefs?.setString(key, jsonEncode(value)) ?? Future.value(false);
  }

  /// Get an object from storage
  Future<Map<String, dynamic>?> getObject(String key) async {
    if (_prefs == null) await initialize();
    final String? jsonString = _prefs?.getString(key);
    if (jsonString == null) {
      return null;
    }
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Save purchased features to local storage
  Future<bool> savePurchasedFeatures(List<String> features) {
    return setStringList('purchased_features', features);
  }

  /// Get purchased features from local storage
  Future<List<String>?> getPurchasedFeatures() async {
    return getStringList('purchased_features');
  }

  /// Get a string value synchronously - returns cached value
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Save a string value synchronously
  Future<bool> setString(String key, String value) async {
    if (_prefs == null) await initialize();
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Get a boolean value synchronously
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Save a boolean value synchronously
  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) await initialize();
    return await _prefs?.setBool(key, value) ?? false;
  }
}
