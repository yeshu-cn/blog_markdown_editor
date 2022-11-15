import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'blog/blog.dart';

class HomeModel extends ChangeNotifier {
  Directory? _sourceDir;
  File? _currentFile;
  bool _showFileListView = true;
  bool _fileChanged = false;

  Future<void> openSourceDir() async {
    String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _sourceDir = Directory(selectedDirectory);
    }
    notifyListeners();
  }

  File? get currentFile => _currentFile;

  bool get fileChanged => _fileChanged;

  void openFile(File file) async {
    _currentFile = file;
    notifyListeners();
  }

  Future<void> saveFile(String content) async {
    debugPrint('save file');
    if (null == currentFile) {
      return;
    }
    await currentFile!.writeAsString(content);
    _fileChanged = false;
    notifyListeners();
  }

  void toggleFileListView() {
    _showFileListView = !_showFileListView;
    notifyListeners();
  }

  void toggleFileChanged(bool changed) {
    _fileChanged = true;
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

  // 删除目录，或者文件
  void deleteFile() async {
    var postName = _getPostName(_currentFile!);
    var dirPath = _getPostDirPath(postName);
    debugPrint('delete file: $dirPath');
    var postDir = Directory(dirPath);
    if (await postDir.exists()) {
      await postDir.delete(recursive: true);
    } else {
      _currentFile?.delete();
    }
    _currentFile = null;
    notifyListeners();
  }

  String _getPostName(File postFile) {
    return postFile.uri.pathSegments.last.replaceAll('.md', '');
  }

  String _getPostFilePath(String postName) {
    return "${getPostSourcePath()}${Platform.pathSeparator}$postName${Platform.pathSeparator}$postName.md";
  }

  String _getPostDirPath(String postName) {
    return "${getPostSourcePath()}${Platform.pathSeparator}$postName";
  }

  String _getPostImagePath(String postName) {
    var imageName = DateTime.now().millisecondsSinceEpoch;
    return "${getPostSourcePath()}${Platform.pathSeparator}$postName${Platform.pathSeparator}$imageName.png";
  }

  Future<String> savePostImage(Uint8List data) async {
    var imagePath = _getPostImagePath(_getPostName(_currentFile!));
    var file = File(imagePath);
    await file.writeAsBytes(data);
    return file.uri.pathSegments.last;
  }

  Future<File?> createNewFile(String name) async {
    var postPath = _getPostFilePath(name);
    File file = File(postPath);
    try {
      file.createSync(recursive: true);
      var dateFormat = DateFormat('yyyy-MM-dd hh:mm:ss');
      var date = dateFormat.format(DateTime.now());
      await file.writeAsString('---\n', mode: FileMode.append);
      await file.writeAsString('title: $name\n', mode: FileMode.append);
      await file.writeAsString('date: $date\n', mode: FileMode.append);
      await file.writeAsString('tags: \n', mode: FileMode.append);
      await file.writeAsString('categories: \n', mode: FileMode.append);
      await file.writeAsString('---\n', mode: FileMode.append);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> build() async {
    await generateBlogData(postSourcePath: getPostSourcePath(), assetsPath: getAssetsPath(), webPath: getWebPath());
  }

  void run() async {
    var rootPath = _sourceDir!.path;
    debugPrint('root path is $rootPath');
    // var result = await Process.run('ls', [], workingDirectory: rootPath);
    // stdout.write(result.stdout);
    // stderr.write(result.stderr);
    // flutter run -d chrome --web-renderer html &
    var result = await Process.run('flutter', ['run', '-d', 'chrome', '--web-renderer', 'html'], workingDirectory: rootPath);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

}