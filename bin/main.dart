// @dart=2.12

import 'package:args/args.dart';
import 'package:github/github.dart' as g;
import 'package:github_commit_notifier/github_commit_watcher.dart';
import 'package:github_commit_notifier/notifier.dart';

import 'utils.dart';

int main(List<String> arguments) {
  final ArgResults? argResults = parseArguments(arguments);
  if (argResults == null) {
    return 1;
  }
  final List<String> repos = argResults['repos'] as List<String>;

  final g.GitHub github = g.GitHub(
    auth: g.findAuthenticationFromEnvironment(),
    client: NonPersistentClient(),
  );
  final GitCommitWatcher watcher = GitCommitWatcher(github);
  final Notifier notifier = Notifier();

  for (final String repo in repos) {
    final List<String> orgAndName = repo.split('/');
    final String org = orgAndName[0];
    final String name = orgAndName[1];
    watcher.watch(org, name, (String title, String? url) async {
      return notifier.notify(
        appName: 'Flutter',
        title: '$org/$name Commit',
        body: title,
        image: 'bin/logo_flutter_square_large.png',
        url: url,
        onOpen: () async {
          if (url != null) {
            await openUrl(url);
          }
        },
        onClose: () {
          print('Notification closed.');
        },
      );
    });
  }

  return 0;
}

ArgResults? parseArguments(List<String> arguments) {
  final ArgParser argParser = ArgParser()
    ..addMultiOption(
      'repos',
      abbr: 'r',
      help:
          'The repositories to watch, for example flutter/flutter,flutter/engine',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
    );
  final ArgResults argResults = argParser.parse(arguments);
  if (!argResults.wasParsed('repos')) {
    print('Please specify some repositories');
    return null;
  }
  return argResults;
}
