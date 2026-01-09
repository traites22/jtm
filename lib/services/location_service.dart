import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_service.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permission denied');
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('✅ Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Failed to get current location: $e');
      return null;
    }
  }

  // Get address from coordinates
  static Future<Map<String, String>?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await Geocoding.placemarkFromCoordinates(
        Coordinates(latitude, longitude),
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return {
          'street': place.street,
          'city': place.locality,
          'state': place.administrativeArea,
          'country': place.country,
          'postalCode': place.postalCode,
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get address: $e');
      return null;
    }
  }

  // Get coordinates from address
  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await Geocoding.locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        return {'latitude': location.latitude, 'longitude': location.longitude};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get coordinates: $e');
      return null;
    }
  }

  // Calculate distance between two points in kilometers
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        (dLat * dLat).sin() + (dLon * dLon).cos() * _toRadians(lat1).cos() * (dLat * dLat).cos();

    double c = 2 * (a).sqrt().atan2((1 - a).sqrt(), a.sqrt());

    return earthRadius * c;
  }

  // Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (3.141592653589793238 / 180);
  }

  // Update user location in Firestore
  static Future<void> updateUserLocation(String userId, Position position) async {
    try {
      Map<String, String>? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await _firestore.collection('users').doc(userId).update({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        },
        'address': address,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User location updated');
    } catch (e) {
      debugPrint('❌ Failed to update user location: $e');
    }
  }

  // Get users within a certain distance
  static Future<List<DocumentSnapshot>> getUsersWithinDistance(
    double centerLatitude,
    double centerLongitude,
    double maxDistanceKm, {
    int limit = 50,
    String? excludeUserId,
  }) async {
    try {
      // Get all users with location data
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('location.latitude', isNotNull)
          .where('location.longitude', isNotNull)
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit * 2) // Get more to filter by distance
          .get();

      List<DocumentSnapshot> nearbyUsers = [];

      for (DocumentSnapshot doc in snapshot.docs) {
        if (doc.id == excludeUserId) continue;

        Map<String, dynamic> locationData = doc.get('location') as Map<String, dynamic>;
        double userLat = locationData['latitude'];
        double userLon = locationData['longitude'];

        double distance = calculateDistance(centerLatitude, centerLongitude, userLat, userLon);

        if (distance <= maxDistanceKm) {
          nearbyUsers.add(doc);

          if (nearbyUsers.length >= limit) break;
        }
      }

      debugPrint('✅ Found ${nearbyUsers.length} users within $maxDistanceKm km');
      return nearbyUsers;
    } catch (e) {
      debugPrint('❌ Failed to get users within distance: $e');
      return [];
    }
  }

  // Get users within age range and distance
  static Future<List<DocumentSnapshot>> getUsersNearbyWithFilters({
    required double centerLatitude,
    required double centerLongitude,
    required double maxDistanceKm,
    required int minAge,
    required int maxAge,
    String? excludeUserId,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('location.latitude', isNotNull)
          .where('location.longitude', isNotNull)
          .where('age', isGreaterThanOrEqualTo: minAge)
          .where('age', isLessThanOrEqualTo: maxAge)
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit * 2)
          .get();

      List<DocumentSnapshot> nearbyUsers = [];

      for (DocumentSnapshot doc in snapshot.docs) {
        if (doc.id == excludeUserId) continue;

        Map<String, dynamic> locationData = doc.get('location') as Map<String, dynamic>;
        double userLat = locationData['latitude'];
        double userLon = locationData['longitude'];

        double distance = calculateDistance(centerLatitude, centerLongitude, userLat, userLon);

        if (distance <= maxDistanceKm) {
          nearbyUsers.add(doc);

          if (nearbyUsers.length >= limit) break;
        }
      }

      debugPrint('✅ Found ${nearbyUsers.length} users matching criteria');
      return nearbyUsers;
    } catch (e) {
      debugPrint('❌ Failed to get users with filters: $e');
      return [];
    }
  }

  // Get distance between two users
  static Future<double?> getDistanceBetweenUsers(String userId1, String userId2) async {
    try {
      DocumentSnapshot user1Doc = await _firestore.collection('users').doc(userId1).get();
      DocumentSnapshot user2Doc = await _firestore.collection('users').doc(userId2).get();

      if (!user1Doc.exists || !user2Doc.exists) {
        return null;
      }

      Map<String, dynamic>? location1 = user1Doc.get('location') as Map<String, dynamic>?;
      Map<String, dynamic>? location2 = user2Doc.get('location') as Map<String, dynamic>?;

      if (location1 == null || location2 == null) {
        return null;
      }

      return calculateDistance(
        location1['latitude'],
        location1['longitude'],
        location2['latitude'],
        location2['longitude'],
      );
    } catch (e) {
      debugPrint('❌ Failed to calculate distance between users: $e');
      return null;
    }
  }

  // Get location updates stream
  static Stream<Position> getLocationUpdates({
    LocationSettings? locationSettings,
    double distanceFilter = 0.0,
  }) {
    return Geolocator.getPositionStream(
      locationSettings:
          locationSettings ??
          const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: distanceFilter),
    );
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      debugPrint('📍 Location permission: $permission');
      return permission;
    } catch (e) {
      debugPrint('❌ Failed to request location permission: $e');
      return LocationPermission.denied;
    }
  }

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('❌ Failed to check location service status: $e');
      return false;
    }
  }

  // Get location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('❌ Failed to check location permission: $e');
      return LocationPermission.denied;
    }
  }

  // Open location settings
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      debugPrint('📍 Opened location settings');
    } catch (e) {
      debugPrint('❌ Failed to open location settings: $e');
    }
  }

  // Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)} km';
    }
  }

  // Validate location data
  static bool isValidLocation(Map<String, dynamic>? location) {
    if (location == null) return false;

    return location.containsKey('latitude') &&
        location.containsKey('longitude') &&
        location['latitude'] != null &&
        location['longitude'] != null &&
        location['latitude'] is num &&
        location['longitude'] is num &&
        location['latitude'] >= -90 &&
        location['latitude'] <= 90 &&
        location['longitude'] >= -180 &&
        location['longitude'] <= 180;
  }

  // Get user's location preferences
  static Future<Map<String, dynamic>> getLocationPreferences(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? preferences = userDoc.get('preferences');
        Map<String, dynamic> locationPrefs = preferences?['location'] ?? {};

        return {
          'maxDistance': locationPrefs['maxDistance'] ?? 50,
          'showDistance': locationPrefs['showDistance'] ?? true,
          'enableLocation': locationPrefs['enableLocation'] ?? true,
          'autoUpdate': locationPrefs['autoUpdate'] ?? false,
        };
      }
      return {'maxDistance': 50, 'showDistance': true, 'enableLocation': true, 'autoUpdate': false};
    } catch (e) {
      debugPrint('❌ Failed to get location preferences: $e');
      return {'maxDistance': 50, 'showDistance': true, 'enableLocation': true, 'autoUpdate': false};
    }
  }

  // Update location preferences
  static Future<void> updateLocationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences.location': preferences,
        'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Location preferences updated');
    } catch (e) {
      debugPrint('❌ Failed to update location preferences: $e');
    }
  }
}
