import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';
import '../widgets/header.dart'; // Import Header widget
import 'package:intl/intl.dart';

class CommunityCalendar extends StatefulWidget {
  const CommunityCalendar({super.key});

  @override
  State<CommunityCalendar> createState() => _CommunityCalendarState();
}

class _CommunityCalendarState extends State<CommunityCalendar> {
  DateTime _selectedDate = DateTime.now();
  final bool _isLoading = false;
  final List<Event> _events = [
    Event(
      id: '1',
      title: 'Community Cleanup',
      description: 'Join us for a community cleanup event at North Street Park',
      location: 'North Street Park',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 13)),
    ),
    Event(
      id: '2',
      title: 'Farmers Market',
      description: 'Weekly farmers market with local produce and crafts',
      location: 'Downtown Square',
      startTime: DateTime.now().add(const Duration(days: 3, hours: 8)),
      endTime: DateTime.now().add(const Duration(days: 3, hours: 12)),
    ),
    Event(
      id: '3',
      title: 'City Council Meeting',
      description: 'Monthly city council meeting open to the public',
      location: 'City Hall, Room 201',
      startTime: DateTime.now().add(const Duration(days: 5, hours: 18)),
      endTime: DateTime.now().add(const Duration(days: 5, hours: 20)),
    ),
  ];

  List<Event> get _eventsForSelectedDate {
    return _events.where((event) {
      return event.startTime.year == _selectedDate.year &&
          event.startTime.month == _selectedDate.month &&
          event.startTime.day == _selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Use the Header widget at the top
          const Header(
            title: 'Community Calendar',
            showDropdown:
                false, // Don't show category dropdown on calendar screen
          ),

          // Calendar content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: BrandColors.gold))
                : Column(
                    children: [
                      _buildCalendarHeader(),
                      _buildCalendarGrid(),
                      _buildEventsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: BrandColors.gold.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                  _selectedDate.day,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                  _selectedDate.day,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Calculate first day of the month
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    // Calculate the weekday of the first day (0 = Monday, 6 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday % 7;
    // Calculate the number of days in the month
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    // Create a list of day cells
    final dayCells = List<Widget>.generate(
      firstWeekday + daysInMonth,
      (index) {
        if (index < firstWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - firstWeekday + 1;
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        // Check if there are events on this day
        final hasEvents = _events.any((event) =>
            event.startTime.year == date.year &&
            event.startTime.month == date.month &&
            event.startTime.day == date.day);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? BrandColors.gold
                  : isToday
                      ? BrandColors.gold.withOpacity(0.3)
                      : Colors.transparent,
              border: Border.all(
                color: isToday ? BrandColors.gold : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected || isToday ? FontWeight.bold : null,
                  ),
                ),
                if (hasEvents)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : BrandColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    // Create a grid of days
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Days of week header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Sun'),
              Text('Mon'),
              Text('Tue'),
              Text('Wed'),
              Text('Thu'),
              Text('Fri'),
              Text('Sat'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: GridView.count(
              crossAxisCount: 7,
              children: dayCells,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = _eventsForSelectedDate;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Events for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, color: BrandColors.gold),
                  label: const Text('Add Event',
                      style: TextStyle(color: BrandColors.gold)),
                  onPressed: () {
                    // Add event functionality
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            events.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        'No events for this date',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(event.description),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Text(event.location),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('h:mm a').format(event.startTime)} - '
                                      '${DateFormat('h:mm a').format(event.endTime)}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              // Show event details
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
  });
}
