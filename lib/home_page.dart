import 'dart:io';
import 'package:blog_markdown_editor/markdown_edit_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchFieldController = TextEditingController();

  Directory? _sourceDir;
  File? _currentFile;

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _buildMenus(),
      body: MacosWindow(
        sidebar: _buildSideBar(),
        endSidebar: _buildEndSideBar(),
        child: null == _currentFile
            ? const Center(child: Text('Hello Markdown'))
            : MarkdownEditPage(_currentFile!),
      ),
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

  void openFile(File file) async {
    _currentFile = file;
    setState(() {});
  }

  Widget _buildFileItem(FileSystemEntity entity) {
    var name = entity.path.split(Platform.pathSeparator).last;
    return GestureDetector(
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
}
