import 'dart:io';
import 'dart:convert';
class SharedPreferencesHelper {
  File file;

  SharedPreferencesHelper(this.file);

  Future<void> init() async {
    if (!await file.exists()) {
      await file.create();
      Map<String, dynamic> jsonData = {};
      final newContent = const JsonEncoder.withIndent('  ').convert(jsonData);
      await file.writeAsString(newContent);
    }
  }

  void set(String key, dynamic value) async {
    await init();
    String content = await file.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(content);
    jsonData[key] = value;
    final newContent = const JsonEncoder.withIndent('  ').convert(jsonData);
    await file.writeAsString(newContent);
  }

  Future<dynamic> get(String key, dynamic defaultValue) async {
    await init();
    String content = await file.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(content);
    return jsonData[key] ?? defaultValue;
  }

  void remove(String key) async {
    await init();
    String content = await file.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(content);
    await jsonData.remove(key);
    final newContent = const JsonEncoder.withIndent('  ').convert(jsonData);
    await file.writeAsString(newContent);
  }
  
  Future<bool> contains(String key) async {
    await init();
    String content = await file.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(content);
    return jsonData.containsKey(key);
  }
}
