import 'package:intl/intl.dart';

/// Utility class for formatting dates
class DateFormatter {
  /// Format a date to a readable string (e.g., "Jan 1, 2025")
  static String formatDate(DateTime date, {String format = 'MMM d, y'}) {
    try {
      return DateFormat(format).format(date);
    } catch (e) {
      return '';
    }
  }

  /// Format a date to a relative string (e.g., "2 hours ago", "Yesterday", "3 days ago")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  /// Parse a date string to DateTime
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }

    try {
      // Try standard RFC822/RFC1123 format used in RSS
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try common US format
        final formats = [
          'EEE, dd MMM yyyy HH:mm:ss zzz', // RFC822
          'dd MMM yyyy HH:mm:ss zzz',
          'yyyy-MM-ddTHH:mm:ssZ', // ISO 8601
          'yyyy-MM-dd HH:mm:ss',
          'MM/dd/yyyy HH:mm:ss',
        ];

        for (final format in formats) {
          try {
            return DateFormat(format).parse(dateStr);
          } catch (_) {
            // Try next format
          }
        }
      } catch (_) {
        // All parsing attempts failed
      }
    }
    return null;
  }

  /// Format a DateTime to a relative timestamp (e.g., "just now", "5m ago", etc.)
  static String getTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  /// Format a DateTime to a full date and time string
  static String getFullDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  /// Format a DateTime to just the date
  static String getDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Format a DateTime to just the time
  static String getTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Parse RSS date formats like "Sat, 22 Mar 2025 16:50:54 +0000"
  static DateTime parseRssDate(String dateStr) {
    if (dateStr.isEmpty) {
      return DateTime.now();
    }

    try {
      // Try with intl package formatter
      final DateFormat format =
          DateFormat("EEE, dd MMM yyyy HH:mm:ss Z", 'en_US');
      return format.parse(dateStr);
    } catch (e) {
      try {
        // Fallback parsing method
        final parts = dateStr.split(', ');
        if (parts.length < 2) throw FormatException('Invalid RSS date');

        final dateParts = parts[1].split(' ');
        final day = dateParts[0];
        final month = _getMonthNumber(dateParts[1]);
        final year = dateParts[2];
        final time = dateParts[3];

        // Format as ISO 8601 which DateTime.parse handles well
        final isoFormat = '$year-$month-${day.padLeft(2, '0')}T$time+0000';
        return DateTime.parse(isoFormat);
      } catch (e) {
        print('Date parsing failed for: $dateStr');
        return DateTime.now(); // Fallback
      }
    }
  }

  /// Convert month abbreviation to number
  static String _getMonthNumber(String monthAbbr) {
    final months = {
      'jan': '01',
      'feb': '02',
      'mar': '03',
      'apr': '04',
      'may': '05',
      'jun': '06',
      'jul': '07',
      'aug': '08',
      'sep': '09',
      'oct': '10',
      'nov': '11',
      'dec': '12'
    };
    return months[monthAbbr.toLowerCase()] ?? '01';
  }

  /// Format a date for display in the UI
  static String formatForDisplay(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(date); // Today: 3:30 PM
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date); // Weekday: 'Mon'
    } else {
      return DateFormat.yMMMd().format(date); // Mar 22, 2025
    }
  }
}
