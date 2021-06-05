// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

/// Open the given URL in the user's default application for the URL's scheme.
///
/// http and https URLs, for example, will be opened in the default browser.
///
/// The default utility to open URLs for the platform is used.
/// A process is spawned to run that utility, with the [ProcessResult]
/// being returned.
Future<io.ProcessResult> openUrl(String url) {
  return io.Process.run(_command, <String>[url], runInShell: true);
}

String get _command {
  if (io.Platform.isWindows) {
    return 'start';
  } else if (io.Platform.isLinux) {
    return 'xdg-open';
  } else if (io.Platform.isMacOS) {
    return 'open';
  } else {
    throw UnsupportedError('Operating system not supported by the open_url '
        'package: ${io.Platform.operatingSystem}');
  }
}

class NonPersistentClient extends http.BaseClient {
  NonPersistentClient()
      : client = http_io.IOClient(
          io.HttpClient()..idleTimeout = const Duration(seconds: 0),
        );

  final http.Client client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.persistentConnection = false;
    return client.send(request);
  }

  @override
  void close() {
    client.close();
  }
}
