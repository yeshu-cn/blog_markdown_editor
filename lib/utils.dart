import 'dart:io';

String getFileName(String filePath) {
  return filePath.split(Platform.pathSeparator).last;
}
