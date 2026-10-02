import 'app_user.dart';

/// Someone the user might want to chat with, and why they were suggested.
class UserRecommendation {
  const UserRecommendation({
    required this.user,
    required this.score,
    required this.reasons,
  });

  final AppUser user;

  /// Higher scores are stronger matches; used only for ordering.
  final int score;

  /// Human-readable reasons, strongest first. Never empty.
  final List<String> reasons;
}
