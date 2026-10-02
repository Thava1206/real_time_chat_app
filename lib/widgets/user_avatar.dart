import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'base64_image.dart';

/// Circle avatar showing the profile photo, or initials when there isn't one,
/// with an optional green "online" dot.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.photo,
    this.radius = 24,
    this.isOnline = false,
  });

  final String initials;
  final Color color;

  /// Base64-encoded photo, shown in place of [initials] when set.
  final String? photo;
  final double radius;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          backgroundImage: photo == null ? null : base64Image(photo!),
          child: photo == null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: radius * 0.7,
                  ),
                )
              : null,
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
                border: Border.all(
                  color: context.surfaces.background,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
