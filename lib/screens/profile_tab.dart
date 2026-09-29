import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class ProfileTab extends StatelessWidget {
  /// [name], [email] and [onLogOut] default to the signed-in user's Firestore
  /// profile; pass them explicitly to render without Firebase (e.g. in tests).
  const ProfileTab({
    super.key,
    this.name,
    this.email,
    this.bio = '',
    this.onLogOut,
    this.onSaveProfile,
  });

  final String? name;
  final String? email;
  final String bio;
  final VoidCallback? onLogOut;
  final Future<void> Function(String name, String bio)? onSaveProfile;

  @override
  Widget build(BuildContext context) {
    if (name != null && email != null && onLogOut != null) {
      return _ProfileView(
        user: AppUser(
          uid: '',
          name: name!,
          email: email!,
          bio: bio,
          avatarColor: AppColors.plum,
        ),
        onLogOut: onLogOut!,
        onSaveProfile: onSaveProfile,
      );
    }

    final authService = AuthService();
    final authUser = authService.currentUser!;
    return StreamBuilder<AppUser?>(
      stream: UserService().watchUser(authUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Fall back to the auth account if the profile is missing or failed
        // to load, so the tab (and log out) still works.
        final user =
            snapshot.data ??
            AppUser(
              uid: authUser.uid,
              name: (authUser.displayName?.isNotEmpty ?? false)
                  ? authUser.displayName!
                  : 'User',
              email: authUser.email ?? '',
              avatarColor: AppUser.avatarColorFor(authUser.uid),
            );
        return _ProfileView(
          user: user,
          onLogOut: authService.signOut,
          onSaveProfile: snapshot.hasData
              ? (name, bio) => authService.updateProfile(name: name, bio: bio)
              : null,
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.user,
    required this.onLogOut,
    this.onSaveProfile,
  });

  final AppUser user;
  final VoidCallback onLogOut;
  final Future<void> Function(String name, String bio)? onSaveProfile;

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(user: user, onSave: onSaveProfile!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: UserAvatar(
            initials: user.initials,
            color: user.avatarColor,
            radius: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(user.bio, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit profile'),
          trailing: const Icon(Icons.chevron_right),
          enabled: onSaveProfile != null,
          onTap: () => _openEditSheet(context),
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
          onTap: onLogOut,
        ),
      ],
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSave});

  final AppUser user;
  final Future<void> Function(String name, String bio) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _bioController = TextEditingController(text: widget.user.bio);

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(_nameController.text, _bioController.text);
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.terracotta),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your name.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLength: 140,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
