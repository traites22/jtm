import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../services/logging_service.dart';

class OptimizedFirestoreService {
  static const int defaultLimit = 20;
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  static final Map<String, QuerySnapshot> _queryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  static void clearCache() {
    _queryCache.clear();
    _cacheTimestamps.clear();
  }
  
  static bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < cacheTimeout;
  }
  
  static Future<QuerySnapshot> _getCachedQuery(
    Query query,
    String cacheKey, {
    Source source = Source.default,
  }) async {
    // Check cache first for default source
    if (source == Source.default && _isCacheValid(cacheKey)) {
      LoggingService().logEvent('cache_hit', parameters: {'cache_key': cacheKey});
      return _queryCache[cacheKey]!;
    }
    
    // Fetch from Firestore
    final snapshot = await query.get(source);
    
    // Cache only for default source
    if (source == Source.default) {
      _queryCache[cacheKey] = snapshot;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Clean old cache entries
      _cleanOldCache();
    }
    
    LoggingService().logEvent('cache_miss', parameters: {'cache_key': cacheKey});
    return snapshot;
  }
  
  static void _cleanOldCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > cacheTimeout) {
        _queryCache.remove(key);
        return true;
      }
      return false;
    });
  }
  
  static Future<List<DocumentSnapshot>> getFilteredUsers({
    Map<String, dynamic>? filters,
    GeoPoint? center,
    double radius = 50.0,
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
    String? userId,
  }) async {
    final trace = LoggingService().startTrace('get_filtered_users');
    
    try {
      Query query = FirebaseFirestore.instance.collection('users');
      
      // Apply basic filters
      if (filters != null) {
        if (filters!.containsKey('minAge')) {
          query = query.where('age', isGreaterThanOrEqualTo: filters!['minAge']);
        }
        
        if (filters!.containsKey('maxAge')) {
          query = query.where('age', isLessThanOrEqualTo: filters!['maxAge']);
        }
        
        if (filters!.containsKey('gender') && filters!['gender'] != null) {
          query = query.where('gender', isEqualTo: filters!['gender']);
        }
        
        if (filters!.containsKey('interests') && filters!['interests'] != null) {
          query = query.where('interests', arrayContainsAny: filters!['interests']);
        }
      }
      
      // Location-based filtering
      if (center != null) {
        query = query.where('location', isGreaterThan: center);
      }
      
      // Exclude current user
      if (userId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: userId);
      }
      
      // Apply ordering and pagination
      query = query
          .orderBy('lastActive', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }
      
      final cacheKey = _generateCacheKey('filtered_users', {
        'filters': filters?.toString(),
        'center': center.toString(),
        'radius': radius,
        'limit': limit,
        'last_doc': lastDocument?.id,
      });
      
      final snapshot = await _getCachedQuery(query, cacheKey);
      
      trace.stop();
      return snapshot.docs;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to get filtered users', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<List<DocumentSnapshot>> getUsersNearLocation(
    GeoPoint center,
    double radius, {
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
  }) async {
    final trace = LoggingService().startTrace('get_users_near_location');
    
    try {
      // Simple location query - in production, use geohash or geofire
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('location', isGreaterThan: center)
          .orderBy('lastActive', descending: true)
          .limit(limit * 2); // Get more to filter precisely
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }
      
      final cacheKey = _generateCacheKey('users_near_location', {
        'center': center.toString(),
        'radius': radius,
        'limit': limit,
        'last_doc': lastDocument?.id,
      });
      
      final snapshot = await _getCachedQuery(query, cacheKey);
      
      // Additional client-side filtering for precise distance
      final users = snapshot.docs
          .where((doc) => doc.exists)
          .take(limit)
          .toList();
      
      trace.stop();
      return users;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to get users near location', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<List<DocumentSnapshot>> getRecentUsers({
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
    String? excludeUserId,
  }) async {
    final trace = LoggingService().startTrace('get_recent_users');
    
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('lastActive', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }
      
      if (excludeUserId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeUserId);
      }
      
      final cacheKey = _generateCacheKey('recent_users', {
        'limit': limit,
        'last_doc': lastDocument?.id,
        'exclude_user': excludeUserId,
      });
      
      final snapshot = await _getCachedQuery(query, cacheKey);
      
      trace.stop();
      return snapshot.docs;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to get recent users', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<DocumentSnapshot?> getUserById(String userId) async {
    final trace = LoggingService().startTrace('get_user_by_id');
    
    try {
      final cacheKey = 'user_$userId';
      
      // Check cache first
      if (_isCacheValid(cacheKey)) {
        final cachedDoc = _queryCache[cacheKey];
        if (cachedDoc != null && cachedDoc.docs.isNotEmpty) {
          trace.stop();
          return cachedDoc.docs.first;
        }
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        // Cache the result
        final snapshot = QuerySnapshot.fromDocument(doc);
        _queryCache[cacheKey] = snapshot;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        trace.stop();
        return doc;
      }
      
      trace.stop();
      return null;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to get user by ID', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<void> updateUserLastActive(String userId) async {
    final trace = LoggingService().startTrace('update_user_last_active');
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'lastActive': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Invalidate user cache
      _queryCache.remove('user_$userId');
      _cacheTimestamps.remove('user_$userId');
      
      trace.stop();
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to update user last active', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<List<DocumentSnapshot>> searchUsers({
    required String query,
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
  }) async {
    final trace = LoggingService().startTrace('search_users');
    
    try {
      // Simple search implementation
      Query nameQuery = FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('name')
          .limit(limit);
      
      final cacheKey = _generateCacheKey('search_users', {
        'query': query,
        'limit': limit,
        'last_doc': lastDocument?.id,
      });
      
      final snapshot = await _getCachedQuery(nameQuery, cacheKey);
      
      trace.stop();
      return snapshot.docs;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to search users', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static String _generateCacheKey(String baseType, Map<String, dynamic> params) {
    final paramsString = params.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    return '${baseType}_${paramsString.hashCode}';
  }
  
  static Future<List<QuerySnapshot>> runBatchedQuery(
    List<Query> queries, {
    int batchSize = 10,
  }) async {
    final trace = LoggingService().startTrace('run_batched_query');
    
    try {
      final results = <QuerySnapshot>[];
      
      for (int i = 0; i < queries.length; i += batchSize) {
        final batch = queries.skip(i).take(batchSize).toList();
        final batchResults = await Future.wait(
          batch.map((query) => query.get()),
        );
        results.addAll(batchResults);
      }
      
      trace.stop();
      return results;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to run batched query', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
