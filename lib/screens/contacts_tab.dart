import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../navigation/app_page_route.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({
    super.key,
    this.currentUid,
    this.userService,
    this.chatService,
  });

  final String? currentUid;
  final UserService? userService;
  final ChatService? chatService;

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  late final UserService _userService = widget.userService ?? UserService();

  Future<void> _openAddContactDialog() => showDialog<void>(
    context: context,
    builder: (_) => _AddContactDialog(
      currentUid: widget.currentUid!,
      userService: _userService,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final uid = widget.currentUid;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.icon(
              onPressed: uid == null ? null : _openAddContactDialog,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Contact'),
            ),
          ),
        ),
        Expanded(
          child: uid == null
              ? const Center(child: Text('Sign in to view your contacts.'))
              : StreamBuilder<List<AppUser>>(
                  stream: _userService.watchContacts(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load contacts.'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final contacts = snapshot.data ?? [];
                    if (contacts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No contacts yet. Add someone to get started.',
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, _) => const Divider(indent: 72),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          leading: UserAvatar(
                            initials: contact.initials,
                            color: contact.avatarColor,
                            photo: contact.photo,
                          ),
                          title: Text(contact.name),
                          subtitle: Text(
                            contact.bio.isNotEmpty
                                ? contact.bio
                                : contact.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.surfaces.mutedText),
                          ),
                          trailing: IconButton(
                            tooltip: 'Message',
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => pushAppPage<void>(
                              context,
                              (_) => ChatScreen(
                                currentUid: uid,
                                otherUser: contact,
                                chatService: widget.chatService,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog({
    required this.currentUid,
    required this.userService,
  });

  final String currentUid;
  final UserService userService;

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _queryController = TextEditingController();
  final _addedIds = <String>{};
  List<AppUser> _results = [];
  String? _errorMessage;
  String? _addingUid;
  bool _hasSearched = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });
    try {
      final results = await widget.userService.searchUsers(
        _queryController.text,
        excludingUid: widget.currentUid,
      );
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not search users.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _add(AppUser user) async {
    setState(() {
      _addingUid = user.uid;
      _errorMessage = null;
    });
    try {
      await widget.userService.addContact(widget.currentUid, user.uid);
      if (mounted) setState(() => _addedIds.add(user.uid));
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.code == 'permission-denied'
              ? 'Firestore denied this write. Deploy the latest firestore.rules.'
              : 'Could not add contact (${error.code}).';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Could not add contact.');
    } finally {
      if (mounted) setState(() => _addingUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LiquidGlassSurface(
        color: context.surfaces.isGlass
            ? const Color(0xE6333C57)
            : context.surfaces.surface,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          title: const Text('Add contact'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          labelText: 'Search by email',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search users',
                      onPressed:
                          _isSearching || _queryController.text.trim().isEmpty
                          ? null
                          : _search,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                if (_isSearching) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_hasSearched &&
                    !_isSearching &&
                    _results.isEmpty &&
                    _errorMessage == null) ...[
                  const SizedBox(height: 16),
                  const Text('No users found.'),
                ],
                if (_results.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        final isAdded = _addedIds.contains(user.uid);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(
                            initials: user.initials,
                            color: user.avatarColor,
                            photo: user.photo,
                            radius: 18,
                          ),
                          title: Text(user.name),
                          trailing: isAdded
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.online,
                                  shadows: [],
                                )
                              : _addingUid == user.uid
                              ? const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Add ${user.name}',
                                  onPressed: _addingUid == null
                                      ? () => _add(user)
                                      : null,
                                  icon: const Icon(Icons.person_add_alt_1),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
