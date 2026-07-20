/// 战斗日志条目
class LogEntry {

  LogEntry({
    required this.message,
    DateTime? timestamp,
    this.type = LogEntryType.info,
  }) : timestamp = timestamp ?? DateTime.now();
  final DateTime timestamp;
  final String message;
  final LogEntryType type;

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
