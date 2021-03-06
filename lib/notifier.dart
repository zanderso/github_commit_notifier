// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Platform;

import 'src/linux_notifier.dart';
import 'src/mac_notifier.dart';
import 'src/windows_notifier.dart';

abstract class Notifier {
  factory Notifier() {
    if (io.Platform.isLinux) {
      return LinuxNotifier();
    } else if (io.Platform.isMacOS) {
      return MacNotifier();
    } else if (io.Platform.isWindows) {
      return WindowsNotifier();
    }
    throw StateError(
      'This program is not supported on ${io.Platform.operatingSystem}',
    );
  }

  Future<void> notify({
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  });
}
