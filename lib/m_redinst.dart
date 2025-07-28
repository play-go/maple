// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_function_literals_in_foreach_calls, empty_catches, depend_on_referenced_packages, unused_import
import 'dart:async';
import 'dart:math';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maple/db.dart';
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
import 'theme.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import "utils.dart";
import "wid_instance.dart";
import "wid_group.dart";
import 'package:clipboard/clipboard.dart';

String gendir = Directory.current.path;
String dbfile = "$gendir/db.json";
SharedPreferencesHelper prefs = SharedPreferencesHelper(File(dbfile));
Map jsonData = {};
String watchdir = "$gendir/instances/NewWers";

var _appTheme = AppTheme();
final WindowController windowController = windowController;
void main(List<String> vars) async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.hide();
  _appTheme.color = fl.Colors.accentColors[await prefs.get("color", 1)];
  _appTheme.mode = ThemeMode.dark;
  // idinahuiprogressbar = await prefs.get("lurkprogressbar", false);
  await WindowManager.instance.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    windowManager.setTitleBarStyle(
      TitleBarStyle.normal,
      windowButtonVisibility: true,
    );

    await windowManager.center();
    await windowManager.setPreventClose(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setResizable(false);
    await windowManager.setMinimumSize(const uii.Size(790, 600));
    await windowManager.setMaximumSize(const uii.Size(790, 600));
    await windowManager.setSize(const uii.Size(790, 600));
    if (Random().nextInt(100) <= 90) {
      await windowManager.setTitle("🍁 | Редактор");
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
          await windowManager.setTitle("🍁 | Ты теперь натурал");
          break;
        case 5:
          await windowManager.setTitle("🍁 | Компилятор VoxelCore");
      }
    }
  });
  await windowManager.setIcon("/icon/icon.ico");

  var launcherPath = path.join(watchdir, 'launcher.json');
  var launcherFile = File(launcherPath);
  var content = await launcherFile.readAsString();
  jsonData = jsonDecode(content);

  jsonData["path"] = watchdir;
  jsonData["vrenya"] = timeToText(jsonData["timeplayed"].round());

  if (await File("$watchdir/icon.png").exists()) {
    jsonData["image"] = Image.file(File("$watchdir/icon.png"));
  } else if (await File("$watchdir/icon.ico").exists()) {
    jsonData["image"] = Image.file(File("$watchdir/icon.ico"));
  }

  runApp(Phoenix(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var textTheme = GoogleFonts.openSansTextTheme(ThemeData.dark().textTheme);
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, child) {
        var appTheme = context.watch<AppTheme>();
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
  double wighperc = 0;
  double heigperc = 0;
  bool havecontent = false;
  bool haveconfig = false;
  bool havescreenshot = false;
  bool haveworlds = false;
  List<Directory> folders = [];
  List<fl.NavigationPaneItem> items = [];
  List<fl.NavigationPaneItem> fitems = [];
  TextStyle my17size = TextStyle(fontSize: 17);

  @override
  void initState() {
    windowManager.addListener(this);
    () async {
      await windowManager.center();
      await windowManager.show();
      // if (Directory("$watchdir/content").existsSync()) {
      //   items.add(

      //   );
      // }
      // if (Directory("$watchdir/worlds").existsSync()) {
      //   items.add(

      //   );
      // }
      // if (Directory("$watchdir/screenshots").existsSync()) {
      //   items.add(

      //   );
      // }
      // if (File("$watchdir/latest.log").existsSync()) {
      //   fitems.add(

      //   );
      // }
      // if (File("$watchdir/controls.toml").existsSync()) {
      //   fitems.add(

      //   );
      // }
    }();
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var appTheme = context.watch<AppTheme>();
    // var theme = fl.FluentTheme.of(context);
    uii.Size size = MediaQuery.of(context).size;
    wighperc = (size.width / 100);
    heigperc = (size.height / 100);
    return fl.NavigationView(
      transitionBuilder: (child, animation) {
        return fl.SuppressPageTransition(child: child);
      },
      pane: fl.NavigationPane(
        size: const fl.NavigationPaneSize(openWidth: 180),
        displayMode: fl.PaneDisplayMode.open,
        menuButton: Container(),
        // fl.StickyNavigationIndicator
        indicator: const fl.StickyNavigationIndicator(duration: Duration.zero),
        items: [
          fl.PaneItem(
            icon: fl.Icon(fl.FluentIcons.info),
            title: Text("Информация"),
            body: fl.Card(
              child: Column(
                spacing: 5,
                children: [
                  Center(
                    child:
                        jsonData["image"] == null
                            ? SizedBox(
                              width: 200,
                              height: 200,
                              child: fl.Card(
                                backgroundColor: fl.Colors.grey,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(jsonData["name"]),
                                ),
                              ),
                            )
                            : SizedBox(
                              width: 200,
                              height: 200,
                              child: fl.Card(
                                padding: fl.EdgeInsets.all(2),
                                backgroundColor: fl.Colors.grey,
                                child: jsonData["image"],
                              ),
                            ),
                  ),
                  SizedBox(height: 15),
                  fl.Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Название инстанса", style: my17size),
                        SizedBox(width: 200, child: fl.TextBox()),
                      ],
                    ),
                  ),
                  fl.Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Файл запуска", style: my17size),
                        SizedBox(
                          width: 200,
                          child: fl.Button(
                            child: Text("Файл"),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  fl.Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Параметры запуска", style: my17size),
                        SizedBox(width: 200, child: fl.TextBox()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          fl.PaneItemSeparator(),
          fl.PaneItem(
            icon: fl.Icon(fl.FluentIcons.add_notes),
            title: Text("Моды"),
            body: Container(),
          ),
          fl.PaneItem(
            icon: fl.Icon(fl.FluentIcons.image_pixel),
            title: Text("Миры"),
            body: Container(),
          ),
          fl.PaneItem(
            icon: fl.Icon(fl.FluentIcons.desktop_screenshot),
            title: Text("Скриншоты"),
            body: Container(),
          ),
        ],
        footerItems: [
          fl.PaneItem(
            icon: fl.Icon(fl.FluentIcons.list_mirrored),
            title: Text("Логи"),
            body: fl.Card(child: Container()),
          ),
        ],
        selected: _selectedRail,
        onChanged: (index) {
          setState(() {
            _selectedRail = index;
          });
        },
      ),
    );
  }
}
