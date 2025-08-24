extension DatabaseMapExtensions on Map<String, dynamic> {
  
  DateTime? getDateTime(String key) {
    final value = this[key];
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
  
  bool getBool(String key, {bool defaultValue = false}) {
    final value = this[key];
    if (value is int) {
      return value == 1;
    }
    return defaultValue;
  }
  
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = this[key];
    if (value is num) {
      return value.toDouble();
    }
    return defaultValue;
  }
  
  int getInt(String key, {int defaultValue = 0}) {
    final value = this[key];
    if (value is int) {
      return value;
    }
    return defaultValue;
  }
  
  String getString(String key, {String defaultValue = ''}) {
    final value = this[key];
    return value?.toString() ?? defaultValue;
  }
}

extension DateTimeExtensions on DateTime {
  
  int get timestamp => millisecondsSinceEpoch;
  
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return isAfter(weekStart) && isBefore(weekEnd.add(const Duration(days: 1)));
  }
}