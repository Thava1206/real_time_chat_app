import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'chats_tab.dart';
import 'contacts_tab.dart';
import 'profile_tab.dart';

/// Main screen shown after login, with a bottom bar to switch between tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.currentUserId,
    this.userService,
    this.chatService,
  });

  final String? currentUserId;
  final UserService? userService;
  final ChatService? chatService;

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
          chatService: widget.chatService,
        );
      case 2:
        return const ProfileTab();
      default:
        return ChatsTab(
          currentUid: widget.currentUserId,
          chatService: widget.chatService,
          userService: widget.userService,
        );
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
      ),
      body: _buildTab(),
      floatingActionButton: _currentIndex == 0
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: context.surfaces.isGlass
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.34),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: FloatingActionButton(
                tooltip: 'New chat',
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Icon(Icons.edit_outlined),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(
              Icons.chat_bubble,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
