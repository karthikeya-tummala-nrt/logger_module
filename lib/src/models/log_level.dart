enum LogLevel {
  verbose(0),
  debug(1),
  info(2),
  warn(3),
  error(4);

  final int value;
  const LogLevel(this.value);

  bool operator >=(LogLevel other) => value >= other.value;
  bool operator >(LogLevel other) => value > other.value;
  bool operator <=(LogLevel other) => value <= other.value;
  bool operator <(LogLevel other) => value < other.value;
}
