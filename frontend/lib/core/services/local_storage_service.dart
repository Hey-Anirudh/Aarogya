import 'package:hive_flutter/hive_flutter.dart';

/// Hive Local Storage Service — offline caching and preferences
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late Box _userBox;
  late Box _cacheBox;

  /// Initialize Hive
  Future<void> initialize() async {
    await Hive.initFlutter();
    _userBox = await Hive.openBox('user_preferences');
    _cacheBox = await Hive.openBox('cache');
  }

  // ──────────────────────────────────────────────
  // USER PREFERENCES
  // ──────────────────────────────────────────────

  /// Save onboarding completion status
  Future<void> setOnboardingComplete(bool value) async {
    await _userBox.put('onboarding_complete', value);
  }

  bool get isOnboardingComplete => _userBox.get('onboarding_complete', defaultValue: false);

  /// Save cached user profile for offline access
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await _userBox.put('cached_profile', profile);
  }

  Map<String, dynamic>? get cachedUserProfile {
    final data = _userBox.get('cached_profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Save login state
  Future<void> setLoggedIn(bool value) async {
    await _userBox.put('is_logged_in', value);
  }

  bool get isLoggedIn => _userBox.get('is_logged_in', defaultValue: false);

  // ──────────────────────────────────────────────
  // CACHE OPERATIONS
  // ──────────────────────────────────────────────

  /// Cache any data with a key
  Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get cached data (returns null if expired or not found)
  dynamic getCachedData(String key, {int maxAgeMinutes = 30}) {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > maxAgeMinutes * 60 * 1000) return null; // Expired

    return cached['data'];
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  /// Clear everything (logout)
  Future<void> clearAll() async {
    await _userBox.clear();
    await _cacheBox.clear();
  }
}
