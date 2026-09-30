import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'chats_tab.dart';
import 'contacts_tab.dart';
import 'profile_tab.dart';

/// Main screen shown after login, with a bottom bar to switch between tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.currentUserId, this.userService});

  final String? currentUserId;
  final UserService? userService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _titles = ['Messages', 'Contacts', 'Profile'];

  Widget _buildTab() {
    switch (_currentIndex) {
      case 1:
        return ContactsTab(
          currentUid: widget.currentUserId,
          userService: widget.userService,
        );
      case 2:
        return const ProfileTab();
      default:
        return const ChatsTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.ink,
      ),
      body: _buildTab(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              tooltip: 'New chat',
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.ink,
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.inkRaised,
        indicatorColor: AppColors.gold.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.gold),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.gold),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.gold),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
