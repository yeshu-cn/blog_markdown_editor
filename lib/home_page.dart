import 'dart:io';
import 'package:blog_markdown_editor/home_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:split_view/split_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _newFileController = TextEditingController();
  final HotKey _hotKey = HotKey(
    KeyCode.keyS,
    modifiers: [KeyModifier.meta],
    scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
  );

  final _copyHotKey = HotKey(
    KeyCode.keyV,
    modifiers: [KeyModifier.meta],
    scope: HotKeyScope.inapp, // Set as inapp-wide hotkey.
  );

  @override
  void initState() {
    _initHotKey();
    super.initState();
  }

  void _initHotKey() async {
    var model = Provider.of<HomeModel>(context, listen: false);
    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) {
        debugPrint('onKeyDown+${hotKey.toJson()}');
        model.saveFile(_controller.text);
      },
    );

    await hotKeyManager.register(
      _copyHotKey,
      keyDownHandler: (hotKey) {
        debugPrint('onKeyDown+${hotKey.toJson()}');
        _handleCopy(model);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xff444444),
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                model.toggleFileListView();
              },
              icon: const Icon(Icons.vertical_split_rounded),
            ),
            centerTitle: true,
            title: Text(_getTitle(model)),
            actions: _getActionList(),
          ),
          body: SplitView(
            controller: SplitViewController(weights: getViewWeights(model.isShowFileListView())),
            viewMode: SplitViewMode.Horizontal,
            gripSize: 1,
            gripColor: const Color(0xffc5c2c7),
            // indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
            // activeIndicator: const SplitIndicator(
            //   viewMode: SplitViewMode.Horizontal,
            //   isActive: true,
            // ),
            children: [
              if (model.isShowFileListView())
                Container(
                  color: const Color(0xFFDEDCE1),
                  child: _buildFileList(model),
                ),
              Container(
                child: _buildEditor(model),
              ),
              Container(
                child: _buildPreview(model),
              ),
            ],
          ),
        );
      },
    );
  }

  List<double?> getViewWeights(bool showFileListView) {
    if (showFileListView) {
      return [0.2];
    } else {
      return [0.5, 0.5];
    }
  }

  Widget _buildFileItem(FileSystemEntity entity, HomeModel model) {
    var name = entity.path.split(Platform.pathSeparator).last;
    return InkWell(
      onTap: () async {
        if (entity is File) {
          _controller.text = await entity.readAsString();
          model.openFile(entity);
        } else {
          var childFile = (entity as Directory).listSync().firstWhere((element) => element.path.endsWith(".md"));
          _controller.text = await (childFile as File).readAsString();
          model.openFile(childFile);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            // ????????????????????????????????????
            color: _isHighLight(name, model) ? const Color(0xffc5c2c7) : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 10, top: 4, bottom: 4),
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

  bool _isHighLight(String name, HomeModel model) {
    return name.replaceAll(".md", '') == model.currentFile?.uri.pathSegments.last.replaceAll(".md", '');
  }

  Widget _buildFileList(HomeModel model) {
    if (!model.isInitSourceDir()) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildFileListTitle(0),
            Expanded(
                child: Center(
                    child: Text(
              '????????????',
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
          children: _buildFileListWidget(model),
        ),
      );
    }
  }

  List<Widget> _getActionList() {
    var model = Provider.of<HomeModel>(context);
    if (model.isInitSourceDir()) {
      return [
        IconButton(
            onPressed: () async {
              await model.openSourceDir();
            },
            tooltip: 'open dir',
            icon: const Icon(Icons.folder_open_rounded)),
        IconButton(
            onPressed: () async {
              model.saveFile(_controller.text);
            },
            tooltip: 'save file',
            icon: Icon(
              Icons.save,
              color: model.fileChanged ? Colors.blue : Colors.white,
            )),
        IconButton(
            onPressed: () async {},
            tooltip: 'upload',
            icon: const Icon(
              Icons.cloud_upload_rounded,
            )),
        IconButton(
            onPressed: () async {
              _showProgressDialog();
              await model.build();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            tooltip: 'build',
            icon: const Icon(
              Icons.archive_outlined,
            )),
        IconButton(
            onPressed: () async {
              model.run();
            },
            tooltip: 'launch',
            icon: const Icon(
              Icons.rocket_launch_outlined,
            )),
        // ????????????
        IconButton(
            onPressed: () async {
              _showCreateNewFileDialog(model);
            },
            tooltip: 'new file',
            icon: const Icon(
              Icons.create_rounded,
            )),
        // ????????????
        IconButton(
            onPressed: () async {
              _showDeleteDialog(model);
            },
            tooltip: 'delete file',
            icon: const Icon(
              Icons.delete_rounded,
            )),
      ];
    } else {
      return [
        IconButton(
            onPressed: () async {
              await model.openSourceDir();
            },
            tooltip: 'open dir',
            icon: const Icon(Icons.folder_open_rounded)),
      ];
    }
  }

  List<Widget> _buildFileListWidget(HomeModel model) {
    var list = model.getPostSourceDir().listSync().map((e) => _buildFileItem(e, model)).toList();
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
            '?????????',
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

  Widget _buildEditor(HomeModel model) {
    return SingleChildScrollView(
      controller: ScrollController(),
      child: TextField(
        showCursor: true,
        maxLines: null,
        onChanged: (str) {
          model.toggleFileChanged(true);
        },
        scribbleEnabled: false,
        decoration: const InputDecoration(
          border: InputBorder.none,
          // fillColor: Color(0x90fdf6e3),
          // filled: true,
          contentPadding: EdgeInsets.all(20.0),
        ),
        controller: _controller,
      ),
    );
  }

  Widget _buildPreview(HomeModel model) {
    return Markdown(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      // ??????????????????????????????????????????
      data: _controller.text.replaceFirstMapped(RegExp(r'---\n[\s\S]*\n---\n'), (match) => ''),
      imageDirectory: '${model.currentFile?.parent.path}${Platform.pathSeparator}',
    );
  }

  String _getTitle(HomeModel model) {
    if (null == model.currentFile) {
      return widget.title;
    } else {
      return model.currentFile!.uri.pathSegments.last;
    }
  }

  void _showCreateNewFileDialog(HomeModel model) async {
    var ret = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('New file'),
            content: TextField(
              controller: _newFileController,
              decoration: const InputDecoration(hintText: "Input file name"),
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, _newFileController.text.trim()), child: const Text('Confirm'))
            ],
          );
        });
    if (null != ret) {
      var file = await model.createNewFile(ret);
      if (null != file) {
        _controller.text = await file.readAsString();
        model.openFile(file);
      } else {}
    }
  }

  void _showDeleteDialog(HomeModel model) async {
    var ret = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete file'),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))
            ],
          );
        });
    if (ret) {
      _controller.text = '';
      model.deleteFile();
    }
  }

  void _handleCopy(HomeModel model) async {
    ClipboardData? cdata = await Clipboard.getData(Clipboard.kTextPlain);
    debugPrint(cdata?.text);
    final imageBytes = await Pasteboard.image;
    debugPrint('image bytes length: ${imageBytes?.length}');
    if (null != imageBytes && null != model.currentFile) {
      var imagePath = await model.savePostImage(imageBytes);
      // ?????????????????????
      var cursorPos = _controller.selection.base.offset;
      // Right text of cursor position
      String suffixText = _controller.text.substring(cursorPos);

      // Add new text on cursor position
      String specialChars = '![]($imagePath)';
      int length = specialChars.length;

      // Get the left text of cursor
      String prefixText = _controller.text.substring(0, cursorPos);

      _controller.text = prefixText + specialChars + suffixText;

      // Cursor move to end of added text
      _controller.selection = TextSelection(
        baseOffset: cursorPos + length,
        extentOffset: cursorPos + length,
      );
    }
  }

  void _showProgressDialog() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return Dialog(
            // The background color
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // The loading indicator
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 15,
                  ),
                  // Some text
                  Text('Loading...')
                ],
              ),
            ),
          );
        });
  }
}
