import 'package:flutter/material.dart';
import '../services/firebase_connection_test.dart';
import '../screens/firebase_login_screen.dart';
import '../screens/local_login_screen.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  bool _authWorking = false;
  String _status = 'Test de connexion Firebase...';
  String? _testUserId;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Test de connexion Firebase...';
    });

    try {
      // Test de connexion générale
      final connected = await FirebaseConnectionTest.testConnection();
      setState(() {
        _isConnected = connected;
        _status = connected ? '✅ Firebase connecté' : '❌ Firebase non connecté';
      });

      if (connected) {
        // Test de l'authentification
        final authWorking = await FirebaseConnectionTest.testAuth();
        setState(() {
          _authWorking = authWorking;
          _status = authWorking ? '✅ Authentification OK' : '❌ Authentification KO';
        });

        if (authWorking) {
          // Test de création d'utilisateur
          try {
            final userId = await FirebaseConnectionTest.registerTestUser();
            setState(() {
              _testUserId = userId;
              _status = '✅ Test complet réussi ! Firebase est prêt';
            });
          } catch (e) {
            setState(() {
              _status = '⚠️ Connexion OK mais erreur création utilisateur: $e';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e';
        _isConnected = false;
        _authWorking = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanup() async {
    if (_testUserId != null) {
      await FirebaseConnectionTest.cleanupTestUser(_testUserId!);
      setState(() {
        _testUserId = null;
      });
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 40),

            // Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isConnected ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isLoading
                        ? Icons.hourglass_empty
                        : _isConnected
                        ? Icons.check_circle
                        : Icons.error,
                    size: 48,
                    color: _isLoading
                        ? Colors.orange
                        : _isConnected
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Indicateurs
            Row(
              children: [
                Expanded(child: _buildIndicator('Firebase', _isConnected)),
                const SizedBox(width: 16),
                Expanded(child: _buildIndicator('Auth', _authWorking)),
              ],
            ),
            const SizedBox(height: 40),

            // Boutons d'action
            if (_isConnected && _authWorking) ...[
              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const FirebaseLoginScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Utiliser Firebase'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LocalLoginScreen()),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Utiliser version locale'),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: _testFirebaseConnection,
                child: Text(
                  'Retester la connexion',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.check : Icons.close,
            color: isActive ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
