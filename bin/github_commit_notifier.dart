// @dart=2.12

import 'dart:async';
import 'dart:io' as io;

import 'package:desktop_notifications/desktop_notifications.dart' as d;
import 'package:github/github.dart' as g;

Future<void> _linuxNotify({
  required String appName,
  required String title,
  required String body,
  String? image,
  dynamic Function()? onOpen,
  dynamic Function()? onClose,
}) async {
  final d.NotificationsClient notificationsClient = d.NotificationsClient();
  try {
    final List<String> capabilities = await notificationsClient.getCapabilities();
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
      actions: <d.NotificationAction>[
        d.NotificationAction('document-open', 'Open PR'),
      ],
    );

    final Completer<void> done = Completer<void>();
    notification.action.then((String action) async {
      if (onOpen != null) {
        final dynamic onOpenResult = onOpen();
        if (onOpenResult is Future<dynamic>) {
          await onOpenResult;
        }
      }
      if (!done.isCompleted) {
        done.complete();
      }
    });
    notification.closeReason.then(
      (d.NotificationClosedReason reason) async {
        if (onClose != null) {
          final dynamic onCloseResult = onClose();
          if (onCloseResult is Future<dynamic>) {
            await onCloseResult;
          }
        }
        if (!done.isCompleted) {
          done.complete();
        }
      }
    );
    await done.future;
  } catch (e) {
    print('Failed to notify: $e');
  } finally {
    notificationsClient.close();
  }
}

Future<void> _windowsNotify({
  required String appName,
  required String title,
  required String body,
  String? image,
  dynamic Function()? onOpen,
  dynamic Function()? onClose,
}) async {
}

Future<void> notify({
  required String appName,
  required String title,
  required String body,
  String? image,
  dynamic Function()? onOpen,
  dynamic Function()? onClose,
}) async {
  if (io.Platform.isLinux) {
    await _linuxNotify(
      appName: appName,
      title: title,
      body: body,
      image: image,
      onOpen: onOpen,
      onClose: onClose,
    );
  } else if (io.Platform.isWindows) {
    await _windowsNotify(
      appName: appName,
      title: title,
      body: body,
      image: image,
      onOpen: onOpen,
      onClose: onClose,
    );
  } else {
    throw StateError(
      'Platform "${io.Platform.operatingSystem}"" is not supported.',
    );
  }
}

Future<void> main(List<String> arguments) async {
  await notify(
    appName: 'Flutter',
    title: 'flutter/engine Commit',
    body: 'Use package:litetest for flutter_frontend_server',
    image: 'bin/logo_flutter_1080px_clr.png',
    onOpen: () async {
      await openUrl('https://github.com/flutter/engine/pull/26341');
    },
    onClose: () {
      print('Notification closed.');
    }
  );

  // final d.NotificationsClient notificationsClient = d.NotificationsClient();
  // try {
  //   final List<String> capabilities = await notificationsClient.getCapabilities();
  //   for (final String c in capabilities) {
  //     print('Capability: $c');
  //   }

  //   final io.File icon = io.File('bin/logo_flutter_1080px_clr.png').absolute;
  //   final d.Notification notification = await notificationsClient.notify(
  //     'flutter/engine Commit',
  //     appName: 'Flutter',
  //     body: 'Use package:litetest for flutter_frontend_server',
  //     hints: <d.NotificationHint>[
  //       d.NotificationHint.actionIcons(),
  //       d.NotificationHint.imagePath(icon.path),
  //     ],
  //     actions: <d.NotificationAction>[
  //       d.NotificationAction('document-open', 'Open PR'),
  //     ],
  //   );

  //   final Completer<void> done = Completer<void>();
  //   notification.action.then((String action) {
  //     print('Action = $action');
  //     openUrl('https://github.com/flutter/engine/pull/26341');
  //     if (!done.isCompleted) {
  //       done.complete();
  //     }
  //   });
  //   notification.closeReason.then((d.NotificationClosedReason reason) {
  //     print('Closed $reason');
  //     if (!done.isCompleted) {
  //       done.complete();
  //     }
  //   });
  //   await done.future;
  // } catch (e) {
  //   print('Failed to notify: $e');
  // }
  // notificationsClient.close();
}

/// Open the given URL in the user's default application for the URL's scheme.
///
/// http and https URLs, for example, will be opened in the default browser.
///
/// The default utility to open URLs for the platform is used.
/// A process is spawned to run that utility, with the [ProcessResult]
/// being returned.
Future<io.ProcessResult> openUrl(String url) {
  return io.Process.run(_command, [url], runInShell: true);
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

// void main(List<String> arguments) {
//   final d.NotificationsClient? notificationsClient;
//   if (io.Platform.isLinux) {
//     // Do I need to make my own dbus?
//     notificationsClient = d.NotificationsClient();
//   } else {
//     notificationsClient = null;
//   }

//   final g.GitHub github = g.GitHub(auth: g.findAuthenticationFromEnvironment());
//   final g.ActivityService activityService = g.ActivityService(github);
//   final g.EventPoller repoEventPoller = activityService.pollRepositoryEvents(
//     g.RepositorySlug('flutter', 'flutter'),
//   );
//   final Stream<g.Event> repoEventStream = repoEventPoller.start(
//     onlyNew: true,
//     interval: 5, // secconds.
//   );
//   repoEventStream.listen((g.Event event) async {
//     final String? type = event.type;
//     if (type == null) {
//       return;
//     }
//     if (type != 'PullRequestEvent') {
//       //print('Event: $type');
//       return;
//     }
//     final Map<String, dynamic>? payload = event.payload;
//     if (payload == null) {
//       //print('\tNo payload');
//       return;
//     }
//     final String action = payload['action'];
//     if (action != 'closed') {
//       //print('\t$action');
//       return;
//     }
//     final Map<String, dynamic>? pullRequest = payload['pull_request'] as Map<String, dynamic>?;
//     if (pullRequest == null) {
//       //print('\tClose action without PR?');
//       return;
//     }
//     final String? title = pullRequest['title'] as String?;
//     if (title == null) {
//       //print('\tPR with no title?');
//       return;
//     }
//     final String? mergedAt = pullRequest['merged_at'] as String?;
//     if (mergedAt == null) {
//       //print('\t$title closed without merging');
//       return;
//     }
//     final DateTime mergeTime = DateTime.parse(mergedAt);
//     if (DateTime.now().difference(mergeTime) > Duration(minutes: 5)) {
//       print('Old commit "$title" merged at $mergedAt');
//       return;
//     }
//     print('New commit "$title" merged at $mergedAt');
//     try {
//       await notificationsClient?.notify(
//         'flutter/flutter Commit',
//         appName: 'Flutter',
//         appIcon: 'https://lh3.googleusercontent.com/Yyiq0kafK7UEUZ43o6NX6PxT-vma-'
//                  'N3z-obKGJMC7y4Ax4fG8TAZOMQJNdLSMk59RnFdpfI_DSPpjJAfZCEW=w1672-h'
//                  '899-rw',
//         body: title,
//       );
//     } catch (e) {
//       print('Failed to notify: $e');
//     }
//   });
// }
