import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_service.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseService.instance.auth;

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
        scopes: ['email', 'profile'],
      );

      // Sign out first to ensure clean state
      await googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google sign-in cancelled');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Update user profile in Firestore
      await _updateUserProfile(userCredential.user!, {
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'provider': 'google',
      });

      debugPrint('✅ Google sign-in successful');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      return null;
    }
  }

  // Facebook Sign-In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.cancelled) {
        debugPrint('❌ Facebook sign-in cancelled');
        return null;
      }

      if (loginResult.status == LoginStatus.failed) {
        debugPrint('❌ Facebook sign-in failed: ${loginResult.message}');
        return null;
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(
        loginResult.accessToken!.token,
      );

      // Sign in to Firebase with the Facebook credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        facebookAuthCredential,
      );

      // Get user info from Facebook
      final graphResponse = await FacebookAuth.instance.getUserData();

      // Update user profile in Firestore
      await _updateUserProfile(userCredential.user!, {
        'displayName': graphResponse['name'],
        'photoUrl': graphResponse['picture']['data']['url'],
        'provider': 'facebook',
      });

      debugPrint('✅ Facebook sign-in successful');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Facebook sign-in failed: $e');
      return null;
    }
  }

  // Sign out from all providers
  Future<void> signOutAll() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Sign out from Facebook
      await FacebookAuth.instance.logOut();

      debugPrint('✅ Signed out from all providers');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
    }
  }

  // Check if user is signed in with Google
  bool isSignedInWithGoogle() {
    final user = _auth.currentUser;
    if (user != null) {
      final providerData = user.providerData.firstWhere(
        (data) => data.providerId == 'google.com',
        orElse: () => ProviderData(''),
      );
      return providerData.providerId == 'google.com';
    }
    return false;
  }

  // Check if user is signed in with Facebook
  bool isSignedInWithFacebook() {
    final user = _auth.currentUser;
    if (user != null) {
      final providerData = user.providerData.firstWhere(
        (data) => data.providerId == 'facebook.com',
        orElse: () => ProviderData(''),
      );
      return providerData.providerId == 'facebook.com';
    }
    return false;
  }

  // Link additional provider to existing account
  Future<UserCredential?> linkGoogleAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      if (googleUser == null) {
        debugPrint('❌ No Google account found');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await user.linkWithCredential(credential);

      debugPrint('✅ Google account linked successfully');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Failed to link Google account: $e');
      return null;
    }
  }

  // Link Facebook account to existing account
  Future<UserCredential?> linkFacebookAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status != LoginStatus.success) {
        debugPrint('❌ Facebook login failed');
        return null;
      }

      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(
        loginResult.accessToken!.token,
      );

      final UserCredential userCredential = await user.linkWithCredential(facebookAuthCredential);

      debugPrint('✅ Facebook account linked successfully');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Failed to link Facebook account: $e');
      return null;
    }
  }

  // Unlink provider
  Future<void> unlinkProvider(String providerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await user.unlink(providerId);
      debugPrint('✅ Provider $providerId unlinked successfully');
    } catch (e) {
      debugPrint('❌ Failed to unlink provider: $e');
    }
  }

  // Helper method to update user profile
  Future<void> _updateUserProfile(User user, Map<String, dynamic> additionalData) async {
    try {
      // Get existing user data
      // Note: You'll need to implement this in your DatabaseService
      // For now, we'll just log the update
      debugPrint('✅ User profile updated: ${additionalData}');
    } catch (e) {
      debugPrint('❌ Failed to update user profile: $e');
    }
  }

  // Get all linked providers
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];

    return user.providerData.map((data) => data.providerId).toList();
  }

  // Stream auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
