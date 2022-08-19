import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

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
    return MaterialApp(
      title: 'Blog Markdown Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const MyHomePage(title: 'Blog Markdown Editor'),
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
        print('onKeyDown+${hotKey.toJson()}');
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
        centerTitle: true,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles();

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
                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                if (selectedDirectory != null) {
                  _sourceDir = Directory(selectedDirectory);
                  setState(() {});
                }
              },
              icon: const Icon(Icons.folder_open_rounded)),
          IconButton(onPressed: () async {
            if (null != _currentFile) {
              saveFile(_currentFile!);
            }
          }, icon: Icon(Icons.save, color: _fileChanged ? Colors.blue : Colors.white,)),
        ],
      ),
      body: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (null != _sourceDir)
            SizedBox(
                width: 200,
                child: ListView(
                  controller: ScrollController(),
                  children: _sourceDir!.listSync().map((e) => _buildFileItem(e)).toList(),
                )),
          const VerticalDivider(),
          Expanded(
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                // decoration:
                //     BoxDecoration(borderRadius: BorderRadius.circular(0), border: Border.all(color: Colors.green)),
                child: TextField(
                  maxLines: null,
                  onChanged: (str) {
                    _fileChanged = true;
                    setState(() {});
                  },
                  decoration: const InputDecoration(border: InputBorder.none),
                  controller: _controller,
                ),
              ),
            ),
          ),
          const VerticalDivider(),
          Expanded(child: Markdown(data: _controller.text, imageDirectory: '${_currentFile!.parent.path}${Platform.pathSeparator}',)),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileSystemEntity entity) {
    var name = entity.path.split(Platform.pathSeparator).last;
    return InkWell(
      onTap: () async {
        if (entity is File) {
          openFile(entity);
        } else {
          var childFile = (entity as Directory).listSync().firstWhere((element) => element.path.endsWith(".md"));
          openFile(childFile as File);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Text(name),
      ),
    );
  }

  void openFile(File file) async {
    _currentFile = file;
    _controller.text = await file.readAsString();
    setState(() {

    });
  }

  void saveFile(File file) async {
    await file.writeAsString(_controller.text);
    _fileChanged = false;
    setState(() {

    });
  }
}
