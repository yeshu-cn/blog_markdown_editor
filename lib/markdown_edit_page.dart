import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:split_view/split_view.dart';

class MarkdownEditPage extends StatefulWidget {
  final File file;

  const MarkdownEditPage(this.file, {Key? key}) : super(key: key);

  @override
  State<MarkdownEditPage> createState() => _MarkdownEditPageState();
}

class _MarkdownEditPageState extends State<MarkdownEditPage> {
  final TextEditingController _controller = TextEditingController();
  bool _fileChanged = false;

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
        _saveFile();
      },
    );
  }

  @override
  void initState() {
    _initHotKey();
    _controller.text = widget.file.readAsStringSync();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MarkdownEditPage oldWidget) {
    print('------->didUpdateWidget:${oldWidget.file.path}');
    _controller.text = widget.file.readAsStringSync();
    _fileChanged = false;
    setState(() {});
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: _buildToolBar(),
      children: [
        ContentArea(builder: (context, scrollController) {
          return SplitView(
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
          );
        }),
        // ContentArea(builder: (context, scrollController) {
        //   return Row(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Flexible(
        //         flex: 1,
        //         child: _buildEditor(),
        //       ),
        //       const VerticalDivider(),
        //       Flexible(
        //         flex: 1,
        //         child: _buildPreview(),
        //       ),
        //     ],
        //   );
        // }),
      ],
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
        ToolBarIconButton(
          label: "Save",
          icon: _fileChanged ? const MacosIcon(
            CupertinoIcons.floppy_disk,
            color: Colors.teal,
          ) : const MacosIcon(
            CupertinoIcons.floppy_disk,
          ),
          onPressed: () => _saveFile(),
          showLabel: true,
        ),
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
          onPressed: () => (){
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
          _fileChanged = true;
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
      controller: ScrollController(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      // 预览的时候去掉头部的数据信息
      // todo 这个正则不对
      data: _controller.text
          .replaceFirstMapped(RegExp(r'---[\s\S]*---'), (match) => ''),
      imageDirectory: '${widget.file.parent.path}${Platform.pathSeparator}',
    );
  }
  void _deleteFile() {

  }

  void _saveFile() async {
    await widget.file.writeAsString(_controller.text);
    _fileChanged = false;
    setState(() {});
  }
}
