import 'dart:io';
import 'package:blog_markdown_editor/home_page.dart';
import 'package:blog_markdown_editor/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:split_view/split_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return MacosApp(
          title: 'Markdown Editor',
          theme: MacosThemeData.light(),
          darkTheme: MacosThemeData.dark(),
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  Directory? _sourceDir;
  File? _currentFile;
  bool _showFileList = true;

  final HotKey _hotKey = HotKey(
    KeyCode.keyS,
    modifiers: [KeyModifier.meta],
    // Set hotkey scope (default is HotKeyScope.system)
    scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
  );
  bool _fileChanged = false;

  @override
  void initState() {
    _initHotKey();
    super.initState();
  }

  void _initHotKey() async {
    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) {
        // print('onKeyDown+${hotKey.toJson()}');
        if (null != _currentFile) {
          saveFile(_currentFile!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff444444),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            _showFileList = !_showFileList;
            setState(() {});
          },
          icon: const Icon(Icons.vertical_split_rounded),
        ),
        centerTitle: true,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null) {
                  File file = File(result.files.single.path!);
                  openFile(file);
                } else {
                  // User canceled the picker
                }
              },
              icon: const Icon(Icons.file_open_rounded)),
          IconButton(
              onPressed: () async {
                String? selectedDirectory =
                    await FilePicker.platform.getDirectoryPath();
                if (selectedDirectory != null) {
                  _sourceDir = Directory(selectedDirectory);
                  setState(() {});
                }
              },
              icon: const Icon(Icons.folder_open_rounded)),
          IconButton(
              onPressed: () async {
                if (null != _currentFile) {
                  saveFile(_currentFile!);
                }
              },
              icon: Icon(
                Icons.save,
                color: _fileChanged ? Colors.blue : Colors.white,
              )),
          IconButton(
              onPressed: () async {},
              icon: const Icon(
                Icons.cloud_upload_rounded,
              )),
          IconButton(
              onPressed: () async {},
              icon: const Icon(
                Icons.archive_outlined,
              )),
          IconButton(
              onPressed: () async {},
              icon: const Icon(
                Icons.rocket_launch_outlined,
              )),
          // 新建文章
          IconButton(
              onPressed: () async {},
              icon: const Icon(
                Icons.create_rounded,
              )),
          // 删除文章
          IconButton(
              onPressed: () async {},
              icon: const Icon(
                Icons.delete_rounded,
              )),
        ],
      ),
      body: SplitView(
        controller: SplitViewController(weights: getViewWeights()),
        viewMode: SplitViewMode.Horizontal,
        gripSize: 1,
        gripColor: const Color(0xffc5c2c7),
        // indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
        // activeIndicator: const SplitIndicator(
        //   viewMode: SplitViewMode.Horizontal,
        //   isActive: true,
        // ),
        children: [
          if (_showFileList)
            Container(
              color: const Color(0xFFDEDCE1),
              child: _buildFileList(),
            ),
          Container(
            child: _buildEditor(),
          ),
          Container(
            child: _buildPreview(),
          ),
        ],
      ),
    );
  }

  List<double?> getViewWeights() {
    if (_showFileList) {
      return [0.2];
    } else {
      return [0.5, 0.5];
    }
  }

  Widget _buildFileItem(FileSystemEntity entity) {
    var name = entity.path.split(Platform.pathSeparator).last;
    return InkWell(
      onTap: () async {
        if (entity is File) {
          openFile(entity);
        } else {
          var childFile = (entity as Directory)
              .listSync()
              .firstWhere((element) => element.path.endsWith(".md"));
          openFile(childFile as File);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            // 当前选中到文件，显示高亮
            // todo 目录选中还不会高亮
            color: name == _currentFile?.path.split(Platform.pathSeparator).last
                ? const Color(0xffc5c2c7)
                : Colors.transparent,
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 10, top: 4, bottom: 4),
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      ),
    );
  }

  void openFile(File file) async {
    _currentFile = file;
    _controller.text = await file.readAsString();
    setState(() {});
  }

  void saveFile(File file) async {
    await file.writeAsString(_controller.text);
    _fileChanged = false;
    setState(() {});
  }

  Widget _buildFileList() {
    if (null == _sourceDir) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildFileListTitle(0),
            Expanded(
                child: Center(
                    child: Text(
              '暂无数据',
              style: Theme.of(context).textTheme.bodySmall,
            ))),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: ListView(
          controller: ScrollController(),
          children: _buildFileListWidget(),
        ),
      );
    }
  }

  List<Widget> _buildFileListWidget() {
    var list = _sourceDir!.listSync().map((e) => _buildFileItem(e)).toList();
    var title = _buildFileListTitle(list.length);
    list.insert(0, title);
    return list;
  }

  Widget _buildFileListTitle(int fileCount) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 8),
      child: Row(
        children: [
          Text(
            '文档库',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            '($fileCount)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: TextField(
        showCursor: true,
        maxLines: null,
        onChanged: (str) {
          _fileChanged = true;
          setState(() {});
        },
        scribbleEnabled: false,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20.0),
        ),
        controller: _controller,
      ),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      // 预览的时候去掉头部的数据信息
      // todo 这个正则不对
      data: _controller.text
          .replaceFirstMapped(RegExp(r'---[\s\S]*---'), (match) => ''),
      imageDirectory: '${_currentFile?.parent.path}${Platform.pathSeparator}',
    );
  }
}
