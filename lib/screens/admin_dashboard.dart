import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user.dart' as user_model;
import '../models/ad.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../services/firebase_service.dart';
import '../utils/analytics_helper.dart';
import '../utils/snackbar_helper.dart';
import '../constants/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FirebaseService _firebaseService;
  late AdService _adService;
  final AnalyticsHelper _analytics = AnalyticsHelper();

  bool _isLoading = true;
  bool _isActionLoading = false;

  // Dashboard data
  Map<String, dynamic> _dashboardStats = {};
  List<Ad> _pendingAds = [];
  List<Map<String, dynamic>> _recentUserSignups = [];
  List<Map<String, dynamic>> _articleStats = [];

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _adService = AdService(_firebaseService);
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
    _analytics.logScreenView('admin_dashboard');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).user;

      // Check if user is admin
      if (currentUser == null ||
          currentUser.role != user_model.UserRole.admin) {
        SnackBarHelper.showErrorSnackBar(context,
            message: "You don't have permission to access this page.");
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _loadDashboardStats(),
        _loadPendingAds(),
        _loadRecentUserSignups(),
        _loadArticleStats(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Check if widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showErrorSnackBar(context,
            message: "Error loading dashboard: $e");
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      // User stats
      final userCountSnapshot =
          await _firebaseService.firestore.collection('users').count().get();

      final userCount = userCountSnapshot.count;

      // Get active user count (users who signed in within the last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final startDate = Timestamp.fromDate(thirtyDaysAgo);

      final activeUserCountSnapshot = await _firebaseService.firestore
          .collection('users')
          .where('lastLogin', isGreaterThanOrEqualTo: startDate)
          .count()
          .get();

      final activeUserCount = activeUserCountSnapshot.count;

      // Ad stats
      final adStats = await _adService.getAdStats();

      // Article stats
      final articleCountSnapshot =
          await _firebaseService.firestore.collection('articles').count().get();

      final articleCount = articleCountSnapshot.count;

      // Event stats
      final eventCountSnapshot =
          await _firebaseService.firestore.collection('events').count().get();

      final eventCount = eventCountSnapshot.count;

      // Notification stats
      final notificationCountSnapshot = await _firebaseService.firestore
          .collection('notifications')
          .count()
          .get();

      final notificationCount = notificationCountSnapshot.count;

      // Set dashboard stats
      _dashboardStats = {
        'userCount': userCount,
        'activeUserCount': activeUserCount,
        'articleCount': articleCount,
        'eventCount': eventCount,
        'notificationCount': notificationCount,
        'adStats': adStats,
      };
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      rethrow;
    }
  }

  Future<void> _loadPendingAds() async {
    try {
      _pendingAds = await _adService.getAdsByStatus('pending');
    } catch (e) {
      debugPrint('Error loading pending ads: $e');
      rethrow;
    }
  }

  Future<void> _approveAd(Ad ad) async {
    try {
      setState(() {
        _isActionLoading = true;
      });

      await _adService.updateAd(ad.id, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Check if widget is still mounted
      if (!mounted) return;

      SnackBarHelper.showSuccessSnackBar(context,
          message: "Ad approved successfully!");

      // Reload pending ads
      await _loadPendingAds();
    } catch (e) {
      // Check if widget is still mounted
      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(context,
          message: "Error approving ad: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _rejectAd(Ad ad, String reason) async {
    try {
      setState(() {
        _isActionLoading = true;
      });

      await _adService.updateAd(ad.id, {
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Check if widget is still mounted
      if (!mounted) return;

      SnackBarHelper.showSuccessSnackBar(context,
          message: "Ad rejected successfully!");

      // Reload pending ads
      await _loadPendingAds();
    } catch (e) {
      // Check if widget is still mounted
      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(context,
          message: "Error rejecting ad: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentUserSignups() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _recentUserSignups = snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;

        return {
          'id': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'zipCode': data['zipCode'] ?? '',
          'role': data['role'] ?? 'basic',
          'createdAt': createdAt?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading recent user signups: $e');
      rethrow;
    }
  }

  Future<void> _loadArticleStats() async {
    try {
      // Get most viewed articles
      final snapshot = await _firebaseService.firestore
          .collection('articles')
          .orderBy('viewCount', descending: true)
          .limit(5)
          .get();

      _articleStats = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Unknown',
          'viewCount': data['viewCount'] ?? 0,
          'likeCount': data['likeCount'] ?? 0,
          'shareCount': data['shareCount'] ?? 0,
          'publishedAt': data['publishedAt'] != null
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading article stats: $e');
      rethrow;
    }
  }

  Future<void> _showRejectDialog(Ad ad) async {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Ad'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please provide a reason for rejection:'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Reason',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a reason';
                      }
                      return null;
                    },
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _rejectAd(ad, reasonController.text);
                }
              },
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    final adStats = _dashboardStats['adStats'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildPendingApprovals(),
          const SizedBox(height: 24),
          _buildUserChart(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final userCount = _dashboardStats['userCount'] ?? 0;
    final articleCount = _dashboardStats['articleCount'] ?? 0;
    final eventCount = _dashboardStats['eventCount'] ?? 0;
    final adStats = _dashboardStats['adStats'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: userCount.toString(),
          icon: Icons.people,
          color: AppColors.primary,
        ),
        _buildStatCard(
          title: 'Articles',
          value: articleCount.toString(),
          icon: Icons.article,
          color: AppColors.secondary,
        ),
        _buildStatCard(
          title: 'Events',
          value: eventCount.toString(),
          icon: Icons.event,
          color: Colors.orangeAccent,
        ),
        _buildStatCard(
          title: 'Active Ads',
          value: (adStats['active'] ?? 0).toString(),
          icon: Icons.ads_click,
          color: Colors.greenAccent.shade700,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    if (_pendingAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Approvals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advertisements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingAds.length > 3 ? 3 : _pendingAds.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final ad = _pendingAds[index];
                    return ListTile(
                      title: Text(ad.title),
                      subtitle: Text(
                        'By ${ad.advertiserName} • ${ad.createdAt != null ? DateFormat('MMM d, y').format(ad.createdAt!) : 'Unknown date'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.check_circle,
                              color: Colors.green.withAlpha(204),
                            ),
                            onPressed:
                                _isActionLoading ? null : () => _approveAd(ad),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red.withAlpha(204),
                            ),
                            onPressed: _isActionLoading
                                ? null
                                : () => _showRejectDialog(ad),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (_pendingAds.length > 3) ...[
                  const Divider(),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _tabController.animateTo(2); // Switch to Ads tab
                      },
                      child: const Text('View All Pending Ads'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserChart() {
    final userCount = _dashboardStats['userCount'] ?? 0;
    final activeUserCount = _dashboardStats['activeUserCount'] ?? 0;
    final inactiveUserCount = userCount - activeUserCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: activeUserCount.toDouble(),
                                title: 'Active',
                                color: AppColors.primary,
                                radius: 80,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: inactiveUserCount.toDouble(),
                                title: 'Inactive',
                                color: AppColors.secondary,
                                radius: 80,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            centerSpaceRadius: 0,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Active Users', AppColors.primary),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                              'Inactive Users', AppColors.secondary),
                          const SizedBox(height: 16),
                          Text(
                            'Total Users: $userCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Active (30d): $activeUserCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent User Signups',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _recentUserSignups.isEmpty
                ? const Center(
                    child: Text('No recent signups'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentUserSignups.length > 5
                        ? 5
                        : _recentUserSignups.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = _recentUserSignups[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (user['displayName'] as String?)?.isNotEmpty == true
                                ? (user['displayName'] as String)
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['displayName']),
                        subtitle: Text(
                          '${user['email']} • ${_getRoleLabel(user['role'])}',
                        ),
                        trailing: Text(
                          DateFormat('MMM d, y').format(user['createdAt']),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    // This would be implemented with user management features
    return const Center(
      child: Text('User management coming soon'),
    );
  }

  Widget _buildAdsTab() {
    final adStats = _dashboardStats['adStats'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdStats(adStats),
          const SizedBox(height: 24),
          _buildPendingAdsList(),
        ],
      ),
    );
  }

  Widget _buildAdStats(Map<String, dynamic> adStats) {
    final total = adStats['total'] ?? 0;
    final pending = adStats['pending'] ?? 0;
    final approved = adStats['approved'] ?? 0;
    final rejected = adStats['rejected'] ?? 0;
    final active = adStats['active'] ?? 0;
    final impressions = adStats['impressions'] ?? 0;
    final clicks = adStats['clicks'] ?? 0;
    final ctr = adStats['ctr'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Ads', total.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Pending', pending.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Approved', approved.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Rejected', rejected.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Active Ads', active.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Impressions', impressions.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Clicks', clicks.toString()),
                ),
                Expanded(
                  child: _buildStatItem('CTR', '${ctr.toStringAsFixed(2)}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPendingAdsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Ads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _pendingAds.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No pending ads'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pendingAds.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final ad = _pendingAds[index];
                      return ListTile(
                        title: Text(ad.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'By ${ad.advertiserName} • ${ad.type} • ${ad.placement}',
                            ),
                            if (ad.createdAt != null)
                              Text(
                                'Submitted: ${DateFormat('MMM d, y').format(ad.createdAt!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        leading: ad.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ad.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: Colors.green.withAlpha(204),
                              ),
                              onPressed: _isActionLoading
                                  ? null
                                  : () => _approveAd(ad),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.red.withAlpha(204),
                              ),
                              onPressed: _isActionLoading
                                  ? null
                                  : () => _showRejectDialog(ad),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildArticleStats(),
        ],
      ),
    );
  }

  Widget _buildArticleStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Articles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _articleStats.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No articles found'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _articleStats.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final article = _articleStats[index];
                      return ListTile(
                        title: Text(article['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Views: ${article['viewCount']} • Likes: ${article['likeCount']} • Shares: ${article['shareCount']}',
                            ),
                            if (article['publishedAt'] != null)
                              Text(
                                'Published: ${DateFormat('MMM d, y').format(article['publishedAt'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'advertiser':
        return 'Advertiser';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Ads'),
            Tab(text: 'Content'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildAdsTab(),
                _buildContentTab(),
              ],
            ),
    );
  }
}
