import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  static Future<String> getLocationName(double lat, double lon) async {
    try {
      // Géocodage inverse pour obtenir le nom de la localisation
      List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lon,
        localeIdentifier: 'fr_FR',
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        if (place.locality?.isNotEmpty == true) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }
        if (place.country?.isNotEmpty == true) {
          parts.add(place.country!);
        }

        return parts.isNotEmpty ? parts.join(', ') : 'Localisation inconnue';
      }

      return 'Localisation inconnue';
    } catch (e) {
      print('Erreur géocodage: $e');
      return 'Erreur de localisation';
    }
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Vérifier les permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        accuracy: position.accuracy,
      );
    } catch (e) {
      print('Erreur de localisation: $e');
      return null;
    }
  }

  static Future<List<LocationData>> searchLocations(String query) async {
    try {
      // Recherche de localisations par nom
      List<Location> locations = await locationFromAddress(query, localeIdentifier: 'fr_FR');

      return locations
          .map(
            (location) => LocationData(
              latitude: location.latitude,
              longitude: location.longitude,
              timestamp: DateTime.now(),
              accuracy: 0.0,
            ),
          )
          .toList();
    } catch (e) {
      print('Erreur recherche localisation: $e');
      return [];
    }
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
    );
  }
}
