import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search messages',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.inkHigh,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sampleChats.length,
            itemBuilder: (context, index) {
              final chat = sampleChats[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: UserAvatar(
                  initials: chat.initials,
                  color: chat.color,
                  isOnline: chat.isOnline,
                ),
                title: Text(
                  chat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: chat.unread > 0
                            ? AppColors.gold
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (chat.unread > 0)
                      Badge(
                        label: Text('${chat.unread}'),
                        backgroundColor: AppColors.gold,
                        textColor: AppColors.ink,
                      ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
