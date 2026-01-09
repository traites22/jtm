import 'package:flutter/material.dart';
import 'firebase_swipe_screen.dart';
import 'matches_screen.dart';
import 'annonce_screen.dart';
import 'message_screen.dart';
import 'settings_screen_functional.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _pages = [
    const FirebaseSwipeScreen(),
    const MatchesScreen(),
    const AnnonceScreen(),
    const MessageScreen(),
    const SettingsScreenFunctional(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JTM - ${['Découvrir', 'Match', 'Annonce', 'Messages', 'Paramètres'][_index]}'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Découvrir'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Annonce'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
