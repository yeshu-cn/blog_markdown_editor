import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import 'blog/blog.dart';

class HomeModel extends ChangeNotifier {
  Directory? _sourceDir;
  File? currentFile;
  bool _showFileListView = true;
  bool fileChanged = false;

  Future<void> openSourceDir() async {
    String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _sourceDir = Directory(selectedDirectory);
    }
    notifyListeners();
  }

  void openFile(File file) async {
    currentFile = file;
    notifyListeners();
  }

  Future<void> saveFile(String content) async {
    if (null == currentFile) {
      return;
    }
    await currentFile!.writeAsString(content);
    fileChanged = false;
    notifyListeners();
  }

  void toggleFileListView() {
    _showFileListView = !_showFileListView;
    notifyListeners();
  }

  void toggleFileChanged(bool changed) {
    // if (fileChanged == changed) {
    //   // 如果没有发生变化则不刷新界面
    //   return;
    // }
    fileChanged = true;
    notifyListeners();
  }

  String getPostSourcePath() {
    return '${_sourceDir!.path}${Platform.pathSeparator}source${Platform.pathSeparator}post';
  }

  Directory getPostSourceDir() {
    return Directory(getPostSourcePath());
  }

  String getAssetsPath() {
    return '${_sourceDir!.path}${Platform.pathSeparator}assets';
  }

  String getWebPath() {
    return '${_sourceDir!.path}${Platform.pathSeparator}web';
  }

  bool isInitSourceDir() {
    return null !=_sourceDir;
  }

  bool isShowFileListView() {
    return _showFileListView;
  }


  void build() {
    generateBlogData(postSourcePath: getPostSourcePath(), assetsPath: getAssetsPath(), webPath: getWebPath());
  }

  void run() async {
    var result = await Process.run('grep', ['-i', 'main', 'test.dart']);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

}