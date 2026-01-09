import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/logging_service.dart';

class CacheManager {
  static const String _cacheBoxName = 'app_cache';
  static const Duration _defaultTtl = Duration(hours: 1);
  static const int _maxCacheSize = 100; // Maximum number of items
  
  static late Box<Map<dynamic>> _cacheBox;
  static bool _initialized = false;
  
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _initialized = true;
      LoggingService().logEvent('cache_initialized');
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to initialize cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
  
  static Future<T?> get<T>(String key, {Duration? ttl}) async {
    await ensureInitialized();
    
    try {
      final cacheEntry = _cacheBox.get(key);
      if (cacheEntry == null) return null;
      
      final entry = CacheEntry.fromJson(Map<String, dynamic>.from(cacheEntry));
      
      // Check if expired
      if (_isExpired(entry, ttl ?? _defaultTtl)) {
        await remove(key);
        return null;
      }
      
      LoggingService().logEvent('cache_hit', parameters: {'key': key});
      return entry.data as T?;
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to get from cache', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  static Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    await ensureInitialized();
    
    try {
      final entry = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl ?? _defaultTtl,
      );
      
      await _cacheBox.put(key, entry.toJson());
      
      // Clean old entries if cache is full
      await _cleanCacheIfNeeded();
      
      LoggingService().logEvent('cache_set', parameters: {'key': key});
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to set cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<void> remove(String key) async {
    await ensureInitialized();
    
    try {
      await _cacheBox.delete(key);
      LoggingService().logEvent('cache_remove', parameters: {'key': key});
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to remove from cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<void> clear() async {
    await ensureInitialized();
    
    try {
      await _cacheBox.clear();
      LoggingService().logEvent('cache_cleared');
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to clear cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<bool> exists(String key) async {
    await ensureInitialized();
    
    try {
      final cacheEntry = _cacheBox.get(key);
      if (cacheEntry == null) return false;
      
      final entry = CacheEntry.fromJson(Map<String, dynamic>.from(cacheEntry));
      return !_isExpired(entry, _defaultTtl);
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to check cache existence', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  static Future<Map<String, dynamic>> getAll() async {
    await ensureInitialized();
    
    try {
      final allEntries = <String, dynamic>{};
      
      for (final key in _cacheBox.keys) {
        final cacheEntry = _cacheBox.get(key);
        if (cacheEntry != null) {
          final entry = CacheEntry.fromJson(Map<String, dynamic>.from(cacheEntry));
          
          // Only include non-expired entries
          if (!_isExpired(entry, _defaultTtl)) {
            allEntries[key] = entry.data;
          } else {
            // Remove expired entry
            await _cacheBox.delete(key);
          }
        }
      }
      
      return allEntries;
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to get all cache entries', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  static Future<void> setAll(Map<String, dynamic> entries, {Duration? ttl}) async {
    await ensureInitialized();
    
    try {
      final now = DateTime.now();
      
      for (final entry in entries.entries) {
        final cacheEntry = CacheEntry(
          data: entry.value,
          timestamp: now,
          ttl: ttl ?? _defaultTtl,
        );
        
        await _cacheBox.put(entry.key, cacheEntry.toJson());
      }
      
      await _cleanCacheIfNeeded();
      LoggingService().logEvent('cache_set_all', parameters: {'count': entries.length});
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to set all cache entries', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<int> size() async {
    await ensureInitialized();
    return _cacheBox.length;
  }
  
  static Future<List<String>> keys() async {
    await ensureInitialized();
    return _cacheBox.keys.cast<String>();
  }
  
  static Future<void> _cleanCacheIfNeeded() async {
    if (await size() > _maxCacheSize) {
      final entries = await getAll();
      final sortedEntries = entries.entries.toList()
        ..sort((a, b) {
          final aEntry = CacheEntry.fromJson(Map<String, dynamic>.from(await _cacheBox.get(a.key)));
          final bEntry = CacheEntry.fromJson(Map<String, dynamic>.from(await _cacheBox.get(b.key)));
          return aEntry.timestamp.compareTo(bEntry.timestamp);
        });
      
      // Remove oldest entries to maintain size limit
      final entriesToRemove = sortedEntries.length - _maxCacheSize;
      for (int i = 0; i < entriesToRemove; i++) {
        await _cacheBox.delete(sortedEntries[i].key);
      }
      
      LoggingService().logEvent('cache_cleaned', parameters: {'removed_count': entriesToRemove});
    }
  }
  
  static bool _isExpired(CacheEntry entry, Duration ttl) {
    return DateTime.now().difference(entry.timestamp) > ttl;
  }
  
  static Future<void> exportCache() async {
    await ensureInitialized();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final allEntries = await getAll();
      
      await prefs.setString('cache_export', jsonEncode(allEntries));
      LoggingService().logEvent('cache_exported', parameters: {'entries_count': allEntries.length});
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to export cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<void> importCache() async {
    await ensureInitialized();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final exportData = prefs.getString('cache_export');
      
      if (exportData != null) {
        final entries = jsonDecode(exportData) as Map<String, dynamic>;
        await setAll(entries.cast<String, dynamic>());
        LoggingService().logEvent('cache_imported', parameters: {'entries_count': entries.length});
      }
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to import cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> getCacheStats() async {
    await ensureInitialized();
    
    try {
      final allKeys = await keys();
      int expiredCount = 0;
      int validCount = 0;
      final now = DateTime.now();
      
      for (final key in allKeys) {
        final cacheEntry = _cacheBox.get(key);
        if (cacheEntry != null) {
          final entry = CacheEntry.fromJson(Map<String, dynamic>.from(cacheEntry));
          if (_isExpired(entry, _defaultTtl)) {
            expiredCount++;
          } else {
            validCount++;
          }
        }
      }
      
      return {
        'total_entries': allKeys.length,
        'valid_entries': validCount,
        'expired_entries': expiredCount,
        'cache_size_mb': await _getCacheSizeMB(),
        'last_cleanup': _getLastCleanupTime(),
      };
    } catch (e, stackTrace) {
      LoggingService().logError('Failed to get cache stats', error: e, stackTrace: stackTrace);
      return {};
    }
  }
  
  static Future<double> _getCacheSizeMB() async {
    try {
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        final size = await cacheFile.length();
        return size / (1024 * 1024); // Convert to MB
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
  
  static Future<File> _getCacheFile() async {
    // This is a simplified implementation
    // In a real app, you'd get the actual Hive file path
    final dir = await Hive.getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheBoxName.hive');
  }
  
  static String _getLastCleanupTime() {
    // Simplified - in real implementation, store last cleanup time
    return DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
    };
  }
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
    );
  }
}

class SmartCache<T> {
  final String prefix;
  final Duration? defaultTtl;
  final int? maxSize;
  
  SmartCache({
    required this.prefix,
    this.defaultTtl,
    this.maxSize,
  });
  
  Future<T?> get(String key) async {
    return CacheManager.get<T>('${prefix}_$key', ttl: defaultTtl);
  }
  
  Future<void> set(String key, T data, {Duration? ttl}) async {
    await CacheManager.set('${prefix}_$key', data, ttl: ttl ?? defaultTtl);
  }
  
  Future<void> remove(String key) async {
    await CacheManager.remove('${prefix}_$key');
  }
  
  Future<void> clear() async {
    final keys = await CacheManager.keys();
    final keysToRemove = keys.where((key) => key.startsWith('${prefix}_')).toList();
    
    for (final key in keysToRemove) {
      await CacheManager.remove(key);
    }
  }
  
  Future<bool> exists(String key) async {
    return CacheManager.exists('${prefix}_$key');
  }
  
  Future<Map<String, T>> getAll() async {
    final allEntries = await CacheManager.getAll();
    final filteredEntries = <String, T>{};
    
    allEntries.forEach((key, value) {
      if (key.startsWith('${prefix}_')) {
        final actualKey = key.substring(prefix.length + 1);
        filteredEntries[actualKey] = value as T;
      }
    });
    
    return filteredEntries;
  }
}

// Specialized cache types for different data
class UserCache extends SmartCache<Map<String, dynamic>> {
  UserCache() : super(prefix: 'user', defaultTtl: const Duration(minutes: 30));
}

class ProfileCache extends SmartCache<Map<String, dynamic>> {
  ProfileCache() : super(prefix: 'profile', defaultTtl: const Duration(hours: 2));
}

class ImageCache extends SmartCache<String> {
  ImageCache() : super(prefix: 'image', defaultTtl: const Duration(days: 7));
}

class SearchCache extends SmartCache<List<String>> {
  SearchCache() : super(prefix: 'search', defaultTtl: const Duration(minutes: 15));
}

class FilterCache extends SmartCache<Map<String, dynamic>> {
  FilterCache() : super(prefix: 'filter', defaultTtl: const Duration(hours: 24));
}
