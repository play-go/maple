// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_function_literals_in_foreach_calls, empty_catches, depend_on_referenced_packages, unused_import
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maple/utils/db.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluent_ui/fluent_ui.dart' as fl;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:ui' as uii;
import 'package:xterm/xterm.dart';
import 'widgets/theme.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import "utils/utils.dart";
import "widgets/wid_instance.dart";
import "widgets/wid_group.dart";
import 'package:clipboard/clipboard.dart';
import 'widgets/gradient_shader_widget.dart';

import 'package:flutter/foundation.dart';

String gendir = Directory.current.path;
String assetf = "$gendir/data/flutter_assets/assets";
String instplace = "$gendir/instances";
String chacheV = "$gendir/cache";
String tempfile = "$gendir/temp.file";
String dbfile = "$gendir/db.json";
String version = "v0.1";
String appTitle = "MapLe";

DateFormat formatter = DateFormat('dd.MM.yyyy');
SharedPreferencesHelper prefs = SharedPreferencesHelper(File(dbfile));
Terminal terminal = Terminal();
final _appTheme = AppTheme();
int itemcount = 16;
final contextController = fl.FlyoutController();
final contextAttachKey = GlobalKey();
List instances = [];
List namesofinst = [];
List profiles = [];

bool changed = false;

List<Map> fortabs = [];

double? progresv;
int pickedidprof = 0;
bool doCloseApp = false;
bool doFrag = false;
bool hideProgress = true;
String fragfilename = "";
String wallpaperfile = "";

bool useNew = false;

void main(List<String> vars) async {
  if (kDebugMode) {
    assetf = "assets";
  }

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.hide();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errterm(terminal, details.exception.toString());
  };

  _appTheme.color = fl.Colors.accentColors[await prefs.get("color", 1)];
  _appTheme.mode = ThemeMode.dark;
  itemcount = await prefs.get("icount", 16);
  doCloseApp = await prefs.get("docloseapp", false);
  doFrag = await prefs.get("dofrag", false);
  useNew = await prefs.get("usenew", false);
  wallpaperfile = await prefs.get("wall", "");
  fragfilename = await prefs.get("frag", "balatro.frag");
  // hideProgress = await prefs.get("lurkprogressbar", false);
  profiles = await prefs.get("profs", []);
  print(gendir);
  await WindowManager.instance.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    windowManager.setTitleBarStyle(
      TitleBarStyle.normal,
      windowButtonVisibility: true,
    );

    await windowManager.center();
    await windowManager.setPreventClose(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(const uii.Size(790, 600));
    await windowManager.setSize(const uii.Size(1000, 700));
    if (Random().nextInt(100) <= 90) {
      await windowManager.setTitle("🍁 | $appTitle $version");
    } else {
      switch (Random().nextInt(6) + 1) {
        case 1:
          await windowManager.setTitle("🍁 | >_<");
          break;
        case 2:
          await windowManager.setTitle("🍁 | <3");
          break;
        case 3:
          await windowManager.setTitle("🍁 | 0_0");
          break;
        case 4:
          await windowManager.setTitle("🍁 | Прочитал? Натурал!");
          break;
        case 5:
          await windowManager.setTitle("🍁 | Компилятор VoxelCore");
      }
    }
  });
  await windowManager.setIcon("$assetf/icons/icon.png");

  // await localNotifier.setup(
  //   appName: 'MapLe',
  //   shortcutPolicy: ShortcutPolicy.requireCreate,
  // );

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.openSansTextTheme(ThemeData.dark().textTheme);
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, child) {
        final appTheme = context.watch<AppTheme>();
        return fl.FluentApp(
          title: 'MapLe',
          locale: const Locale("ru"),
          themeMode: fl.ThemeMode.dark,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: fl.NavigationPaneTheme(
                data: const fl.NavigationPaneThemeData(),
                child: child!,
              ),
            );
          },

          darkTheme: fl.FluentThemeData(
            typography: fl.Typography.raw(
              display: textTheme.displayLarge,
              titleLarge: textTheme.titleLarge,
              title: textTheme.titleMedium,
              subtitle: textTheme.titleSmall,
              bodyLarge: textTheme.bodyLarge,
              bodyStrong: textTheme.bodyMedium,
              body: textTheme.bodyMedium,
              caption: textTheme.bodySmall,
            ),
            accentColor: appTheme.color,
            brightness: fl.Brightness.dark,
          ),
          theme: fl.FluentThemeData(
            typography: fl.Typography.raw(
              display: textTheme.displayLarge,
              titleLarge: textTheme.titleLarge,
              title: textTheme.titleMedium,
              subtitle: textTheme.titleSmall,
              bodyLarge: textTheme.bodyLarge,
              bodyStrong: textTheme.bodyMedium,
              body: textTheme.bodyMedium,
              caption: textTheme.bodySmall,
            ),
            accentColor: appTheme.color,
            brightness: fl.Brightness.dark,
          ),
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  int _selectedRail = 0;
  int _selectedTab = 0;
  int _selectedG = 0;
  double wighperc = 0;
  double heigperc = 0;
  List<fl.ComboBoxItem> verlist = [];
  Map tver = {};
  Map pickedins = {};
  String selectedVersion = "";
  String selectedVersionS = "";

  void topickid(Map inst) {
    pickedins = inst;
    setState(() {});
  }

  void setselectedg(index) {
    _selectedG;
    setState(() => _selectedG = index);
  }

  @override
  void initState() {
    windowManager.addListener(this);
    () async {
      await windowManager.center();
      await windowManager.show();
      await windowManager.focus();
      terminal.write("------ 🍁 | $appTitle $version ------");
      terminal.nextLine();
      logterm(terminal, "[InitState] Запуск приложения");

      if (!await Directory(instplace).exists())
        await Directory(instplace).create();
      if (!await Directory(chacheV).exists()) await Directory(chacheV).create();
      try {
        List a = jsonDecode(
          (await http.get(
            Uri.parse(
              "https://api.github.com/repos/MihailRis/VoxelEngine-Cpp/releases",
            ),
            headers: <String, String>{
              'Content-Type': 'application/vnd.github+json',
            },
          )).body,
        );
        for (Map i in a) {
          String id = jsonEncode(
            i["name"].toString().replaceAll(RegExp(r"v"), "").split("."),
          );
          verlist.add(
            fl.ComboBoxItem(value: id, child: Text("Версия ${i['name']}")),
          );

          tver.addAll({id: i});
        }
        verlist.sort(
          (a, b) => checklist(jsonDecode(a.value), jsonDecode(b.value)),
        );
        verlist = verlist.reversed.toList();
        setState(() {});
      } catch (exp) {}

      await readAllLaunchers(instplace);
      logterm(terminal, "[InitState] Сценарий чтения завершен");
      setState(() {});
      logterm(terminal, "[InitState] Запущено");
    }();
    super.initState();
    // timerrr = Timer.periodic(const Duration(milliseconds: 5000), (timer) {
    //   updatevkladka();
    //   setState(() {});
    // });
  }

  void checkforfolder() {}

  @override
  void dispose() {
    logterm(terminal, "[Dispose] Пока Пока!");
    windowManager.removeListener(this);
    // windowManager.destroy();
    super.dispose();
  }

  //fl.MenuFlyoutItem(text: Text("KaBoT"), onPressed: () {}),

  Widget pickedprofile() {
    return fl.DropDownButton(
      items: [
        for (int i = 0; i < profiles.length; i++)
          fl.MenuFlyoutItem(
            text: fl.Text(profiles[i]),
            onPressed:
                () => setState(() {
                  pickedidprof = i;
                }),
          ),
        fl.MenuFlyoutSeparator(),
        fl.MenuFlyoutItem(
          text: Text("Настроить профилей"),
          onPressed:
              () => setState(() {
                _selectedRail = 2;
              }),
        ),
      ],
      title: Text(profiles.isNotEmpty ? profiles[pickedidprof] : "???"),
    );
  }

  Widget playersname() {
    List<Widget> pp = [];

    profiles.forEach((element) {
      pp.add(
        fl.Card(
          padding: EdgeInsets.all(2),
          child: fl.ListTile(
            title: Text(element),
            // leading: fl.Icon(fl.FluentIcons.circle_shape),
            trailing: fl.IconButton(
              icon: fl.Icon(
                fl.FluentIcons.delete,
                color: fl.Colors.red.lighter,
              ),
              onPressed:
                  () => setState(() {
                    profiles.removeWhere((item) => item == element);
                    prefs.set("profs", profiles);
                  }),
            ),
          ),
        ),
      );
    });

    return SingleChildScrollView(child: Column(children: pp));
  }

  Future<String> readAllLaunchers(
    String parentDir, {
    bool doshit = false,
  }) async {
    final directory = Directory(parentDir);
    instances.clear();
    logterm(terminal, "Запуск сканирования экземпляров");
    if (!await directory.exists()) {
      return "";
    } else {
      await directory.create();
    }
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is Directory) {
        final launcherPath = path.join(entity.path, 'launcher.json');
        final launcherFile = File(launcherPath);

        if (await launcherFile.exists()) {
          try {
            final content = await launcherFile.readAsString();
            final jsonData = jsonDecode(content);

            jsonData["path"] = entity.path;
            jsonData["vrenya"] = timeToText(jsonData["timeplayed"].round());
            if (await File("${jsonData['path']}/icon.png").exists()) {
              jsonData["image"] = Image.file(
                File("${jsonData['path']}/icon.png"),
              );
            } else if (await File("${jsonData['path']}/icon.ico").exists()) {
              jsonData["image"] = Image.file(
                File("${jsonData['path']}/icon.ico"),
              );
            }
            try {
              Map d = instances.firstWhere(
                (d) => d["name"] == jsonData["group"],
                orElse: () => throw Exception(),
              );
              instances
                  .elementAt(instances.indexOf(d))["instances"]
                  .add(jsonData);
            } catch (e) {
              instances.add({
                "name": jsonData["group"],
                "instances": [jsonData],
              });
            }

            // instances.sort((e1, e2) => checksum(e1, e2));
            logterm(
              terminal,
              "${jsonData["name"]}:${jsonData["group"]} загружен",
            );
            namesofinst.add(jsonData);
          } catch (e) {
            errterm(terminal, "Папка ${entity.path} не инициализирована");
            terminal.write(e.toString());
            terminal.nextLine();
          }
        }
      }
    }

    instances.sort((a, b) {
      if (a["name"].isEmpty && b["name"].isNotEmpty) {
        return -1; // пустая строка выше
      }
      if (a["name"].isNotEmpty && b["name"].isEmpty) {
        return 1; // непустая ниже пустой
      }
      return a["name"].compareTo(b["name"]); // обычная сортировка по алфавиту
    });
    if (doshit) {
      pickedins = {};
      pickedidprof = 0;
    }
    logterm(terminal, "Конец сканирования экземпляров");
    setState(() {});
    return "";
  }

  void creatinginstance(String name, String group) async {
    Terminal hellnah = Terminal(maxLines: 100);

    showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder:
          (context) => fl.ContentDialog(
            title: fl.Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Создание инстанса...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(height: 200, child: TerminalView(hellnah)),
          ),
    );
    void printtoterm(String text) {
      hellnah.write(text);
      hellnah.nextLine();
      setState(() {});
    }

    String vers = (jsonDecode(selectedVersion) as List).join(".");
    printtoterm("Название: $name");
    printtoterm("Группа: $group");
    printtoterm("Версия: $vers");
    hellnah.nextLine();
    printtoterm("Запуск кода установки инстанса");

    void installthisshit() async {
      var nn = await gennamefordir("$instplace/$name");
      await Directory(nn).create();
      printtoterm("Папка инстанса создана ($nn)");
      printtoterm("Копирование папки из кэша");
      await copyDirectory(Directory("$chacheV/v$vers"), Directory(nn));
      printtoterm("Создание launcher.json");
      File ljs = File("$nn/launcher.json");
      await ljs.create();
      String execute = "";
      if (Platform.isLinux) {
        execute = "game.AppImage";
      } else if (Platform.isWindows) {
        execute = "VoxelCore.exe";
      }

      ljs.writeAsString(
        jsonEncode({
          "name": name,
          "group": group,
          "execute": execute,
          "timeplayed": 0,
        }),
      );
      logterm(terminal, "Инстанс $name создан");
      printtoterm("Кто прочитал тот badboy");
      Navigator.pop(context, 'Инстанс создан');
      await fl.displayInfoBar(
        context,
        builder: (context, close) {
          return fl.InfoBar(
            style: fl.InfoBarThemeData(),
            title: Text("Инстанс $name создан"),
            severity: fl.InfoBarSeverity.success,
          );
        },
      );
      await readAllLaunchers(instplace);
    }

    try {
      printtoterm("Приступаем к установке версии");
      if (await Directory("$chacheV/v$vers").exists()) {
        printtoterm("Версия в кэше найдена");
        installthisshit();
      } else {
        printtoterm("Версия в кэше не найдена");
        printtoterm("Идёт установка из GitHub...");
        String url = '';
        for (Map l in jsonDecode(
          (await http.get(
            Uri.parse(tver[selectedVersion]["assets_url"]),
            headers: <String, String>{
              'Content-Type': 'application/vnd.github+json',
            },
          )).body,
        )) {
          if (l.isNotEmpty &&
              Platform.isWindows &&
              l["name"].toString().split(".").last == "zip") {
            url = l["browser_download_url"];
          } else if (l.isNotEmpty &&
              Platform.isLinux &&
              l["name"].toString().split(".").last == "AppImage") {
            url = l["browser_download_url"];
          }
        }
        if (url != "") {
          await File(tempfile).create();
          Downloader versDown = Downloader(
            filePath: tempfile,
            url: url,
            inss: (String e) async {
              printtoterm("Кэширование папки");
              String gamedir = "$chacheV/${tver[selectedVersion]["tag_name"]}";
              await Directory(gamedir).create(recursive: true);
              if (Platform.isLinux) {
                await extractAppImageArchive(tempfile, gamedir);
              } else if (Platform.isWindows) {
                await extractZipArchive(
                  tempfile,
                  gamedir,
                  e.replaceAll(".zip", ""),
                );
              }

              logterm(
                terminal,
                "Версия ${tver[selectedVersion]["tag_name"]} закэшированна",
              );
              setState(() {});
              installthisshit();
            },
          );
          await versDown.startDownload();
          setState(() {});
        } else {
          throw Exception(["Не найдена ссылка"]);
        }
      }

      // --- nen edfuf
    } catch (e) {
      Navigator.pop(context, 'Блябь ошибка');
      setState(() {});
      await fl.displayInfoBar(
        context,
        builder: (context, close) {
          return fl.InfoBar(
            style: fl.InfoBarThemeData(),
            title: Text('Ошибка при создании инстанса'),
            severity: fl.InfoBarSeverity.error,
          );
        },
      );
      errterm(terminal, "-------------- Увага! Ошибка!");
      errterm(terminal, e.toString());
    }

    setState(() {});
  }

  void startthisshit() async {
    setState(() {});
    Map mapforsave = pickedins;
    logterm(terminal, pickedins.toString());
    String tempdir = "";
    if (File("${mapforsave['path']}/${mapforsave['execute']}").existsSync()) {
      if (doCloseApp) {
        await windowManager.hide();
      }
      Process a;
      if (Platform.isWindows) {
        a = await Process.start(
          "${mapforsave['path']}/${mapforsave['execute']}",
          [],
          runInShell: false,
          workingDirectory: mapforsave['path'],
        );
      } else {
        tempdir = (await Process.run("mktemp", [])).stdout.toString();
        await Process.run("chmod", [
          "+x",
          mapforsave['execute'],
        ], workingDirectory: mapforsave['path']);
        a = await Process.start(
          "./${mapforsave['execute']}",
          ["--appimage-extract-and-run", "--dir", "${mapforsave['path']}"],
          runInShell: true,
          environment: {"TMPDIR": tempdir},
          workingDirectory: mapforsave['path'],
        );
      }

      await fl.displayInfoBar(
        context,
        builder: (context, close) {
          return const fl.InfoBar(
            style: fl.InfoBarThemeData(),
            title: Text('Игра запущена!'),
            severity: fl.InfoBarSeverity.success,
          );
        },
      );
      int timestart = DateTime.now().millisecondsSinceEpoch;
      await a.exitCode;
      await windowManager.show();
      a.kill();
      int timeplay =
          ((DateTime.now().millisecondsSinceEpoch - timestart) / 1000).round();
      Map h = await getjsonfile("${mapforsave["path"]}/launcher.json");
      h["timeplayed"] += timeplay;
      setjsonfile("${mapforsave["path"]}/launcher.json", h);
      setState(() {});
      if (tempdir != "") await Process.run("rm", ["-rf", tempdir]);
    } else {
      await fl.displayInfoBar(
        context,
        builder: (context, close) {
          return const fl.InfoBar(
            style: fl.InfoBarThemeData(),
            title: Text('Не найден файл для запуска игры!'),
            severity: fl.InfoBarSeverity.error,
          );
        },
      );
    }
  }

  void debugthisshit() async {
    setState(() {});

    fortabs.add({
      "name": pickedins["name"],
      "terminal": Terminal(maxLines: 10000),
    });
    Terminal term = fortabs.last["terminal"];
    Map mapforsave = pickedins;
    logterm(terminal, pickedins.toString());
    if (File("${mapforsave['path']}/${mapforsave['execute']}").existsSync()) {
      Process a;
      String tempdir = "";
      if (Platform.isWindows) {
        a = await Process.start(
          "${mapforsave['path']}/${mapforsave['execute']}",
          [],
          runInShell: false,
          workingDirectory: mapforsave['path'],
        );
      } else {
        tempdir = (await Process.run("mktemp", [])).stdout.toString();
        a = await Process.start(
          "./${mapforsave['execute']}",
          ["--appimage-extract-and-run", "--dir", "${mapforsave['path']}"],
          runInShell: false,
          environment: {"TMPDIR": tempdir},
          workingDirectory: mapforsave['path'],
        );
      }

      await fl.displayInfoBar(
        context,
        builder: (context, close) {
          return const fl.InfoBar(
            style: fl.InfoBarThemeData(),
            title: Text('Игра запущена в дебаг режиме!'),
            severity: fl.InfoBarSeverity.success,
          );
        },
      );

      a.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
        line,
      ) {
        if (line == "") return;
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
          term.write(
            "$color[${match.group(1)}] \x1B[33m${match.group(2)}  \x1B[90m[${match.group(3)}] \x1B[0m${match.group(4)}",
          );
        } else {
          term.write(line);
        }
        term.nextLine();
      });
      a.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
        line,
      ) {
        term.write("\x1B[93m${line.trim()}\x1B[0m");
        term.nextLine();
      });

      int timestart = DateTime.now().millisecondsSinceEpoch;
      await a.exitCode;
      await windowManager.show();
      a.kill();
      int timeplay =
          ((DateTime.now().millisecondsSinceEpoch - timestart) / 1000).round();
      Map h = await getjsonfile("${mapforsave["path"]}/launcher.json");
      h["timeplayed"] += timeplay;
      setjsonfile("${mapforsave["path"]}/launcher.json", h);
      if (tempdir != "") await Process.run("rm", ["-rf", tempdir]);
    } else {
      await fl.displayInfoBar(
        context,
        builder: (context, close) {
          return const fl.InfoBar(
            style: fl.InfoBarThemeData(),
            title: Text('Не найден файл для запуска игры!'),
            severity: fl.InfoBarSeverity.error,
          );
        },
      );
    }
  }

  List<fl.MenuFlyoutItem> genphoto(setStateDialog) {
    List<fl.MenuFlyoutItem> res = [
      fl.MenuFlyoutItem(
        onPressed: () {
          wallpaperfile = "";
          prefs.set("wall", "");
          setState(() {});
          setStateDialog(() {});
        },
        text: Text("Ничего"),
      ),
    ];
    for (var i in Directory("$assetf/icons").listSync()) {
      if (path.basename(i.path) == "README") {
      } else {
        res.add(
          fl.MenuFlyoutItem(
            onPressed: () {
              wallpaperfile = i.path;
              prefs.set("wall", i.path);
              setState(() {});
              setStateDialog(() {});
            },
            text: Text(path.basename(i.path)),
          ),
        );
      }
    }
    return res;
  }

  void selrailtoone(fl.FluentThemeData theme) async {
    await showDialog<String>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return fl.ContentDialog(
                title: fl.Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Настройки',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: fl.Card(
                  child: fl.SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Column(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            fl.ToggleButton(
                              checked: doCloseApp,
                              child: Text("Скрывать при запуске экземпляра"),
                              onChanged:
                                  (bool s) => setStateDialog(() {
                                    doCloseApp = s;
                                    prefs.set("docloseapp", s);
                                  }),
                            ),
                            fl.ToggleButton(
                              checked: useNew,
                              child: Text("Современный дизайн"),
                              onChanged:
                                  (bool s) => setStateDialog(() {
                                    useNew = s;
                                    prefs.set("usenew", s);
                                    setState(() {});
                                  }),
                            ),
                            fl.Button(
                              child: Text("Удалить все терминалы"),
                              onPressed:
                                  () => setState(() {
                                    fortabs.clear();
                                  }),
                            ),
                            fl.ToggleButton(
                              checked: doFrag,
                              child: Text("Шейдер вместо фото на фоне"),
                              onChanged:
                                  (bool s) => setStateDialog(() {
                                    doFrag = s;
                                    prefs.set("dofrag", s);
                                    changed = false;
                                    setState(() {});
                                  }),
                            ),
                            !doFrag
                                ? fl.DropDownButton(
                                  items: genphoto(setStateDialog),
                                  title: Text(path.basename(wallpaperfile)),
                                  leading: Text("Обои"),
                                )
                                : fl.DropDownButton(
                                  items: [
                                    fl.MenuFlyoutItem(
                                      onPressed:
                                          () => setStateDialog(() {
                                            fragfilename = "balatro.frag";
                                            prefs.set("frag", "balatro.frag");
                                            changed = true;
                                          }),
                                      text: Text("Balatro"),
                                    ),
                                    fl.MenuFlyoutItem(
                                      onPressed:
                                          () => setStateDialog(() {
                                            fragfilename = "cloud.frag";
                                            prefs.set("frag", "cloud.frag");
                                            changed = true;
                                          }),
                                      text: Text("Облака"),
                                    ),
                                    fl.MenuFlyoutItem(
                                      onPressed:
                                          () => setStateDialog(() {
                                            fragfilename = "cubes.frag";
                                            prefs.set("frag", "cubes.frag");
                                            changed = true;
                                          }),
                                      text: Text("Кубы"),
                                    ),
                                    fl.MenuFlyoutItem(
                                      onPressed:
                                          () => setStateDialog(() {
                                            fragfilename = "earthbound.frag";
                                            prefs.set(
                                              "frag",
                                              "earthbound.frag",
                                            );
                                            changed = true;
                                          }),
                                      text: Text("EarthBound"),
                                    ),
                                    fl.MenuFlyoutItem(
                                      onPressed:
                                          () => setStateDialog(() {
                                            fragfilename = "shader.frag";
                                            prefs.set("frag", "shader.frag");
                                            changed = true;
                                          }),
                                      text: Text("Пользовательский"),
                                    ),
                                  ],
                                  title: Text(fragfilename),
                                  leading: Text("Шейдер"),
                                ),
                            changed
                                ? Text("Переключите вкладки для обновления!")
                                : Container(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  void selrailtoterms() => setState(() {
    _selectedRail = 3;
  });

  void setrailtozero() => setState(() {
    _selectedRail = 0;
  });

  void crnewinst() async {
    setState(() => selectedVersion = verlist.first.value ?? selectedVersion);
    setState(
      () =>
          selectedVersionS =
              (verlist.first.child as Text).data.toString().split("v")[1] ??
              selectedVersionS,
    );
    final cont = TextEditingController();
    final contg = TextEditingController();
    await showDialog<String>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return fl.ContentDialog(
                title: const Text(
                  'Новый инстанс',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  height: 110,
                  child: Column(
                    spacing: 5,
                    children: [
                      fl.TextBox(
                        controller: cont,
                        expands: false,
                        placeholder: selectedVersionS.toString(),
                        onChanged: (_) => setStateDialog(() {}),
                      ),
                      fl.TextBox(
                        controller: contg,
                        expands: false,
                        placeholder: "Группа",
                        onChanged: (_) => setStateDialog(() {}),
                      ),
                      fl.ComboBox(
                        value: selectedVersion,
                        items: verlist,
                        onChanged: (e) {
                          setStateDialog(() {
                            selectedVersion = e.toString();
                            selectedVersionS = jsonDecode(e).join(".");
                          });
                        },
                        placeholder: Container(width: 280),
                      ),
                    ],
                  ),
                ),
                actions: [
                  fl.FilledButton(
                    onPressed: () {
                      Navigator.pop(context, 'Запуск создания');
                      creatinginstance(
                        cont.text.isNotEmpty ? cont.text : selectedVersionS,
                        contg.text,
                      );
                      setState(() {});
                    },
                    child: const Text('Создать'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void opennewwindow() async {
    zatichka(context);
  }

  void copyfromterm() async {
    List mm = [];
    terminal.lines.forEach((line) {
      line.toString().isNotEmpty ? mm.add(line) : null;
    });
    FlutterClipboard.copy(mm.join("\n"));
    await fl.displayInfoBar(
      context,
      builder: (context, close) {
        return fl.InfoBar(
          title: const Text('Текст из терминала скопирован!'),
          severity: fl.InfoBarSeverity.success,
        );
      },
    );
    setState(() {});
  }

  List<fl.Tab> givemesometabs(fl.FluentThemeData theme) {
    List<fl.Tab> result = [
      fl.Tab(
        body: fl.Card(
          padding: fl.EdgeInsetsGeometry.all(5),
          child: Stack(
            children: [
              TerminalView(
                terminal,
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.keyC, control: true):
                      CopySelectionTextIntent.copy,
                  SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  ): SelectAllTextIntent(SelectionChangedCause.keyboard),
                },
                theme: termtheme,
                readOnly: true,
                backgroundOpacity: 0.25,
                autofocus: true,
              ),
              Container(
                padding: EdgeInsets.all(5),
                alignment: Alignment.bottomRight,
                child: fl.IconButton(
                  style: fl.ButtonStyle(iconSize: WidgetStatePropertyAll(25.0)),
                  icon: Icon(fl.FluentIcons.copy),
                  onPressed: copyfromterm,
                ),
              ),
            ],
          ),
        ),
        text: Text("Лаунчер"),
        selectedBackgroundColor: fl.WidgetStatePropertyAll(
          theme.cardColor.withAlpha(5),
        ),
        icon: Icon(fl.FluentIcons.list),
      ),
    ];

    fortabs.forEach((Map i) {
      result.add(
        fl.Tab(
          selectedBackgroundColor: fl.WidgetStatePropertyAll(
            theme.cardColor.withAlpha(5),
          ),
          body: fl.Card(
            padding: fl.EdgeInsetsGeometry.all(5),
            child: Stack(
              children: [
                TerminalView(
                  i["terminal"],
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.keyC, control: true):
                        CopySelectionTextIntent.copy,
                    SingleActivator(
                      LogicalKeyboardKey.keyA,
                      control: true,
                    ): SelectAllTextIntent(SelectionChangedCause.keyboard),
                  },
                  theme: termtheme,
                  readOnly: true,
                  backgroundOpacity: 0.25,
                  autofocus: true,
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  alignment: Alignment.bottomRight,
                  child: fl.IconButton(
                    style: fl.ButtonStyle(
                      iconSize: WidgetStatePropertyAll(25.0),
                    ),
                    icon: Icon(fl.FluentIcons.copy),
                    onPressed: copyfromterm,
                  ),
                ),
              ],
            ),
          ),
          text: Text(i["name"]),
          icon: Icon(fl.FluentIcons.app_icon_default),
          onClosed: () {
            fortabs.remove(i);
            if (_selectedTab > 0) _selectedTab--;
            setState(() {});
          },
        ),
      );
    });

    return result;
  }

  void newprofile() async {
    final cont = TextEditingController();
    await showDialog<String>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return fl.ContentDialog(
                title: const Text('Новый профиль'),
                content: SizedBox(
                  height: 30,
                  child: fl.TextBox(
                    controller: cont,
                    expands: false,
                    placeholder: "Ваш супер никнейм",
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                ),
                actions: [
                  fl.Button(
                    onPressed:
                        cont.text.isNotEmpty && !profiles.contains(cont.text)
                            ? () {
                              profiles.add(cont.text);
                              prefs.set("profs", profiles);
                              logterm(
                                terminal,
                                "Создан новый профиль {имя: ${cont.text}}",
                              );
                              setState(() {});
                              Navigator.pop(context, 'Создано');
                            }
                            : null,
                    child: const Text('Создать'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void impnewex() async {
    zatichka(context); //FIXME: ZATICHKA
  }

  void setgroup() async {
    final cont = TextEditingController();
    await showDialog<String>(
      context: context,
      builder:
          (context) => fl.ContentDialog(
            title: const Text('Название новой группы'),
            content: SizedBox(
              height: 30,
              child: fl.TextBox(
                controller: cont,
                expands: false,
                placeholder: "Новое название",
              ),
            ),
            actions: [
              fl.Button(
                onPressed: () async {
                  Map a = await getjsonfile(
                    "${pickedins["path"]}/launcher.json",
                  );
                  a["group"] = cont.text;
                  setjsonfile("${pickedins["path"]}/launcher.json", a);
                  logterm(
                    terminal,
                    "Смена группы у ${pickedins["name"]} {теперь группа: ${cont.text.isNotEmpty ? cont.text : "Нет группы"}}",
                  );
                  setState(() {});
                  Navigator.pop(context, 'Создано');
                  await readAllLaunchers(instplace);
                },
                child: const Text('Изменить'),
              ),
            ],
          ),
    );
  }

  void openfolder() {
    OpenFile.open(pickedins["path"]);
  }

  void copythisshit() async {
    String dt = DateTime.now().millisecondsSinceEpoch.toString();
    await showDialog<String>(
      context: context,
      builder:
          (context) => fl.ContentDialog(
            title: const Text(
              'Вы точно хотите копировать инстанс?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // content: SizedBox(height: 40, child: Text("Вы уверенны?")),
            actions: [
              fl.FilledButton(
                onPressed: () async {
                  await copyDirectory(
                    Directory(pickedins["path"]),
                    await Directory(
                      await gennamefordir(pickedins["path"]),
                    ).create(),
                  );
                  logterm(
                    terminal,
                    "Копирование ${pickedins["name"]} {новый инстанс: ${pickedins["name"]}_$dt}",
                  );
                  Navigator.pop(context, 'Создано');
                  await fl.displayInfoBar(
                    context,
                    builder: (context, close) {
                      return fl.InfoBar(
                        title: const Text('Инстанс скопирован!'),
                        severity: fl.InfoBarSeverity.success,
                      );
                    },
                  );
                  setState(() {});
                  await readAllLaunchers(instplace);
                  setState(() {});
                },
                child: const Text('Копировать'),
              ),
            ],
          ),
    );
  }

  void exportthisshit() {
    zatichka(context); //FIXME: ZATICHKA
  }

  void obnovitspisok() async {
    setState(() => pickedins = {});
    Navigator.pop(context, 'Перенос');
    await readAllLaunchers(instplace);
  }

  void deletethisshit() async {
    await showDialog<String>(
      context: context,
      builder:
          (context) => fl.ContentDialog(
            title: const Text('Вы точно хотите удалить инстанс?'),
            content: SizedBox(
              height: 40,
              child: Text(
                "Инстанс \"${pickedins["name"]}\" будет безвозвратно удалён...",
              ),
            ),
            actions: [
              fl.FilledButton(
                onPressed: () async {
                  await Directory(pickedins["path"]).delete(recursive: true);
                  logterm(terminal, "Удалён инстанс ${pickedins["name"]}");
                  Navigator.pop(context, 'Удалено');
                  setState(() {});
                  await readAllLaunchers(instplace, doshit: true);
                  await fl.displayInfoBar(
                    context,
                    builder: (context, close) {
                      return fl.InfoBar(
                        title: const Text('Инстанс удалён!'),
                        severity: fl.InfoBarSeverity.success,
                      );
                    },
                  );
                },
                child: const Text(
                  'Ты должен удалить это сейчас же',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              fl.Button(
                onPressed: () async {
                  Navigator.pop(context, 'Не удалено');
                  setState(() {});
                  await readAllLaunchers(instplace);
                },
                child: const Text('Не чето не хочу пока'),
              ),
            ],
          ),
    );
  }

  Widget buttongen(size) {
    return SizedBox(
      height: size.height - 30,
      width: 250,
      child: fl.Card(
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 25),
            pickedins["image"] == null
                ? SizedBox(
                  width: 200,
                  height: 200,
                  child: fl.Card(
                    backgroundColor: fl.Colors.grey,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(pickedins["name"]),
                    ),
                  ),
                )
                : SizedBox(
                  width: 200,
                  height: 200,
                  child: fl.Card(
                    padding: fl.EdgeInsets.all(2),
                    backgroundColor: fl.Colors.grey,
                    child: pickedins["image"],
                  ),
                ),
            SizedBox(height: 20),
            Column(
              spacing: 3,
              children: [
                Row(
                  spacing: 3,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 28,
                      child: fl.FilledButton(
                        onPressed: startthisshit,
                        child: Text("Запуск"),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      width: 37,
                      child: fl.FilledButton(
                        onPressed: debugthisshit,
                        child: fl.Icon(fl.FluentIcons.bug),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 200,
                  child: fl.Button(
                    onPressed: opennewwindow,
                    child: Text("Редактировать"),
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: 200,
                  child: fl.Button(
                    onPressed: openfolder,
                    child: Text("Папка экзепляра"),
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: 200,
                  child: fl.Button(
                    onPressed: setgroup,
                    child: Text("Изменить группу"),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: fl.Button(
                    onPressed: copythisshit,
                    child: Text("Копировать"),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: fl.Button(
                    onPressed: exportthisshit,
                    child: Text("Экспорт"),
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: 200,
                  child: fl.FilledButton(
                    style: fl.ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        fl.Colors.red.lighter,
                      ),
                    ),
                    onPressed: deletethisshit,
                    child: Text("Удалить"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<fl.NavigationPaneItem> askforbuild(
    Size size,
    fl.FluentThemeData theme,
    int num,
  ) {
    switch (num) {
      case 0:
        return [
          fl.PaneItem(
            icon: Container(),
            body: Stack(
              children: [
                doFrag
                    ? Positioned.fill(child: GradientShaderWidget(fragfilename))
                    : wallpaperfile != ""
                    ? Positioned.fill(
                      child: Image(image: AssetImage(wallpaperfile)),
                    )
                    : Container(),
                Positioned.fill(
                  child:
                      useNew
                          ? fl.Acrylic(
                            shadowColor: Colors.blueAccent,
                            luminosityAlpha: 0.9,
                            blurAmount: 1,
                          )
                          : Container(),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: size.height - 30,
                          width: size.width - 250,
                          child: GestureDetector(
                            onSecondaryTapUp: (d) {
                              // This calculates the position of the flyout according to the parent navigator
                              final targetContext =
                                  contextAttachKey.currentContext;
                              if (targetContext == null) return;
                              final box =
                                  targetContext.findRenderObject() as RenderBox;
                              final position = box.localToGlobal(
                                d.localPosition,
                                ancestor:
                                    fl.Navigator.of(
                                      context,
                                    ).context.findRenderObject(),
                              );

                              contextController.showFlyout(
                                barrierColor: fl.Colors.black.withValues(
                                  alpha: 0.1,
                                ),
                                position: position,
                                builder: (context) {
                                  return fl.FlyoutContent(
                                    child: SizedBox(
                                      width: 250,
                                      height: 110,
                                      child: fl.CommandBar(
                                        overflowBehavior:
                                            fl
                                                .CommandBarOverflowBehavior
                                                .scrolling,
                                        direction: fl.Axis.vertical,
                                        isCompact: false,
                                        primaryItems: [
                                          fl.CommandBarButton(
                                            icon: const fl.Icon(
                                              fl.FluentIcons.add,
                                            ),
                                            label: const Text(
                                              'Создать инстанс',
                                            ),
                                            onPressed:
                                                verlist.isNotEmpty
                                                    ? crnewinst
                                                    : null,
                                          ),
                                          fl.CommandBarButton(
                                            icon: const fl.Icon(
                                              fl.FluentIcons.upload,
                                            ),
                                            label: const Text(
                                              'Импортировать инстанс',
                                            ),
                                            onPressed: impnewex,
                                          ),
                                          fl.CommandBarButton(
                                            icon: const fl.Icon(
                                              fl.FluentIcons.reset,
                                            ),
                                            label: const Text(
                                              'Обновить список',
                                            ),
                                            onPressed: obnovitspisok,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: fl.FlyoutTarget(
                              key: contextAttachKey,
                              controller: contextController,
                              child: fl.Card(
                                borderRadius: BorderRadius.zero,
                                padding: EdgeInsets.zero,
                                child: SizedBox(
                                  height: size.height - heigperc * 6 - 71,
                                  width: uii.Size.infinite.width,
                                  child:
                                      instances.isNotEmpty
                                          ? SingleChildScrollView(
                                            child: Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Wrap(
                                                alignment: WrapAlignment.start,
                                                spacing: 5,
                                                runSpacing: 5,
                                                children: [
                                                  for (
                                                    int i = 0;
                                                    i < instances.length;
                                                    i++
                                                  )
                                                    Group(instances[i]["name"], [
                                                      for (
                                                        int j = 0;
                                                        j <
                                                            instances[i]["instances"]
                                                                .length;
                                                        j++
                                                      )
                                                        Instance(
                                                          instances[i]["instances"][j]["name"],
                                                          _appTheme.color,
                                                          instances[i]["instances"][j],
                                                          pickedins,
                                                          topickid,
                                                          icon:
                                                              instances[i]["instances"][j]["image"],
                                                        ),
                                                    ]),
                                                ],
                                              ),
                                            ),
                                          )
                                          : Center(
                                            child: fl.Card(
                                              child: fl.Text(
                                                "Нажмите правой кнопкой чтобы открыть меню действий",
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        pickedins.isNotEmpty
                            ? buttongen(size)
                            : SizedBox(
                              height: size.height - 30,
                              width: 250,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 25),
                                        useNew ? fakebutton(size) : Container(),
                                      ],
                                    ),
                                  ),

                                  Positioned.fill(
                                    child:
                                        useNew
                                            ? fl.Acrylic(
                                              shadowColor: Colors.blueAccent,
                                              luminosityAlpha: 0.9,
                                              blurAmount: 1,
                                            )
                                            : Container(),
                                  ),
                                  Positioned.fill(
                                    child: fl.Card(
                                      borderRadius: BorderRadius.zero,

                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text("Экземпляр не выбран!"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                    SizedBox(
                      width: size.width,
                      height: 30,
                      child: fl.Card(
                        borderRadius: BorderRadius.zero,
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: fl.Card(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child:
                                    pickedins.isNotEmpty
                                        ? Text(
                                          "${pickedins['name']}, сыграно ${pickedins["vrenya"]}",
                                        )
                                        : Text("Экземпляр не выбран..."),
                              ),
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                !hideProgress
                                    ? fl.ProgressBar(value: progresv)
                                    : Container(),
                                pickedprofile(),
                                fl.IconButton(
                                  icon: Icon(fl.FluentIcons.device_bug),
                                  onPressed: selrailtoterms,
                                ),
                                fl.IconButton(
                                  icon: Icon(fl.FluentIcons.settings),
                                  onPressed: () {
                                    selrailtoone(theme);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      case 2:
        return [
          fl.PaneItem(
            icon: Container(),
            body: Stack(
              children: [
                doFrag
                    ? Positioned.fill(child: GradientShaderWidget(fragfilename))
                    : wallpaperfile != ""
                    ? Positioned.fill(
                      child: Image(image: AssetImage(wallpaperfile)),
                    )
                    : Container(),
                Positioned.fill(
                  child:
                      useNew
                          ? fl.Acrylic(
                            shadowColor: Colors.blueAccent,
                            luminosityAlpha: 0.9,
                            blurAmount: 1,
                          )
                          : Container(),
                ),
                Column(
                  children: [
                    SizedBox(
                      height: size.height - 30,
                      width: size.width,
                      child: Column(
                        mainAxisAlignment: fl.MainAxisAlignment.center,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 80,
                              width: 300,
                              child: fl.Card(
                                borderRadius: BorderRadius.zero,
                                padding: EdgeInsets.zero,
                                child: Column(
                                  mainAxisAlignment:
                                      fl.MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Профили",
                                      style: TextStyle(fontSize: 25),
                                    ),
                                    Text(
                                      "Пока что без функционала",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            fl.Colors.white
                                                .toAccentColor()
                                                .darkest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 300,
                              width: 300,
                              child: fl.Card(
                                borderRadius: BorderRadius.zero,
                                padding: EdgeInsets.zero,
                                child: playersname(),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 40,
                              width: 300,
                              child: fl.FilledButton(
                                onPressed: newprofile,
                                child: fl.Icon(fl.FluentIcons.add),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: size.width,
                      height: 30,
                      child: fl.Card(
                        borderRadius: BorderRadius.zero,
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: fl.Card(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("Профили"),
                              ),
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                !hideProgress
                                    ? fl.ProgressBar(value: progresv)
                                    : Container(),
                                pickedprofile(),
                                fl.IconButton(
                                  icon: Icon(fl.FluentIcons.context_menu),
                                  onPressed: setrailtozero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      case 3:
        return [
          fl.PaneItem(
            icon: Container(),
            body: Stack(
              children: [
                doFrag
                    ? Positioned.fill(child: GradientShaderWidget(fragfilename))
                    : wallpaperfile != ""
                    ? Positioned.fill(
                      child: Image(image: AssetImage(wallpaperfile)),
                    )
                    : Container(),
                Positioned.fill(
                  child:
                      useNew
                          ? fl.Acrylic(
                            shadowColor: Colors.blueAccent,
                            luminosityAlpha: 0.9,
                            blurAmount: 1,
                          )
                          : Container(),
                ),
                fl.Column(
                  children: [
                    SizedBox(
                      height: size.height - 30,
                      width: size.width,
                      child: SizedBox(
                        width: 200,
                        height: 300,
                        child: fl.TabView(
                          tabs: givemesometabs(theme),
                          minTabWidth: 100,
                          showScrollButtons: true,
                          currentIndex: _selectedTab,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex == 0) {
                                return;
                              }
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = fortabs.removeAt(oldIndex - 1);
                              fortabs.insert(newIndex - 1, item);

                              if (_selectedTab == newIndex) {
                                _selectedTab = oldIndex;
                              } else if (_selectedTab == oldIndex) {
                                _selectedTab = newIndex;
                              }
                            });
                          },
                          onChanged: (index) {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: size.width,
                      height: 30,
                      child: fl.Card(
                        borderRadius: BorderRadius.zero,
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: fl.Card(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("Терминалы"),
                              ),
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                !hideProgress
                                    ? fl.ProgressBar(value: progresv)
                                    : Container(),
                                pickedprofile(),
                                fl.IconButton(
                                  icon: Icon(fl.FluentIcons.context_menu),
                                  onPressed: setrailtozero,
                                ),
                                fl.IconButton(
                                  icon: Icon(fl.FluentIcons.settings),
                                  onPressed: () {
                                    selrailtoone(theme);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      case _:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = fl.FluentTheme.of(context);
    uii.Size size = MediaQuery.of(context).size;
    wighperc = (size.width / 100);
    heigperc = (size.height / 100);
    return fl.NavigationView(
      transitionBuilder: (child, animation) {
        return fl.SuppressPageTransition(child: child);
      },
      pane: fl.NavigationPane(
        size: const fl.NavigationPaneSize(compactWidth: 0),
        displayMode: fl.PaneDisplayMode.compact,
        menuButton: Container(),
        indicator: const fl.StickyNavigationIndicator(duration: Duration.zero),
        footerItems: askforbuild(size, theme, _selectedRail),
        selected: 0,
        onChanged: (index) {
          setState(() {
            _selectedRail = index;
          });
        },
      ),
    );
  }
}
