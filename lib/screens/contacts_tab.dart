import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sampleChats.length,
      itemBuilder: (context, index) {
        final contact = sampleChats[index];
        return ListTile(
          leading: UserAvatar(
            initials: contact.initials,
            color: contact.color,
            isOnline: contact.isOnline,
          ),
          title: Text(contact.name),
          subtitle: Text(
            contact.isOnline ? 'Online' : 'Offline',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          trailing: IconButton(
            tooltip: 'Message',
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.gold),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(chat: contact)),
            ),
          ),
        );
      },
    );
  }
}
