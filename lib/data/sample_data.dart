import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder data for the UI until chats are loaded from Firestore.
class SampleChat {
  const SampleChat({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.color,
    this.unread = 0,
    this.isOnline = false,
  });

  final String name;
  final String lastMessage;
  final String time;
  final Color color;
  final int unread;
  final bool isOnline;

  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0])
      .take(2)
      .join();
}

const sampleChats = [
  SampleChat(
    name: 'Maya Chen',
    lastMessage: 'Jordan said the build is failing on main',
    time: '9:41 AM',
    color: AppColors.terracotta,
    unread: 2,
    isOnline: true,
  ),
  SampleChat(
    name: 'CS Project Team',
    lastMessage: 'Priya: Meeting moved to 3pm',
    time: '9:20 AM',
    color: AppColors.forest,
    unread: 5,
  ),
  SampleChat(
    name: 'Priya Patel',
    lastMessage: 'You: Let me know if the link doesn\'t work',
    time: 'Yesterday',
    color: AppColors.plum,
    isOnline: true,
  ),
  SampleChat(
    name: 'Alex Rivera',
    lastMessage: 'Pickup basketball on Saturday?',
    time: 'Tue',
    color: Color(0xFF3E6A8A),
  ),
  SampleChat(
    name: 'Sam Okafor',
    lastMessage: 'Congrats on the internship!! 🎉',
    time: '9/17/26',
    color: Color(0xFF8A6A3E),
  ),
];
