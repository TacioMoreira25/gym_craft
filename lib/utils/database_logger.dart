import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class DatabaseLogger {
  static bool _isEnabled = true;
  static LogLevel _minLevel = LogLevel.info;
  
  static void configure({bool enabled = true, LogLevel minLevel = LogLevel.info}) {
    _isEnabled = enabled;
    _minLevel = minLevel;
  }
  
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }
  
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }
  
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  static void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (!_isEnabled || level.index < _minLevel.index) return;
    
    String prefix = '[DB ${level.name.toUpperCase()}]';
    String fullMessage = '$prefix $message';
    
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    
    developer.log(
      fullMessage,
      name: 'DatabaseLogger',
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );
  }
  
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}