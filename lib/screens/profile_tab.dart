import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class ProfileTab extends StatelessWidget {
  /// [name], [email] and [onLogOut] default to the signed-in Firebase user;
  /// pass them explicitly to render without Firebase (e.g. in tests).
  const ProfileTab({super.key, this.name, this.email, this.onLogOut});

  final String? name;
  final String? email;
  final VoidCallback? onLogOut;

  @override
  Widget build(BuildContext context) {
    final usesFirebase = name == null || email == null || onLogOut == null;
    final authService = usesFirebase ? AuthService() : null;
    final user = authService?.currentUser;
    final displayName =
        name ??
        ((user?.displayName?.isNotEmpty ?? false)
            ? user!.displayName!
            : 'User');
    final userEmail = email ?? user?.email ?? '';
    final logOut = onLogOut ?? authService!.signOut;
    final initials = displayName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: UserAvatar(
            initials: initials,
            color: AppColors.plum,
            radius: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          userEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Edit profile'),
          trailing: Icon(Icons.chevron_right),
        ),
        const ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text('Notifications'),
          trailing: Icon(Icons.chevron_right),
        ),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Privacy'),
          trailing: Icon(Icons.chevron_right),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.terracotta),
          title: const Text(
            'Log out',
            style: TextStyle(color: AppColors.terracotta),
          ),
          onTap: logOut,
        ),
      ],
    );
  }
}
