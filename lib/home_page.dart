import 'dart:io';
import 'package:blog_markdown_editor/utils.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:split_view/split_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchFieldController = TextEditingController();

  Directory? _sourceDir;
  String? _currentFile;

  final List<String> _openFileList = [];

  final TextEditingController _controller = TextEditingController();
  var lastEditTime = 0;

  final HotKey _hotKey = HotKey(
    KeyCode.keyS,
    modifiers: [KeyModifier.meta],
    // Set hotkey scope (default is HotKeyScope.system)
    scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
  );

  void _initHotKey() async {
    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) {
        if (null != _currentFile) {
          _saveFile();
        }
      },
    );
  }

  @override
  void initState() {
    _initHotKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _buildMenus(),
      body: MacosWindow(
        sidebar: _buildSideBar(),
        endSidebar: _buildEndSideBar(),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return MacosScaffold(
      toolBar: _buildToolBar(),
      children: _isEmpty() ? _buildEmptyData() : _buildMarkDownEditor(),
    );
  }

  bool _isEmpty() {
    return _openFileList.isEmpty;
  }

  List<Widget> _buildMarkDownEditor() {
    return [
      ContentArea(builder: (_, __) {
        return Column(
          children: [
            _buildOpenTabs(),
            Expanded(
                child: SplitView(
              controller: SplitViewController(weights: [0.5, 0.5]),
              viewMode: SplitViewMode.Horizontal,
              gripSize: 2,
              gripColor: const Color(0xffc5c2c7),
              children: [
                Container(
                  child: _buildEditor(),
                ),
                Container(
                  child: _buildPreview(),
                ),
              ],
            )),
          ],
        );
      })
    ];
  }

  Widget _buildOpenTabs() {
    return Container(
      color: const Color(0xffF7F5F5),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: _buildTabs(),
      ),
    );
  }

  List<Widget> _buildTabs() {
    return _openFileList.mapIndexed((index, element) {
      var fileName = getFileName(element);
      var highLight = fileName == getFileName(_currentFile!);
      return _buildTab(element, highLight);
    }).toList();
  }

  List<Widget> _buildEmptyData() {
    return [
      ContentArea(builder: (_, __) {
        return const Center(
          child: Text('Hello Markdown'),
        );
      })
    ];
  }

  Widget _buildTab(String filePath, bool highLight) {
    var fileName = getFileName(filePath);
    return GestureDetector(
      onTap: () {
        _currentFile = filePath;
        setState(() {});
      },
      child: Container(
        width: 240,
        decoration: BoxDecoration(
            color:
                highLight ? const Color(0xffffffff) : const Color(0xffF7F5F5),
            border: const Border(right: BorderSide(color: Color(0xffE0DEDE)))),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 10, bottom: 10, left: 20, right: 20),
                child: Text(
                  fileName,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  _closeEditFile(filePath);
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.close_sharp,
                    size: 16,
                    color: Color(0xffd7d5d5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: MacosTextField.borderless(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        showCursor: true,
        maxLines: null,
        autofocus: true,
        onChanged: (str) {
          _checkAutoSave();
          setState(() {});
        },
        expands: true,
        cursorColor: Colors.teal,
        controller: _controller,
      ),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      selectable: true,
      controller: ScrollController(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      // 预览的时候去掉头部的数据信息
      // todo 这个正则不对
      data: _controller.text
          .replaceFirstMapped(RegExp(r'---[\s\S]*---'), (match) => ''),
      imageDirectory: '',
    );
  }

  ToolBar _buildToolBar() {
    return ToolBar(
      leading: MacosTooltip(
        message: 'Toggle Sidebar',
        useMousePosition: false,
        child: MacosIconButton(
          icon: MacosIcon(
            CupertinoIcons.sidebar_left,
            color: MacosTheme.brightnessOf(context).resolve(
              const Color.fromRGBO(0, 0, 0, 0.5),
              const Color.fromRGBO(255, 255, 255, 0.5),
            ),
            size: 20.0,
          ),
          boxConstraints: const BoxConstraints(
            minHeight: 20,
            minWidth: 20,
            maxWidth: 48,
            maxHeight: 38,
          ),
          onPressed: () => MacosWindowScope.of(context).toggleSidebar(),
        ),
      ),
      title: const Text('Markdown Editor'),
      actions: [
        ToolBarIconButton(
          icon: const MacosIcon(
            CupertinoIcons.doc_text,
          ),
          onPressed: () => debugPrint("New"),
          label: "New",
          showLabel: true,
          tooltipMessage: "New File",
        ),
        // ToolBarIconButton(
        //   label: "Save",
        //   icon: const MacosIcon(
        //     CupertinoIcons.floppy_disk,
        //   ),
        //   onPressed: () {},
        //   showLabel: true,
        // ),
        ToolBarIconButton(
          label: "Delete",
          icon: const MacosIcon(
            CupertinoIcons.trash,
          ),
          onPressed: () => debugPrint("pressed"),
          showLabel: true,
        ),
        const ToolBarDivider(),
        ToolBarIconButton(
          label: "Generate Data",
          icon: const MacosIcon(
            CupertinoIcons.archivebox,
          ),
          onPressed: () => debugPrint("Table..."),
          showLabel: true,
        ),
        ToolBarIconButton(
          label: "Start Server",
          icon: const MacosIcon(
            CupertinoIcons.play,
          ),
          onPressed: () => () {
            // Process.run(executable, arguments);
          },
          showLabel: true,
        ),
        ToolBarIconButton(
          label: "Deploy",
          icon: const MacosIcon(
            CupertinoIcons.share,
          ),
          onPressed: () => debugPrint("pressed"),
          showLabel: true,
        ),
      ],
    );
  }

  List<PlatformMenu> _buildMenus() {
    return [
      const PlatformMenu(
        label: 'macos_ui Widget Gallery',
        menus: [
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.about,
          ),
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.quit,
          ),
        ],
      ),
      const PlatformMenu(
        label: 'View',
        menus: [
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.toggleFullScreen,
          ),
        ],
      ),
      const PlatformMenu(
        label: 'Window',
        menus: [
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.minimizeWindow,
          ),
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.zoomWindow,
          ),
        ],
      ),
    ];
  }

  Sidebar _buildSideBar() {
    return Sidebar(
      decoration: const BoxDecoration(
        color: Color(0xFFDEDCE1),
      ),
      minWidth: 200,
      builder: (context, controller) {
        return _buildFileList(controller);
      },
      top: _buildTop(),
      bottom: _buildBottom(),
    );
  }

  Widget _buildBottom() {
    return Row(
      children: [
        GestureDetector(
          child: const Icon(
            CupertinoIcons.folder_open,
            size: 20,
            color: Colors.black45,
          ),
          onTap: () {
            _openFolder();
          },
        ),
      ],
    );
  }

  void _openFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _sourceDir = Directory(selectedDirectory);
      setState(() {});
    }
  }

  Sidebar _buildEndSideBar() {
    return Sidebar(
      startWidth: 200,
      minWidth: 200,
      maxWidth: 300,
      shownByDefault: false,
      builder: (context, scrollController) {
        return const Center(
          child: Text('End Sidebar'),
        );
      },
    );
  }

  Widget _buildTop() {
    int fileCount = _sourceDir?.listSync().length ?? 0;
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

  List<Widget> _buildFileListWidget() {
    var list = _sourceDir!.listSync().map((e) => _buildFileItem(e)).toList();
    return list;
  }

  void _editFile(String file) async {
    // 显示新文件前，保存文件内容
    if (null != _currentFile) {
      _saveFile();
    }

    _currentFile = file;
    _controller.text = File(_currentFile!).readAsStringSync();
    if (!_openFileList.contains(file)) {
      _openFileList.add(file);
    }
    setState(() {});
  }

  void _closeEditFile(String file) {
    // 关闭前保存文件内容
    _saveFile();

    updateCurrentFile(file);
    _openFileList.remove(file);
    setState(() {});
  }

  void updateCurrentFile(String file) {
    // 如果关闭的是当前正在看的文件，则显示上一个文件，如果关闭的是其他文件则不用管
    if (file != _currentFile) {
      return;
    }
    var index = _openFileList.indexOf(file);
    var preIndex = index - 1;
    if (preIndex >= 0) {
      var preFile = _openFileList.elementAt(preIndex);
      _currentFile = preFile;
    } else {
      var nextIndex = index + 1;
      if (nextIndex < _openFileList.length) {
        var nextFile = _openFileList.elementAt(nextIndex);
        _currentFile = nextFile;
      } else {
        _currentFile = null;
      }
    }
  }

  Widget _buildFileItem(FileSystemEntity entity) {
    var name = entity.path.split(Platform.pathSeparator).last;
    return GestureDetector(
      onTap: () async {
        if (entity is File) {
          _editFile(entity.path);
        } else {
          var childFile = (entity as Directory)
              .listSync()
              .firstWhere((element) => element.path.endsWith(".md"));
          _editFile(childFile.path);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            // 当前选中到文件，显示高亮
            // todo 目录选中还不会高亮
            color: name == getFileName(_currentFile ?? '')
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

  Widget _buildFileList(ScrollController controller) {
    if (null == _sourceDir) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
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
          controller: controller,
          children: _buildFileListWidget(),
        ),
      );
    }
  }

  // 输入字符后，2秒内没有新的输入，则自动保存文件内容
  void _checkAutoSave() {
    lastEditTime = DateTime.now().millisecondsSinceEpoch;
    Future.delayed(const Duration(seconds: 2)).then((value) {
      if (DateTime.now().millisecondsSinceEpoch - lastEditTime > 2 * 1000) {
        _saveFile();
      }
    });
  }

  void _saveFile() async {
    var file = File(_currentFile!);
    await file.writeAsString(_controller.text);
  }
}
