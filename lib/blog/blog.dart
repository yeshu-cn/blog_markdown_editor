import 'dart:convert';
import 'dart:io';
import 'package:blog_markdown_editor/blog/category_item.dart';
import 'package:blog_markdown_editor/blog/post_detail.dart';
import 'package:blog_markdown_editor/blog/post_item.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';


PostItem toPostItem(PostDetail detail) {
  return PostItem(
      title: detail.title, createTime: detail.createTime, updateTime: detail.updateTime, category: detail.category);
}

String _assetsPath = './../assets';
String _webPath = './../web';
String _postSourcePath = './data/post';

// posts.json
void createPostsApi(List<PostItem> data) {
  var jsonData = jsonEncode(data);
  File file = File('$_assetsPath/api/posts.json');
  file.writeAsString(jsonData);

  debugPrint('create posts.json file :${file.path}, post count: ${data.length}');
}

// categories.json
void createCategoryApi(List<CategoryItem> data) {
  var jsonData = jsonEncode(data);
  File file = File('$_assetsPath/api/categories.json');
  file.writeAsString(jsonData);

  debugPrint('create categories.json file :${file.path}, category count: ${data.length}');
}

// title_createTime.json
Future<void> createPostDetail(PostDetail data) async {
  var jsonData = jsonEncode(data);
  File file = File('$_assetsPath/post/${data.createTime}.json');
  file.writeAsString(jsonData);

  debugPrint('create post detail json file:${file.path}');
}

void copyImageToWebDir(int postCreateTime, File imageFile) {
  Directory dir = Directory('$_webPath/images/$postCreateTime');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  imageFile.copySync('$_webPath/images/$postCreateTime/${imageFile.uri.pathSegments.last}');
}

void copyPostImageToWebDir(PostDetail postDetail) async {
  postDetail.imagePathList.forEachIndexed((index, element) {
    copyImageToWebDir(postDetail.createTime, File(element));
  });
}

Future<PostDetail> parsePostDetailFromMarkdown(FileSystemEntity entity) async {
  var lines = await (entity as File).readAsLines();
  lines.removeAt(0);
  String title = '';
  String createTime = '';
  String updateTime = '';
  String category = '';
  String content = '';
  int i = 0;
  for (var element in lines) {
    if (element.startsWith("title")) {
      title = element.replaceFirst(RegExp(r'title:'), '').trim();
    } else if (element.startsWith("updated")) {
      updateTime = element.replaceFirst(RegExp(r'updated:'), '').trim();
      updateTime = updateTime.replaceAll(RegExp(r"'"), '').trim();
    } else if (element.startsWith("date")) {
      createTime = element.replaceFirst(RegExp(r'date:'), '').trim();
    } else if (element.startsWith('categories')) {
      category = element.replaceFirst(RegExp(r'categories:'), '').trim();
    } else if (element.startsWith('---')) {
      i++;
      break;
    }
    i++;
  }
  lines.removeRange(0, i);
  for (var element in lines) {
    content = '$content \n $element';
  }
  // 2016-03-07 11:53:45
  var dateFormat = DateFormat('yyyy-MM-dd hh:mm:ss');
  return PostDetail(
      title: title,
      createTime: dateFormat.parse(createTime).millisecondsSinceEpoch,
      updateTime: updateTime.isEmpty ? -1 : dateFormat.parse(updateTime).millisecondsSinceEpoch,
      category: category.isEmpty ? "default" : category,
      content: content);
}

Future<PostDetail> parsePostDetailWithImage(Directory dir) async {
  final List<FileSystemEntity> entities = await dir.list().toList();
  // 删除这个默认的系统隐藏文件
  entities.removeWhere((element) => element.path.endsWith('.DS_Store'));

  PostDetail? postDetail;
  List<String> imageList = [];
  for (var element in entities) {
    if (element is File) {
      if (element.path.endsWith('.md')) {
        // markdown文件
        postDetail = await parsePostDetailFromMarkdown(element);
        postDetail.hasImage = true;
      } else {
        imageList.add(element.path);
      }
    }
  }
  // 最终肯定有帖子，不为null
  postDetail!.hasImage = true;
  postDetail.imagePathList = imageList;
  return postDetail;
}

Future<void> generateBlogData({required String postSourcePath, required String assetsPath, required String webPath}) async {
  _postSourcePath = postSourcePath;
  _assetsPath = assetsPath;
  _webPath = webPath;

  try {
    var dir = Directory(_postSourcePath);
    final List<FileSystemEntity> entities = await dir.list().toList();
    List<PostDetail> postDetailList = [];
    for (var element in entities) {
      if (element is File && element.path.endsWith('.md')) {
        var postDetail = await parsePostDetailFromMarkdown(element);
        postDetailList.add(postDetail);
      } else if (element is Directory) {
        // 目录直接拷贝过去
        var postDetail = await parsePostDetailWithImage(element);
        postDetailList.add(postDetail);
      }
    }
    // 按时间从大到小排序
    postDetailList.sort((a, b) => b.createTime.compareTo(a.createTime));
    // 创建post.md文件
    for (var element in postDetailList) {
      createPostDetail(element);
    }
    // 复制post的image到web目录中
    var postWithImageList = postDetailList.where((element) => element.hasImage);
    for (var element in postWithImageList) {
      copyPostImageToWebDir(element);
    }
    // 创建posts.json
    var postItemList = postDetailList.map((e) => toPostItem(e)).toList();
    createPostsApi(postItemList);

    // 创建categories.json
    List<CategoryItem> categories = [];
    var categoryMap = groupBy<PostItem, String>(postItemList, (item) => item.category);
    categoryMap.forEach((key, value) {
      categories.add(CategoryItem(name: key, postCount: value.length));
    });
    createCategoryApi(categories);
  } catch (e) {
    debugPrint('generateBlogData error: $e');
  }
}

void testReadFile() {
  var file = File('./data/test.md');
  var lines = file.readAsLinesSync();
  lines.forEachIndexed((index, element) {
    debugPrint(element);
  });
}
