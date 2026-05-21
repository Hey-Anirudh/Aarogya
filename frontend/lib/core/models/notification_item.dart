class NotificationItem {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${createdAt.day}/${createdAt.month}/${createdAt.year}";
  }
}
