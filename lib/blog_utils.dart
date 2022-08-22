import 'dart:io';

import 'package:intl/intl.dart';

class BlogUtils {
  static String _sourceDir = '';

  // init first
  static void init(String sourceDir) {
    _sourceDir = sourceDir;
  }

  static bool isInit() {
    return _sourceDir.isNotEmpty;
  }

  static String _getPostFileDir() {
    return '$_sourceDir${Platform.pathSeparator}source${Platform.pathSeparator}post';
  }

  static String getPostFilePath(String fileName) {
    return  '${_getPostFileDir()}${Platform.pathSeparator}$fileName${Platform.pathSeparator}$fileName.md';
  }

  static bool createNetPost(String fileName) {
    var filePath = getPostFilePath(fileName);
    var file = File(filePath);
    if (file.existsSync()) {
      return false;
    }
    // 2016-05-24 08:00:41
    var format = DateFormat('yyyy-MM-dd hh:mm:ss');
    var date = format.format(DateTime.now());
    file.createSync(recursive: true);
    file.writeAsStringSync('---\n');
    file.writeAsStringSync('title: $fileName\n', mode: FileMode.append);
    file.writeAsStringSync('date: $date\n', mode: FileMode.append);
    file.writeAsStringSync('tags: \n', mode: FileMode.append);
    file.writeAsStringSync('categories: \n', mode: FileMode.append);
    file.writeAsStringSync('---\n', mode: FileMode.append);
    return true;
  }

  static void deletePost(String filePath) {
    // 删除目录和文件
  }

  static void generatePostApi() {}

  static void startServer() {}
}
