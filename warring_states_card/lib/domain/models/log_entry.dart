/// 战斗日志条目
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogEntryType type;

  LogEntry({
    required this.message,
    DateTime? timestamp,
    this.type = LogEntryType.info,
  }) : timestamp = timestamp ?? DateTime.now();

  LogEntry copyWith({String? message, LogEntryType? type}) {
    return LogEntry(
      message: message ?? this.message,
      type: type ?? this.type,
    );
  }
}

enum LogEntryType {
  info,
  damage,
  heal,
  death,
  play,
  system,
}
