import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

String getFileName(String filePath) {
  return filePath.split(Platform.pathSeparator).last;
}

Future saveSourceDir(String sourceDirPath) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sourceDir', sourceDirPath);
}

Future<String?> getSourceDir() async {
  final prefs = await SharedPreferences.getInstance();
  return  prefs.getString('sourceDir');
}

String getBlogPostSourceDir(String sourceDir) {
  return '$sourceDir${Platform.pathSeparator}source/post';
}

void runBlogS() async {
  var sourceDir = await getSourceDir();
  if (null == sourceDir) {
    return;
  }
  var sh = '$sourceDir${Platform.pathSeparator}blog.sh';
  Process.run(sh, ['s']).then((result) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  });
}