import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circle avatar showing initials, with an optional green "online" dot.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.radius = 24,
    this.isOnline = false,
  });

  final String initials;
  final Color color;
  final double radius;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: radius * 0.7,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
