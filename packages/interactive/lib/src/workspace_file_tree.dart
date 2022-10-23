import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class WorkspaceFileTree {
  static final log = Logger('WorkspaceFileTree');

  final String directory;

  WorkspaceFileTree._(this.directory);

  static Future<WorkspaceFileTree> create() async {
    final dir = await _getDir();
    await _prepare(dir);

    log.info('Use $dir as workspace');

    return WorkspaceFileTree._(dir);
  }

  void dispose() {
    // maybe remove the dir later?
  }

  String get pathAutoGeneratedDart =>
      p.join(directory, 'lib', 'auto_generated.dart');

  static Future<String> _getDir() async => p.join(Directory.systemTemp.path,
      'dart_interactive_workspace_${DateTime.now().toIso8601String()}');

  static Future<void> _prepare(String dir) async {
    Directory(dir).createSync(recursive: true);
    Directory(p.join(dir, 'lib')).createSync(recursive: true);
    File(p.join(dir, 'pubspec.yaml')).writeAsStringSync(_kDefaultPubspecYaml);
  }
}

const _kDefaultPubspecYaml = '''
name: execution_workspace
environment:
  sdk: ">=2.18.0 <3.0.0"
''';
