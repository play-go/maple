// ignore_for_file: unused_import

import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maple/db.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluent_ui/fluent_ui.dart' as fl;
import 'package:path/path.dart' as p;
// import 'dart:io' show Directory, Platform, File;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tdtx_nf_icons/tdtx_nf_icons.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'dart:ui' as uii;
import 'package:xterm/xterm.dart';
import 'theme.dart';
import 'package:provider/provider.dart';
import 'package:filter_list/filter_list.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

TerminalTheme termtheme = TerminalTheme(
  background: Colors.black,
  foreground: Colors.white,
  cursor: const Color.fromARGB(255, 255, 255, 255),
  black: Colors.black,
  red: Colors.red,
  green: Colors.green,
  yellow: const Color.fromARGB(255, 248, 236, 128),
  blue: Colors.blue,
  magenta: Colors.purple,
  cyan: Colors.cyan,
  white: Colors.white,
  brightBlack: Colors.grey,
  brightRed: Colors.redAccent,
  brightGreen: Colors.lightGreen,
  brightYellow: Colors.yellowAccent,
  brightBlue: Colors.lightBlue,
  brightMagenta: Colors.pink,
  brightCyan: Colors.tealAccent,
  brightWhite: Colors.white70,
  selection: Colors.blue.withOpacity(0.3),
  searchHitBackground: Colors.yellow,
  searchHitBackgroundCurrent: Colors.orange,
  searchHitForeground: Colors.black,
);

DateFormat logform = DateFormat('kk:mm:ss dd.MM.yyyy');
RegExp logRegExp = RegExp(r'^\[(\w)\]\s+([\d/: .+-]+)\s+\[(.*?)\]\s+(.*)$');

void sendtoterm(String line, terminal) {
  final Match? match = logRegExp.firstMatch(line);

  if (match != null) {
    String color;
    switch (match.group(1)) {
      case 'I':
        color = '\x1B[34m'; // Зелёный для информационных сообщений
        break;
      case 'W':
        color = '\x1B[93m'; // Жёлтый для предупреждений
        break;
      case 'E':
        color = '\x1B[31m'; // Красный для ошибок
        break;
      default:
        color = '\x1B[0m'; // Стандартный цвет
    }
    terminal.write(
      "$color[${match.group(1)}] \x1B[33m${match.group(2)}  \x1B[90m[${match.group(3)}] \x1B[0m${match.group(4)}",
    );
  } else {
    terminal.write(line);
  }
  terminal.nextLine();
}

void logterm(Terminal term, String message) {
  DateTime now = DateTime.now();
  term.write("\x1B[33m[${logform.format(now)}] \x1B[34m[LOG] \x1B[0m$message");
  term.nextLine();
}

void nullfunction() {}

void errterm(Terminal term, String message) {
  DateTime now = DateTime.now();
  term.write(
    "\x1B[33m[${logform.format(now)}] \x1B[31m[ERROR] \x1B[0m$message",
  );
  term.nextLine();
}

Future<String> gennamefordir(String destination) async {
  var res = destination;
  var i;
  var k = 1;

  if (await Directory(destination).exists()) {
    while (true) {
      i = "$destination($k)";
      if (!(await Directory(i).exists())) {
        res = i;
        break;
      }
      k++;
    }
  }
  print(res);
  return res;
}

void zatichka(context) async {
  await showDialog<String>(
    context: context,
    builder:
        (context) => fl.ContentDialog(
          title: const Text(
            'УПС... Этого функционала ещё не существует. На данный момент это всего лишь затычка',
          ),
        ),
  );
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  await for (var entity in source.list(recursive: false)) {
    if (entity is Directory) {
      var newDirectory = Directory(
        path.join(destination.absolute.path, path.basename(entity.path)),
      );
      await newDirectory.create();
      await copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      await entity.copy(
        path.join(destination.path, path.basename(entity.path)),
      );
    }
  }
}

Future<String> extractZipArchive(
  String zipFilePath,
  String destinationDirPath,
  String izbegat,
) async {
  final zipFile = File(zipFilePath);
  if (!await zipFile.exists()) {
    throw Exception('Архив не существует: $zipFilePath');
  }

  final bytes = await zipFile.readAsBytes();

  final archive = ZipDecoder().decodeBytes(bytes, verify: false);

  final destinationDir = Directory(destinationDirPath);
  if (!await destinationDir.exists()) {
    await destinationDir.create(recursive: true);
  }
  String res = "";
  bool bres = false;
  for (final file in archive) {
    final filePath = path
        .join(destinationDirPath, file.name)
        .replaceAll("/$izbegat", "");
    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    } else {
      if (!bres) {
        res = file.name.split("/").first;
        if (await Directory("$destinationDirPath/$res").exists()) {
          throw Exception("Мод конфликтует с другими папками модов");
        }
        bres = true;
      } else {
        String a = file.name.split("/").first;
        if (await Directory("$destinationDirPath/$a").exists() && a != res) {
          throw Exception("Мод конфликтует с другими папками модов");
        }
      }
      final dir = Directory(filePath);
      await dir.create(recursive: true);
    }
  }

  return res;
}

Future<String> extractAppImageArchive(
  String zipFilePath,
  String destinationDirPath,
) async {
  String zipFileRoot = zipFilePath.replaceAll("temp.file", "");

  await Process.start(
    "chmod",
    ["+x", zipFilePath],
    runInShell: false,
    workingDirectory: zipFileRoot,
  );
  await File(zipFilePath).copy("$destinationDirPath/game.AppImage");

  return zipFilePath;
}

void termss(terminal, line) {
  final RegExp logRegExp = RegExp(
    r'^\[(\w)\]\s+([\d/: .+-]+)\s+\[(.*?)\]\s+(.*)$',
  );
  final Match? match = logRegExp.firstMatch(line);

  if (match != null) {
    String color;
    switch (match.group(1)) {
      case 'I':
        color = '\x1B[34m';
        break;
      case 'W':
        color = '\x1B[93m';
        break;
      case 'E':
        color = '\x1B[31m';
        break;
      default:
        color = '\x1B[0m';
    }
    terminal.write(
      "$color[${match.group(1)}] \x1B[33m${match.group(2)}  \x1B[90m[${match.group(3)}] \x1B[0m${match.group(4)}",
    );
  } else {
    terminal.write(line);
  }
  terminal.nextLine();
}

class Downloader {
  final String url;
  final String filePath;
  late http.Client client;
  late File file;
  var inss = (String e) async {};
  bool ended = false;
  bool paused = false;
  dynamic speedd, bytes, maxbytes;
  double percent = 0.0;
  int totalBytes = 0;
  final startTime = DateTime.now();
  StreamSubscription<List<int>>? subscription;
  IOSink? fileSink;

  Downloader({required this.url, required this.filePath, required this.inss}) {
    client = http.Client();
    file = File(filePath);
    try {
      file.deleteSync();
    } catch (err) {}
    file.createSync();
    fileSink = file.openWrite();
  }

  Future<String> startDownload({bool deletefile = true}) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.clear();
      request.headers.addAll({"content-type": "application/vnd.github+json"});
      final response = await client.send(request);
      var totalFileLength = int.parse(response.headers['content-length']!);
      subscription = response.stream.listen(
        (List<int> chunk) {
          fileSink!.add(chunk);
          totalBytes += chunk.length;
          double percentDownloaded = (totalBytes / totalFileLength * 100);
          final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
          double speed = (totalBytes / elapsedSeconds) / 1024;
          bytes = totalBytes;
          maxbytes = totalFileLength;
          speedd = speed.toStringAsFixed(0);
          percent = percentDownloaded;
        },
        onDone: () async {
          await fileSink!.close();
          await subscription!.cancel();
          ended = true;
          await inss(
            response.headers["content-disposition"].toString().split(
              "filename=",
            )[1],
          );
          if (deletefile) {
            await file.delete();
          }
        },
        onError: (e) {},
        cancelOnError: true,
      );
    } catch (e) {}
    return "";
  }

  void pauseDownload() {
    if (paused) {
      subscription?.resume();
      paused = false;
    } else {
      subscription?.pause();
      paused = true;
    }
  }

  void resumeDownload() {
    subscription?.resume();
  }

  void cancelDownload() async {
    await subscription?.cancel();
    await fileSink?.close();
    client.close();
  }
}

int checksum(String i, String b) {
  if (i == " ") {
    return 1;
  } else if (b == " ") {
    return -1;
  }
  List ib = [i, b];
  ib.sort();
  if (ib[0] == i) {
    return 1;
  } else {
    return -1;
  }
}

int checklist(List i, List b) {
  if (i.length == 1 && b.length > 1) {
    if (int.tryParse(i[0])! > int.tryParse(b[1])!) {
      return 1;
    } else if (int.tryParse(i[0])! < int.tryParse(b[1])!) {
      return -1;
    }
  } else if (b.length == 1 && i.length > 1) {
    if (int.tryParse(i[1])! > int.tryParse(b[0])!) {
      return 1;
    } else if (int.tryParse(i[1])! < int.tryParse(b[0])!) {
      return -1;
    }
  }
  if (int.tryParse(i[0])! > int.tryParse(b[0])!) {
    return 1;
  } else if (int.tryParse(i[0])! < int.tryParse(b[0])!) {
    return -1;
  } else {
    if (int.tryParse(i[1])! > int.tryParse(b[1])!) {
      return 1;
    } else if (int.tryParse(i[1])! < int.tryParse(b[1])!) {
      return -1;
    } else {
      if (int.tryParse(i[2])! > int.tryParse(b[2])!) {
        return 1;
      } else if (int.tryParse(i[2])! > int.tryParse(b[2])!) {
        return -1;
      } else {
        if (i.length > 3 && b.length > 3) {
          if (int.tryParse(i[4])! > int.tryParse(b[4])!) {
            return 1;
          } else if (int.tryParse(i[4])! > int.tryParse(b[4])!) {
            return -1;
          }
        } else if (i.length > 3 && b.length <= 3) {
          return 1;
        } else if (b.length > 3 && i.length <= 3) {
          return -1;
        }
        if (int.tryParse(i[2])! > int.tryParse(b[2])!) {
          return 1;
        } else if (int.tryParse(i[2])! > int.tryParse(b[2])!) {
          return -1;
        }
        return 0;
      }
    }
  }
}

Widget fakebutton(size) {
  return Column(
    children: [
      SizedBox(
        width: 200,
        height: 200,
        child: fl.Card(
          backgroundColor: fl.Colors.grey,
          child: Container(alignment: Alignment.center, child: Text("0_0")),
        ),
      ),
      SizedBox(height: 20),
      Column(
        spacing: 3,
        children: [
          SizedBox(
            width: 200,
            child: fl.FilledButton(
              child: Text("Запуск"),
              onPressed: nullfunction,
            ),
          ),
          SizedBox(
            width: 200,
            child: fl.Button(
              child: Text("Редактировать"),
              onPressed: nullfunction,
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            width: 200,
            child: fl.Button(
              child: Text("Папка экзепляра"),
              onPressed: nullfunction,
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            width: 200,
            child: fl.Button(
              child: Text("Изменить группу"),
              onPressed: nullfunction,
            ),
          ),
          SizedBox(
            width: 200,
            child: fl.Button(
              child: Text("Копировать"),
              onPressed: nullfunction,
            ),
          ),
          SizedBox(
            width: 200,
            child: fl.Button(child: Text("Экспорт"), onPressed: nullfunction),
          ),
          SizedBox(height: 5),
          SizedBox(
            width: 200,
            child: fl.FilledButton(
              style: fl.ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(fl.Colors.red.lighter),
              ),
              onPressed: nullfunction,
              child: Text("Удалить"),
            ),
          ),
        ],
      ),
    ],
  );
}

Future<dynamic> getjsonfile(filename) async {
  return jsonDecode(await File(filename).readAsString());
}

void setjsonfile(filename, newjson) async {
  await File(filename).writeAsString(jsonEncode(newjson));
}

String timeToText(int totalSeconds) {
  if (totalSeconds < 0 || totalSeconds.isNaN) return "~ секунд";
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 9) {
    return '$hours ${_word(hours, "час", "часа", "часов")}';
  }
  if (hours > 0) {
    return (minutes == 0)
        ? '$hours ${_word(hours, "час", "часа", "часов")}'
        : '$hours ${_word(hours, "час", "часа", "часов")} '
            '$minutes ${_word(minutes, "минута", "минуты", "минут")}';
  }
  if (minutes > 9) {
    return '$minutes ${_word(minutes, "минута", "минуты", "минут")}';
  }
  if (minutes > 0) {
    return '$minutes ${_word(minutes, "минута", "минуты", "минут")} '
        '$seconds ${_word(seconds, "секунда", "секунды", "секунд")}';
  }
  return '$seconds ${_word(seconds, "секунда", "секунды", "секунд")}';
}

String _word(int n, String one, String few, String many) {
  final nMod100 = n % 100;
  if (nMod100 >= 11 && nMod100 <= 14) return many;
  switch (n % 10) {
    case 1:
      return one;
    case 2:
    case 3:
    case 4:
      return few;
    default:
      return many;
  }
}
