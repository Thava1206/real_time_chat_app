import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/user_service.dart';
import '../theme/appearance_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/user_avatar.dart';

class ProfileTab extends StatelessWidget {
  /// [name], [email] and [onLogOut] default to the signed-in user's Firestore
  /// profile; pass them explicitly to render without Firebase (e.g. in tests).
  const ProfileTab({
    super.key,
    this.name,
    this.email,
    this.bio = '',
    this.photo,
    this.onLogOut,
    this.onSaveProfile,
    this.onChangePhoto,
  });

  final String? name;
  final String? email;
  final String bio;
  final String? photo;
  final VoidCallback? onLogOut;
  final Future<void> Function(String name, String bio)? onSaveProfile;

  /// Saves a new base64 photo, or removes it when passed null.
  final Future<void> Function(String? photo)? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    if (name != null && email != null && onLogOut != null) {
      return _ProfileView(
        user: AppUser(
          uid: '',
          name: name!,
          email: email!,
          bio: bio,
          photo: photo,
          avatarColor: AppColors.plum,
        ),
        onLogOut: onLogOut!,
        onSaveProfile: onSaveProfile,
        onChangePhoto: onChangePhoto,
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
          onChangePhoto: snapshot.hasData ? authService.updatePhoto : null,
        );
      },
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView({
    required this.user,
    required this.onLogOut,
    this.onSaveProfile,
    this.onChangePhoto,
  });

  final AppUser user;
  final VoidCallback onLogOut;
  final Future<void> Function(String name, String bio)? onSaveProfile;
  final Future<void> Function(String? photo)? onChangePhoto;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _imageService = ImageService();
  bool _isSavingPhoto = false;

  AppUser get user => widget.user;

  Future<void> _changePhoto() async {
    final action = await showPhotoSourceSheet(
      context,
      canRemove: user.photo != null,
    );
    if (action == null || !mounted) return;

    setState(() => _isSavingPhoto = true);
    try {
      final source = action.source;
      if (source == null) {
        await widget.onChangePhoto!(null);
      } else {
        final photo = await _imageService.pickProfilePhoto(source);
        if (photo != null) await widget.onChangePhoto!(photo);
      }
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        AuthException(:final message) => message,
        FormatException() => 'That file is not a supported image.',
        _ => 'Could not update your photo.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSavingPhoto = false);
    }
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LiquidGlassSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: context.surfaces.isGlass
            ? const Color(0xE6333C57)
            : context.surfaces.surface,
        child: _EditProfileSheet(user: user, onSave: widget.onSaveProfile!),
      ),
    );
  }

  void _openAppearanceDialog(
    BuildContext context,
    AppearanceController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: LiquidGlassSurface(
          color: context.surfaces.isGlass
              ? const Color(0xE6333C57)
              : context.surfaces.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Appearance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              ...AppAppearance.values.map((appearance) {
                final selected = controller.appearance == appearance;
                return ListTile(
                  leading: Icon(appearance.icon),
                  title: Text(appearance.label),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        )
                      : null,
                  onTap: () async {
                    await controller.setAppearance(appearance);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearanceController = AppearanceScope.maybeOf(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(child: _buildAvatar(context)),
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
          style: TextStyle(color: context.surfaces.mutedText),
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
          enabled: widget.onSaveProfile != null,
          onTap: () => _openEditSheet(context),
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Appearance'),
          subtitle: Text(
            appearanceController?.appearance.label ?? 'Dark',
            style: TextStyle(color: context.surfaces.mutedText),
          ),
          trailing: const Icon(Icons.chevron_right),
          enabled: appearanceController != null,
          onTap: appearanceController == null
              ? null
              : () => _openAppearanceDialog(context, appearanceController),
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
          leading: const Icon(
            Icons.logout,
            color: AppColors.terracotta,
            shadows: [],
          ),
          title: const Text(
            'Log out',
            style: TextStyle(color: AppColors.terracotta),
          ),
          onTap: widget.onLogOut,
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatar = UserAvatar(
      initials: user.initials,
      color: user.avatarColor,
      photo: user.photo,
      radius: 48,
    );
    if (widget.onChangePhoto == null) return avatar;

    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Change profile photo',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _isSavingPhoto ? null : _changePhoto,
        child: Stack(
          alignment: Alignment.center,
          children: [
            avatar,
            if (_isSavingPhoto)
              const SizedBox.square(
                dimension: 96,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.surfaces.background,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: 16,
                  color: colors.onPrimary,
                  shadows: const [],
                ),
              ),
            ),
          ],
        ),
      ),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isSaving) _save();
              },
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
