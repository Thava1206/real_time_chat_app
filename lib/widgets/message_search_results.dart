import 'package:flutter/material.dart';

import '../models/message_search_result.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

class MessageSearchResults extends StatelessWidget {
  const MessageSearchResults({
    super.key,
    required this.results,
    required this.currentUid,
    required this.onSelected,
  });

  final Future<List<MessageSearchResult>> results;
  final String currentUid;
  final ValueChanged<MessageSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MessageSearchResult>>(
      future: results,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not search messages.'));
        }
        final matches = snapshot.data ?? const [];
        if (matches.isEmpty) {
          return const Center(child: Text('No matching messages.'));
        }
        return ListView.separated(
          itemCount: matches.length,
          separatorBuilder: (_, _) => const Divider(indent: 72),
          itemBuilder: (context, index) {
            final result = matches[index];
            final sent = result.message.senderId == currentUid;
            final title = result.isGroup
                ? result.groupName ?? 'Group chat'
                : result.otherUser.name;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: result.isGroup
                  ? CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        Icons.groups_2_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : UserAvatar(
                      initials: result.otherUser.initials,
                      color: result.otherUser.avatarColor,
                      photo: result.otherUser.photo,
                    ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    sent ? 'Sent' : 'Received',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                result.message.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.surfaces.mutedText),
              ),
              onTap: () => onSelected(result),
            );
          },
        );
      },
    );
  }
}
