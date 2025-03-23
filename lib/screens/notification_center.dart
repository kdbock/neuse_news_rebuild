import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../models/notification.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../utils/analytics_helper.dart';
import '../utils/date_formatter.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_button.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  late Future<List<AppNotification>> _notificationsFuture;
  final NotificationService _notificationService = NotificationService();
  final AnalyticsHelper _analytics = AnalyticsHelper();
  bool _isLoading = false;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _analytics.logScreenView('notification_center');
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    if (userId != null) {
      _notificationsFuture =
          _notificationService.getNotificationsForUser(userId);
    } else {
      _notificationsFuture = Future.value([]);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.markNotificationAsRead(notification.id);
      _analytics.logEvent('notification_marked_read', parameters: {
        'notification_id': notification.id,
        'notification_type': notification.type,
      });
      await _refreshNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    if (userId == null) return;

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await _notificationService.markAllNotificationsAsRead(userId);
      _analytics.logEvent('all_notifications_marked_read');
      await _refreshNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking all notifications as read: $e')),
      );
    } finally {
      setState(() {
        _isMarkingAllRead = false;
      });
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.deleteNotification(notification.id);
      _analytics.logEvent('notification_deleted', parameters: {
        'notification_id': notification.id,
        'notification_type': notification.type,
      });
      await _refreshNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, List<AppNotification>> _groupNotificationsByDate(
      List<AppNotification> notifications) {
    final groupedNotifications = <String, List<AppNotification>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in notifications) {
      final createdAt = notification.createdAt;
      final createdAtDate =
          DateTime(createdAt.year, createdAt.month, createdAt.day);

      String groupKey;
      if (createdAtDate == today) {
        groupKey = 'Today';
      } else if (createdAtDate == yesterday) {
        groupKey = 'Yesterday';
      } else {
        groupKey = DateFormat('MMMM d, y').format(createdAt);
      }

      if (!groupedNotifications.containsKey(groupKey)) {
        groupedNotifications[groupKey] = [];
      }

      groupedNotifications[groupKey]!.add(notification);
    }

    return groupedNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (!_isMarkingAllRead)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark All Read'),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: FutureBuilder<List<AppNotification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _isLoading) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final notifications = snapshot.data!;
            final groupedNotifications =
                _groupNotificationsByDate(notifications);

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, index) {
                final date = groupedNotifications.keys.elementAt(index);
                final notificationsForDate = groupedNotifications[date]!;

                return _buildNotificationGroup(date, notificationsForDate);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(
      String date, List<AppNotification> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            date,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
          ),
        ),
        ...notifications
            .map((notification) => _buildNotificationItem(notification)),
      ],
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? null
                : AppColors.lightGrey.withOpacity(0.3),
            border:
                Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getNotificationTitle(notification),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                        ),
                        Text(
                          DateFormatter.getTimestamp(notification.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: CustomButton(
                          text: notification.actionLabel!,
                          onPressed: () {
                            _markAsRead(notification);
                            Navigator.of(context)
                                .pushNamed(notification.actionRoute!);
                          },
                          isSmall: true,
                          isOutlined: true,
                        ),
                      ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'article':
        iconData = Icons.article;
        iconColor = Colors.blue;
        break;
      case 'event':
        iconData = Icons.event;
        iconColor = Colors.green;
        break;
      case 'weather':
        iconData = Icons.cloud;
        iconColor = Colors.orange;
        break;
      case 'account':
        iconData = Icons.person;
        iconColor = Colors.purple;
        break;
      case 'system':
        iconData = Icons.notifications;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.primary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getNotificationTitle(AppNotification notification) {
    switch (notification.type) {
      case 'article':
        return notification.title ?? 'New Article';
      case 'event':
        return notification.title ?? 'Community Event';
      case 'weather':
        return notification.title ?? 'Weather Alert';
      case 'account':
        return notification.title ?? 'Account Update';
      case 'system':
        return notification.title ?? 'System Notification';
      default:
        return notification.title ?? 'Notification';
    }
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/notification_empty.svg',
            width: 120,
            height: 120,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Refresh',
            onPressed: _refreshNotifications,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          if (error.isNotEmpty && !error.contains('network'))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Try Again',
            onPressed: _refreshNotifications,
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}
