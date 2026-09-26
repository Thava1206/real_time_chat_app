import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Placeholder landing screen shown after a successful login/signup.
/// Replace with the real chat screens as they are built.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;
    final displayName = user?.displayName;
    final greeting = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (user?.email ?? 'there');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, $greeting!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
