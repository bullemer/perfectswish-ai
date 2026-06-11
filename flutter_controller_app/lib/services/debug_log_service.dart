import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
  });

  String get formattedTime {
    final t = timestamp;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}

class DebugLogService extends ChangeNotifier {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 100;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void log(String message, {String level = 'INFO', dynamic error}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error?.toString(),
    );

    _logs.insert(0, entry); // Add to top
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }
    
    // Also print to console
    if (kDebugMode) {
      debugPrint('[$level] $message ${error != null ? "Error: $error" : ""}');
    }
    
    notifyListeners();
  }

  void info(String message) => log(message, level: 'INFO');
  void warning(String message) => log(message, level: 'WARN');
  void error(String message, [dynamic error]) => log(message, level: 'ERROR', error: error);
  
  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
