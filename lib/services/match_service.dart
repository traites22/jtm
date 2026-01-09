import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';

class MatchService {
  /// Returns true if like resulted in a match (reciprocal like).
  static Future<bool> likeUser({
    required String me,
    required Map<String, dynamic> target,
    bool isSuperLike = false,
  }) async {
    final likesBox = Hive.box('likesBox');
    final matchesBox = Hive.box('matchesBox');
    final messagesBox = Hive.box('messagesBox');

    final targetId = target['id'] as String;

    final myLikes = List<String>.from(likesBox.get(me, defaultValue: []) as List);
    if (!myLikes.contains(targetId)) {
      myLikes.add(targetId);
      likesBox.put(me, myLikes);
    }

    final targetLikes = List<String>.from(likesBox.get(targetId, defaultValue: []) as List);
    if (targetLikes.contains(me)) {
      // It's a match — create match entry and an initial message
      matchesBox.put(targetId, {
        'id': targetId,
        'name': target['name'],
        'photo': target['photos']?.isNotEmpty == true ? target['photos'][0] : null,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      final key = 'match:$targetId';
      final list = List<Map>.from(messagesBox.get(key, defaultValue: []) as List);
      list.add({
        'sender': 'them',
        'text': 'Salut! 👋',
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      messagesBox.put(key, list);
      return true;
    }

    return false;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in km

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get compatible profiles for the current user based on filters and preferences
  static List<UserModel> getCompatibleProfiles({
    required UserModel currentUser,
    required List<UserModel> allProfiles,
    FilterModel? filters,
  }) {
    // Remove current user from the list
    final otherProfiles = allProfiles.where((p) => p.id != currentUser.id).toList();

    // Apply filters if provided
    if (filters != null) {
      return FilterService.filterProfiles(otherProfiles, filters, currentUser);
    }

    // Apply basic preference filtering
    return otherProfiles.where((profile) {
      // Basic gender preference filtering
      if (currentUser.lookingFor != null && currentUser.lookingFor != 'tous') {
        if (currentUser.lookingFor != profile.gender) {
          return false;
        }
      }

      // Remove already liked profiles
      final likesBox = Hive.box('likesBox');
      final myLikes = List<String>.from(likesBox.get(currentUser.id, defaultValue: []) as List);
      if (myLikes.contains(profile.id)) {
        return false;
      }

      // Remove already matched profiles
      final matchesBox = Hive.box('matchesBox');
      if (matchesBox.get(profile.id) != null) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Calculate match compatibility score between two users
  static double calculateCompatibilityScore(UserModel user1, UserModel user2) {
    double score = 0.0;

    // Age compatibility (closer ages = higher score)
    final ageDiff = (user1.age - user2.age).abs();
    score += (1.0 - (ageDiff / 50.0)) * 0.2; // Max 0.2 points

    // Interest compatibility (more common interests = higher score)
    if (user1.interests.isNotEmpty && user2.interests.isNotEmpty) {
      final commonInterests = user1.interests
          .where((interest) => user2.interests.contains(interest))
          .length;
      final totalInterests = (user1.interests.length + user2.interests.length) / 2;
      score += (commonInterests / totalInterests) * 0.4; // Max 0.4 points
    }

    // Location compatibility (if both have location)
    if (user1.latitude != null &&
        user1.longitude != null &&
        user2.latitude != null &&
        user2.longitude != null) {
      // Using a public method for distance calculation
      final distance = _calculateDistance(
        user1.latitude!,
        user1.longitude!,
        user2.latitude!,
        user2.longitude!,
      );
      // Closer distance = higher score (up to 100km)
      score += (1.0 - (distance / 100.0).clamp(0.0, 1.0)) * 0.3; // Max 0.3 points
    } else {
      score += 0.15; // Give some points if location is unknown
    }

    // Looking for compatibility
    if (user1.lookingFor != null && user2.lookingFor != null) {
      if (user1.lookingFor == 'tous' ||
          user2.lookingFor == 'tous' ||
          user1.lookingFor == user2.gender ||
          user2.lookingFor == user1.gender) {
        score += 0.1; // Max 0.1 points
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Sort profiles by compatibility score
  static List<UserModel> sortByCompatibility(List<UserModel> profiles, UserModel currentUser) {
    final sortedProfiles = List<UserModel>.from(profiles);
    sortedProfiles.sort((a, b) {
      final scoreA = calculateCompatibilityScore(currentUser, a);
      final scoreB = calculateCompatibilityScore(currentUser, b);
      return scoreB.compareTo(scoreA); // Highest score first
    });
    return sortedProfiles;
  }

  /// Get match statistics for a user
  static Map<String, dynamic> getMatchStats(String userId) {
    final likesBox = Hive.box('likesBox');
    final matchesBox = Hive.box('matchesBox');

    final myLikes = List<String>.from(likesBox.get(userId, defaultValue: []) as List);
    final myMatches = matchesBox.keys.where((key) => matchesBox.get(key) != null).toList();

    return {
      'totalLikes': myLikes.length,
      'totalMatches': myMatches.length,
      'matchRate': myLikes.isNotEmpty ? (myMatches.length / myLikes.length) : 0.0,
    };
  }
}
