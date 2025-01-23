import 'package:logger/logger.dart';

/// LOGGER DESCRIPTION
/// To debug print to console use variable 'logger' with types:
/// logger.t => Trace log
/// logger.d => Debug log
/// logger.i => Info log
/// logger.w => Warning log
/// logger.e => Error log [with param Error]
/// logger.f => Fatal error log [with params Error, StackTrace]
var logger = Logger(
  printer: CustomLogPrinter(
    methodLine: 0,
    //printTime: true,
    noBoxing: true,
    needEmojis: true,
    printClassInfo: true,
  ),
);

class CustomLogPrinter extends PrettyPrinter {
  CustomLogPrinter({
    this.methodLine,
    this.noBoxing = false,
    this.needEmojis = true,
    this.printClassInfo = true,
  }) : super(methodCount: methodLine, noBoxingByDefault: noBoxing, printEmojis: needEmojis);

  final int? methodLine;
  final bool noBoxing;
  final bool needEmojis;
  final bool printClassInfo;

  @override
  List<String> log(LogEvent event, {bool printInfo = true}) {
    // Получение оригинального форматированного лога от PrettyPrinter
    final originalOutput = super.log(event);

    if (!printClassInfo) return originalOutput;

    // final level = event.level.toString().toUpperCase().padRight(5);
    final stackTrace = StackTrace.current;
    final logDetails = _extractLogDetails(stackTrace);

    final className = logDetails['className'] ?? 'UnknownClass';
    final methodName = logDetails['methodName'] ?? 'UnknownMethod';

    if (!printInfo) return originalOutput;

    return originalOutput.map((line) {
      final emoji = noBoxing ? _getEmoji(line) : '';
      final newLine = _removeEmoji(line, emoji);
      return '$emoji[$className->$methodName]:$newLine';
    }).toList();
  }

  String _removeEmoji(String line, String emoji) {
    if (emoji.isEmpty) return line;

    return line.replaceFirst(emoji, '');
  }

  String _getEmoji(String line) {
    for (var value in PrettyPrinter.defaultLevelEmojis.values) {
      if (value.isNotEmpty && line.contains(value)) {
        return value;
      }
    }
    return '';
  }

  Map<String, String?> _extractLogDetails(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    if (lines.length >= 3) {
      // first 3 lines it's current classes (r'#3....')
      final match = RegExp(r'#3\s+([^\s]+)\.(\w+)').firstMatch(lines[3]);
      if (match != null) {
        return {
          'className': match.group(1),
          'methodName': match.group(2),
        };
      }
    }
    return {};
  }
}
