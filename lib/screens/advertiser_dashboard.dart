import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../models/ad.dart';
import '../theme/brand_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/header.dart';
import '../utils/snackbar_helper.dart';

class AdvertiserDashboard extends StatefulWidget {
  const AdvertiserDashboard({super.key});

  @override
  State<AdvertiserDashboard> createState() => _AdvertiserDashboardState();
}

class _AdvertiserDashboardState extends State<AdvertiserDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Ad> _ads = [];
  List<DocumentSnapshot> _sponsoredArticles = [];
  List<DocumentSnapshot> _communityEvents = [];
  String? _errorMessage;
  bool _isRefreshing = false;

  // Filters
  String _adStatusFilter = 'all'; // all, active, pending, expired

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final adService = Provider.of<AdService>(context, listen: false);
      final user = authService.appUser;

      if (user == null) {
        throw Exception('You must be logged in to view your ads');
      }

      // Load ads
      _ads = await adService.getAdvertiserAds(user.id);

      // Load sponsored articles
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('sponsored_articles')
          .where('userId', isEqualTo: user.id)
          .orderBy('submittedAt', descending: true)
          .get();

      _sponsoredArticles = articlesSnapshot.docs;

      // Load events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('community_events')
          .where('userId', isEqualTo: user.id)
          .orderBy('submittedAt', descending: true)
          .get();

      _communityEvents = eventsSnapshot.docs;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading advertiser data: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadData();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(
            title: 'Advertiser Dashboard',
            showDropdown: false,
          ),

          if (_errorMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red[100],
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: BrandColors.gold,
            unselectedLabelColor: BrandColors.darkGray,
            indicatorColor: BrandColors.gold,
            tabs: const [
              Tab(text: 'Ads'),
              Tab(text: 'Articles'),
              Tab(text: 'Events'),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdsTab(),
                _buildArticlesTab(),
                _buildEventsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAdvertisingOptions(context);
        },
        backgroundColor: BrandColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAdsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(BrandColors.gold),
        ),
      );
    }

    if (_ads.isEmpty) {
      return _buildEmptyState(
        'No Ads Found',
        'You haven\'t created any ads yet. Tap the + button to place your first ad.',
        Icons.ad_units,
      );
    }

    // Filter ads based on selected status
    List<Ad> filteredAds = _ads;
    if (_adStatusFilter != 'all') {
      final now = DateTime.now();

      if (_adStatusFilter == 'active') {
        filteredAds = _ads
            .where((ad) =>
                ad.isActive &&
                ad.startDate.isBefore(now) &&
                ad.endDate.isAfter(now))
            .toList();
      } else if (_adStatusFilter == 'pending') {
        filteredAds = _ads
            .where((ad) => ad.isActive && ad.startDate.isAfter(now))
            .toList();
      } else if (_adStatusFilter == 'expired') {
        filteredAds = _ads
            .where((ad) => !ad.isActive || ad.endDate.isBefore(now))
            .toList();
      }
    }

    return Column(
      children: [
        // Filter Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Filter: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Active', 'active'),
              _buildFilterChip('Pending', 'pending'),
              _buildFilterChip('Expired', 'expired'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                color: BrandColors.gold,
                onPressed: _isRefreshing ? null : _refreshData,
              ),
            ],
          ),
        ),

        // Ads List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAds.length,
            itemBuilder: (context, index) {
              final ad = filteredAds[index];
              return _buildAdCard(ad);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color:
                _adStatusFilter == value ? Colors.white : BrandColors.darkGray,
            fontWeight:
                _adStatusFilter == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: _adStatusFilter == value,
        selectedColor: BrandColors.gold,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _adStatusFilter = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildAdCard(Ad ad) {
    final now = DateTime.now();
    final isActive =
        ad.isActive && ad.startDate.isBefore(now) && ad.endDate.isAfter(now);
    final isPending = ad.isActive && ad.startDate.isAfter(now);
    final isExpired = !ad.isActive || ad.endDate.isBefore(now);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: isActive
                ? Colors.green[700]
                : isPending
                    ? Colors.blue[700]
                    : Colors.grey[700],
            child: Text(
              isActive
                  ? 'ACTIVE'
                  : isPending
                      ? 'PENDING'
                      : 'EXPIRED',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Ad Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ad Type Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ad.adUnitId?.contains('banner') ?? false
                            ? Icons.view_carousel
                            : Icons.article,
                        size: 32,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Ad Title and Unit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getAdUnitName(ad.adUnitId ?? 'unknown'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Duration
                Row(
                  children: [
                    const Icon(
                      Icons.date_range,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(ad.startDate)} - ${dateFormat.format(ad.endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                        'Impressions', ad.impressions.toString()),
                    _buildMetricColumn('Clicks', ad.clicks.toString()),
                    _buildMetricColumn(
                      'CTR',
                      ad.impressions > 0
                          ? '${((ad.clicks / ad.impressions) * 100).toStringAsFixed(2)}%'
                          : '0.00%',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.analytics, size: 16),
                      label: const Text('Detailed Metrics'),
                      onPressed: () => _showAdMetrics(ad),
                      style: TextButton.styleFrom(
                        foregroundColor: BrandColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BrandColors.darkGray,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(BrandColors.gold),
        ),
      );
    }

    if (_sponsoredArticles.isEmpty) {
      return _buildEmptyState(
        'No Sponsored Articles',
        'You haven\'t submitted any sponsored articles yet.',
        Icons.article,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: BrandColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sponsoredArticles.length,
        itemBuilder: (context, index) {
          final article = _sponsoredArticles[index];
          final data = article.data() as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: _getStatusColor(data['status'] ?? 'pending'),
                  child: Text(
                    _getStatusText(data['status'] ?? 'pending'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Untitled Article',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _truncateText(data['content'] ?? '', 100),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted: ${_formatTimestamp(data['submittedAt'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(BrandColors.gold),
        ),
      );
    }

    if (_communityEvents.isEmpty) {
      return _buildEmptyState(
        'No Community Events',
        'You haven\'t submitted any community events yet.',
        Icons.event,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: BrandColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _communityEvents.length,
        itemBuilder: (context, index) {
          final event = _communityEvents[index];
          final data = event.data() as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: _getStatusColor(data['status'] ?? 'pending'),
                  child: Text(
                    _getStatusText(data['status'] ?? 'pending'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Untitled Event',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['location'] ?? 'No location specified',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatEventDate(
                                data['startDateTime'], data['endDateTime']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _truncateText(data['description'] ?? '', 100),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: BrandColors.gold,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvertisingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create New Advertising',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.darkGray,
                ),
              ),
              const SizedBox(height: 24),
              // Submit Sponsored Article
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article,
                    color: Colors.blue[700],
                  ),
                ),
                title: const Text('Submit Sponsored Article'),
                subtitle: const Text('\$75.00 - Featured in the news feed'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/submit-article');
                },
              ),
              // Add Community Event
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.green[700],
                  ),
                ),
                title: const Text('Add Community Event'),
                subtitle: const Text('\$25.00 - Featured in the calendar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add-event');
                },
              ),
              // Contact for Custom Advertising
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.contact_mail,
                    color: Colors.amber[700],
                  ),
                ),
                title: const Text('Contact for Custom Advertising'),
                subtitle: const Text('Banner ads, sponsorships, and more'),
                onTap: () {
                  Navigator.pop(context);
                  SnackBarHelper.showInfoSnackBar(
                    context,
                    message:
                        'Please email info@neusenews.com for custom advertising inquiries',
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAdMetrics(Ad ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: Provider.of<AdService>(context, listen: false)
                  .getAdMetrics(ad.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Error loading metrics: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final metrics = snapshot.data!;
                final dateFormat = DateFormat('MMM d, yyyy');

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Ad Performance Metrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.darkGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ad.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: BrandColors.gold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${dateFormat.format(ad.startDate)} - ${dateFormat.format(ad.endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Metrics Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMetricCard(
                          'Impressions',
                          metrics['impressions']?.toString() ?? '0',
                          Icons.visibility,
                          Colors.blue,
                        ),
                        _buildMetricCard(
                          'Clicks',
                          metrics['clicks']?.toString() ?? '0',
                          Icons.touch_app,
                          Colors.green,
                        ),
                        _buildMetricCard(
                          'CTR',
                          '${(metrics['ctr'] ?? 0.0).toStringAsFixed(2)}%',
                          Icons.analytics,
                          Colors.purple,
                        ),
                        _buildMetricCard(
                          'Ad Type',
                          _getAdUnitName(ad.adUnitId ?? 'unknown'),
                          Icons.category,
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Actions
                    Center(
                      child: CustomButton(
                        text: 'Close',
                        onPressed: () => Navigator.pop(context),
                        variant: CustomButtonVariant.secondary,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BrandColors.darkGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAdUnitName(String adUnitId) {
    if (adUnitId.contains('splash')) {
      return 'Splash Screen Banner';
    } else if (adUnitId.contains('home')) {
      return 'Home Page Banner';
    } else if (adUnitId.contains('feed')) {
      return 'In-Feed Native Ad';
    } else if (adUnitId.contains('classifieds')) {
      return 'Classifieds Ad';
    } else if (adUnitId.contains('calendar')) {
      return 'Calendar Banner';
    } else if (adUnitId.contains('weather')) {
      return 'Weather Banner';
    }
    return 'Custom Ad';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green[700]!;
      case 'pending':
        return Colors.blue[700]!;
      case 'rejected':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getStatusText(String status) {
    return status.toUpperCase();
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('MMM d, yyyy').format(dateTime);
    }

    return 'Unknown';
  }

  String _formatEventDate(dynamic startDateTime, dynamic endDateTime) {
    if (startDateTime == null) return 'Date not specified';

    if (startDateTime is Timestamp) {
      final start = startDateTime.toDate();
      final dateStr = DateFormat('MMM d, yyyy').format(start);

      if (endDateTime is Timestamp) {
        final startTime = DateFormat('h:mm a').format(start);
        final endTime = DateFormat('h:mm a').format(endDateTime.toDate());
        return '$dateStr, $startTime - $endTime';
      }

      return dateStr;
    }

    return 'Date not specified';
  }
}
