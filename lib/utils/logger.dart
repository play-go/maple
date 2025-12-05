import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileLogger {
  FileLogger._(this.appName, {required this.maxBytes, required this.keepFiles});

  final String appName;
  final int maxBytes; // например 5 МБ
  final int keepFiles; // сколько лог-файлов хранить
  late final Directory logsDir;

  late File _currentFile;
  IOSink? _sink;
  DateTime _currentDay = _today();
  int _writtenBytes = 0;
  bool _closed = false;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static Future<FileLogger> init({
    required String appName,
    int maxBytes = 5 * 1024 * 1024,
    int keepFiles = 7,
  }) async {
    final logger = FileLogger._(
      appName,
      maxBytes: maxBytes,
      keepFiles: keepFiles,
    );
    await logger._open();
    return logger;
  }

  Future<void> _open() async {
    final baseDir = await getApplicationSupportDirectory();
    logsDir = Directory('${baseDir.path}/$appName/logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    await _rollFile(forceNew: true);
    await _cleanupOldFiles();
  }

  Future<void> _rollFile({bool forceNew = false}) async {
    final nowDay = _today();
    final needNewDay = nowDay.isAfter(_currentDay);
    final needNewBySize = _writtenBytes >= maxBytes;

    if (!forceNew && !needNewDay && !needNewBySize) return;

    await _sink?.flush();
    await _sink?.close();

    _currentDay = nowDay;
    final stamp =
        '${_currentDay.year.toString().padLeft(4, '0')}-'
        '${_currentDay.month.toString().padLeft(2, '0')}-'
        '${_currentDay.day.toString().padLeft(2, '0')}';

    // если по размеру – добавим индекс, чтобы не затирать
    String filePathBase = '${logsDir.path}/app-$stamp';
    String path = '$filePathBase.log';
    if (!forceNew && needNewBySize && await File(path).exists()) {
      int i = 1;
      while (await File('$filePathBase.$i.log').exists()) {
        i++;
      }
      path = '$filePathBase.$i.log';
    }

    _currentFile = File(path);
    _sink = _currentFile.openWrite(mode: FileMode.append);
    _writtenBytes =
        await _currentFile.exists() ? await _currentFile.length() : 0;
  }

  Future<void> _cleanupOldFiles() async {
    final files =
        (await logsDir
                .list()
                .where((e) => e is File && e.path.endsWith('.log'))
                .toList())
            .cast<File>();

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    if (files.length > keepFiles) {
      for (final f in files.skip(keepFiles)) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> log(
    String level,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) async {
    if (_closed) return;
    await _rollFile(); // проверим дату и размер

    final ts = DateTime.now().toIso8601String();
    final buf = StringBuffer()..write('[$ts] [$level] $message');
    if (error != null) buf.write(' | error: $error');
    if (stack != null) buf.write('\n$stack');
    buf.write('\n');

    final line = buf.toString();
    _sink?.write(line);
    _writtenBytes += line.length;
  }

  Future<void> i(String msg) => log('INFO', msg);
  Future<void> w(String msg) => log('WARN', msg);
  Future<void> e(String msg, [Object? err, StackTrace? st]) =>
      log('ERROR', msg, err, st);

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
  }
}
