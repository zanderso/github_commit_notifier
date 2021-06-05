// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:desktop_notifications/desktop_notifications.dart' as d;
import 'package:pedantic/pedantic.dart';

import '../notifier.dart';

class LinuxNotifier implements Notifier {
  LinuxNotifier();

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
    final d.NotificationsClient notificationsClient = d.NotificationsClient();
    try {
      final List<String> capabilities =
          await notificationsClient.getCapabilities();
      for (final String c in capabilities) {
        print('Capability: $c');
      }

      final io.File? icon = image != null ? io.File(image).absolute : null;
      final d.Notification notification = await notificationsClient.notify(
        title,
        appName: appName,
        body: body,
        hints: <d.NotificationHint>[
          d.NotificationHint.actionIcons(),
          if (icon != null) d.NotificationHint.imagePath(icon.path),
        ],
        actions: const <d.NotificationAction>[
          d.NotificationAction('document-open', 'Open PR'),
        ],
      );

      final Completer<void> done = Completer<void>();
      unawaited(notification.action.then((String action) async {
        if (onOpen != null) {
          final dynamic onOpenResult = onOpen();
          if (onOpenResult is Future<dynamic>) {
            await onOpenResult;
          }
        }
        if (!done.isCompleted) {
          done.complete();
        }
      }));
      unawaited(notification.closeReason
          .then((d.NotificationClosedReason reason) async {
        if (onClose != null) {
          final dynamic onCloseResult = onClose();
          if (onCloseResult is Future<dynamic>) {
            await onCloseResult;
          }
        }
        if (!done.isCompleted) {
          done.complete();
        }
      }));
      await done.future;
    } on Exception catch (e) {
      print('Failed to notify: $e');
    } finally {
      await notificationsClient.close();
    }
  }
}
