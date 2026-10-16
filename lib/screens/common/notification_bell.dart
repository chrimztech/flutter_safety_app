import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/context_ext.dart';
import '../../app/session.dart';
import '../notifications/notifications_screen.dart';

/// App-bar bell with the unread count (polled in the background every minute).
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.select<SessionController, int>((s) => s.unreadNotifications);
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () async {
        await context.push(const NotificationsScreen());
        if (context.mounted) await context.session.refreshUnread();
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
