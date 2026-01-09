import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'invite_friends_screen.dart';
import 'account_settings_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_screen.dart';
import '../services/profile_service.dart';

class ProfileMainScreen extends StatefulWidget {
  const ProfileMainScreen({super.key});

  @override
  State<ProfileMainScreen> createState() => _ProfileMainScreenState();
}

class _ProfileMainScreenState extends State<ProfileMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const ProfileScreen(), const ProfileEditScreen()];

  final List<String> _titles = ['Mon Profil', 'Éditer le Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_currentIndex == 0 ? Icons.edit : Icons.person),
            onPressed: () {
              setState(() {
                _currentIndex = (_currentIndex + 1) % _pages.length;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const InviteFriendsScreen()));
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _titles.asMap().entries.map((entry) {
          return BottomNavigationBarItem(icon: _getIconForIndex(entry.key), label: entry.value);
        }).toList(),
      ),
    );
  }

  Widget _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icon(Icons.person);
      case 1:
        return Icon(Icons.edit);
      default:
        return Icon(Icons.person);
    }
  }
}
