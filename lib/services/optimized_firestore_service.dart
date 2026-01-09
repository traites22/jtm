import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/user.dart';
import '../models/filter_model.dart';
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
  
  static Future<List<UserModel>> getFilteredUsers({
    FilterModel? filters,
    GeoPoint? center,
    double radius = 50.0,
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
    String? userId,
  }) async {
    final trace = LoggingService().startTrace('get_filtered_users');
    
    try {
      Query query = FirebaseFirestore.instance.collection('users');
      
      // Apply filters
      if (filters?.minAge != null) {
        query = query.where('age', isGreaterThanOrEqualTo: filters!.minAge);
      }
      
      if (filters?.maxAge != null) {
        query = query.where('age', isLessThanOrEqualTo: filters!.maxAge);
      }
      
      if (filters?.gender != null && filters!.gender!.isNotEmpty) {
        query = query.where('gender', isEqualTo: filters!.gender);
      }
      
      if (filters?.interests != null && filters!.interests!.isNotEmpty) {
        query = query.where('interests', arrayContainsAny: filters!.interests);
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
        'filters': filters?.toJson(),
        'center': center,
        'radius': radius,
        'limit': limit,
        'last_doc': lastDocument?.id,
      });
      
      final snapshot = await _getCachedQuery(query, cacheKey);
      
      final users = snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      trace.stop();
      return users;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to get filtered users', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<List<UserModel>> getUsersNearLocation(
    GeoPoint center,
    double radius, {
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
  }) async {
    final trace = LoggingService().startTrace('get_users_near_location');
    
    try {
      // Calculate bounding box for location query
      final earthRadius = 6371; // km
      final latDistance = radius / earthRadius;
      final lonDistance = radius / (earthRadius * cos(center.latitude * pi / 180));
      
      final minLat = center.latitude - latDistance * 180 / pi;
      final maxLat = center.latitude + latDistance * 180 / pi;
      final minLon = center.longitude - lonDistance * 180 / pi;
      final maxLon = center.longitude + lonDistance * 180 / pi;
      
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('location.latitude', isGreaterThanOrEqualTo: minLat)
          .where('location.latitude', isLessThanOrEqualTo: maxLat)
          .orderBy('location.latitude')
          .orderBy('location.longitude')
          .limit(limit * 2); // Get more to filter precisely
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }
      
      final cacheKey = _generateCacheKey('users_near_location', {
        'center': center,
        'radius': radius,
        'limit': limit,
        'last_doc': lastDocument?.id,
      });
      
      final snapshot = await _getCachedQuery(query, cacheKey);
      
      // Additional client-side filtering for precise distance
      final users = snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            if (user.location == null) return false;
            final distance = _calculateDistance(center, user.location!);
            return distance <= radius;
          })
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
  
  static Future<List<UserModel>> getRecentUsers({
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
      
      final users = snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      trace.stop();
      return users;
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to get recent users', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<UserModel?> getUserById(String userId) async {
    final trace = LoggingService().startTrace('get_user_by_id');
    
    try {
      final cacheKey = 'user_$userId';
      
      // Check cache first
      if (_isCacheValid(cacheKey)) {
        final cachedDoc = _queryCache[cacheKey];
        if (cachedDoc != null && cachedDoc.docs.isNotEmpty) {
          trace.stop();
          return UserModel.fromFirestore(cachedDoc.docs.first);
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
        return UserModel.fromFirestore(doc);
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
  
  static Future<List<UserModel>> searchUsers({
    required String query,
    int limit = defaultLimit,
    DocumentSnapshot? lastDocument,
  }) async {
    final trace = LoggingService().startTrace('search_users');
    
    try {
      // Use Firestore's full-text search capabilities
      Query nameQuery = FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('name')
          .limit(limit);
      
      Query bioQuery = FirebaseFirestore.instance
          .collection('users')
          .where('bio', isGreaterThanOrEqualTo: query)
          .where('bio', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('bio')
          .limit(limit);
      
      final cacheKey = _generateCacheKey('search_users', {
        'query': query,
        'limit': limit,
        'last_doc': lastDocument?.id,
      });
      
      // Run both queries in parallel
      final results = await Future.wait([
        _getCachedQuery(nameQuery, '${cacheKey}_name'),
        _getCachedQuery(bioQuery, '${cacheKey}_bio'),
      ]);
      
      // Combine and deduplicate results
      final allDocs = <DocumentSnapshot>[];
      final seenIds = <String>{};
      
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          if (doc.exists && !seenIds.contains(doc.id)) {
            allDocs.add(doc);
            seenIds.add(doc.id);
          }
        }
      }
      
      // Sort by relevance (simple implementation)
      allDocs.sort((a, b) {
        final aName = a.get('name')?.toString().toLowerCase() ?? '';
        final bName = b.get('name')?.toString().toLowerCase() ?? '';
        final aBio = a.get('bio')?.toString().toLowerCase() ?? '';
        final bBio = b.get('bio')?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();
        
        // Calculate relevance score
        final aScore = _calculateRelevance(aName, aBio, queryLower);
        final bScore = _calculateRelevance(bName, bBio, queryLower);
        
        return bScore.compareTo(aScore);
      });
      
      final users = allDocs
          .take(limit)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      trace.stop();
      return users;
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
  
  static double _calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // km
    
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _calculateRelevance(String name, String bio, String query) {
    double score = 0.0;
    
    // Name matches are more important
    if (name.contains(query)) {
      if (name.startsWith(query)) {
        score += 10.0; // Exact prefix match
      } else if (name == query) {
        score += 20.0; // Exact match
      } else {
        score += 5.0; // Partial match
      }
    }
    
    // Bio matches are less important
    if (bio.contains(query)) {
      score += 2.0;
    }
    
    return score;
  }
  
  static Future<QuerySnapshot> runBatchedQuery(
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
      return QuerySnapshot.fromDocuments(
        results.expand((snapshot) => snapshot.docs).toList(),
      );
    } catch (e, stackTrace) {
      trace.stop();
      LoggingService().logError('Failed to run batched query', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
