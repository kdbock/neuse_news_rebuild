/// Helper class for form input validation
class Validators {
  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Regular expression for email validation
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password with common strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates a simple password (less strict for existing users)
  static String? validateSimplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validates that two password fields match
  static String? validatePasswordMatch(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates a name field
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  /// Validates a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validates a ZIP code
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'ZIP code is required';
    }

    // US ZIP code format (5 digits or 5+4)
    final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');

    if (!zipRegex.hasMatch(value)) {
      return 'Please enter a valid ZIP code';
    }

    return null;
  }

  /// Validates a required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  /// Validates a URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL can be optional
    }

    // Simple URL validation
    final urlRegex = RegExp(
      r'^(https?:\/\/)?' // optional protocol
      r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|' // domain name
      r'((\d{1,3}\.){3}\d{1,3}))' // OR ip (v4) address
      r'(\:\d+)?(\/[-a-z\d%_.~+]*)*' // port and path
      r'(\?[;&a-z\d%_.~+=-]*)?' // query string
      r'(\#[-a-z\d_]*)?$', // fragment locator
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Validates a date in the future
  static String? validateFutureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    final now = DateTime.now();

    if (value.isBefore(now)) {
      return 'Date must be in the future';
    }

    return null;
  }

  /// Validates text length
  static String? validateTextLength(String? value,
      {int min = 0, int max = 1000}) {
    if (value == null || value.isEmpty) {
      if (min > 0) {
        return 'This field is required';
      }
      return null;
    }

    if (value.length < min) {
      return 'Must be at least $min characters';
    }

    if (value.length > max) {
      return 'Must be less than $max characters';
    }

    return null;
  }
}
