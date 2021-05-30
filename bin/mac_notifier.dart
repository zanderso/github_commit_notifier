import 'dart:io' as io;

import 'notifier.dart';

class MacNotifier implements Notifier {
  MacNotifier();

  @override
  Future<void> notify({
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  }) async {
    final bool terminalNotifierResult = await _terminalNotifierNotify(
      appName: appName,
      title: title,
      body: body,
      image: image,
      url: url,
      onOpen: onOpen,
      onClose: onClose,
    );
    if (terminalNotifierResult) {
      return;
    }
    await _fallbackNotify(
      appName: appName,
      title: title,
      body: body,
      image: image,
      url: url,
      onOpen: onOpen,
      onClose: onClose,
    );
  }

  Future<bool> _terminalNotifierNotify({
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  }) async {
    try {
      final io.ProcessResult result = await io.Process.run(
        'terminal-notifier',
        <String>[
          '-title',
          '"$title"',
          '-subtitle',
          '"$appName"',
          '-message',
          '"$body"',
          if (image != null) ...<String>['-appIcon', '"$image"'],
          if (url != null) ...<String>['-open', '"$url"'],
        ],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        print('Result: ${result.exitCode}');
        print('stdout:\n${result.stdout as String}');
        print('stderr:\n${result.stderr as String}');
        return false;
      }
      return true;
    } on Exception catch (e) {
      print('Error while running terminal-notifier: "$e"');
      return false;
    }
  }

  Future<void> _fallbackNotify({
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  }) async {
    final List<String> displayCommand = <String>[
      'display',
      'notification',
      '"$body"',
      'with',
      'title',
      '"$title"',
      'subtitle',
      '"$appName"',
    ];
    final String display = displayCommand.join(' ');
    final io.ProcessResult result = await io.Process.run(
      'osascript',
      <String>[
        '-e',
        display,
      ],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      print('Result: ${result.exitCode}');
      print('stdout:\n${result.stdout as String}');
      print('stderr:\n${result.stderr as String}');
    }
  }
}
