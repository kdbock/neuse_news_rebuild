import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

/// Service for handling push notifications using Firebase Messaging
class NotificationService {
  // Add this global key to use for showing in-app notifications
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize the notification service
  Future<void> initialize() async {
    debugPrint('Simplified notification service initialized');
    // No local notifications initialization needed
  }

  /// Show an in-app notification when the app is in the foreground
  void showInAppNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'View',
        onPressed: () {
          // Handle tap on notification
          if (payload != null) {
            try {
              final data = json.decode(payload) as Map<String, dynamic>;
              // Handle navigation based on payload data
              debugPrint('Notification payload: $data');
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
            }
          }
        },
      ),
    );

    // Show the snackbar
    messengerKey.currentState?.showSnackBar(snackBar);
  }

  /// Show a notification (simplified)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Showing notification: $title - $body');

    // Show in-app notification if the app is in the foreground
    showInAppNotification(title: title, body: body, payload: payload);
  }

  /// Handle foreground FCM message
  void handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'Neuse News',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  /// Handle notification message opened from terminated state
  Future<void> handleInitialMessage(RemoteMessage message) async {
    debugPrint('Initial message: ${message.data}');
    // Navigation would go here
  }

  /// Handle app opened from a notification when in background
  void handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    // Navigation would go here
  }

  /// Clear all notifications (simplified)
  Future<void> clearAllNotifications() async {
    debugPrint('Would clear all notifications');
    // Nothing to do in the simplified version
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // For iOS, we'd use Firebase Messaging permission request
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get all notifications for a specific user
  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark a specific notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a specific user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a specific notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Create a new notification for a user
  Future<void> createNotification({
    required String userId,
    required String type,
    required String body,
    String? title,
    String? actionLabel,
    String? actionRoute,
  }) async {
    try {
      final notification = AppNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        body: body,
        title: title,
        actionLabel: actionLabel,
        actionRoute: actionRoute,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      debugPrint('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }
}
