import 'dart:async';

import 'package:github/github.dart' as g;

class GitCommitWatcher {
  GitCommitWatcher(this.github) : _activityService = g.ActivityService(github);

  final g.GitHub github;
  final g.ActivityService _activityService;
  final Map<String, g.EventPoller> _eventPollers = <String, g.EventPoller>{};

  void watch(
    String org,
    String repo,
    Future<void> Function(String, String?) onCommit,
  ) {
    final g.EventPoller repoEventPoller = _activityService.pollRepositoryEvents(
      g.RepositorySlug(org, repo),
    );
    _eventPollers['$org/$repo'] = repoEventPoller;
    final Stream<g.Event> repoEventStream = repoEventPoller.start(
      onlyNew: true,
      interval: 300, // secconds.
    );
    repoEventStream.listen((g.Event event) async {
      final String? type = event.type;
      if (type == null) {
        return;
      }
      if (type != 'PullRequestEvent') {
        return;
      }
      final Map<String, dynamic>? payload = event.payload;
      if (payload == null) {
        return;
      }
      final String action = payload['action'] as String;
      if (action != 'closed') {
        return;
      }
      final Map<String, dynamic>? pullRequest =
          payload['pull_request'] as Map<String, dynamic>?;
      if (pullRequest == null) {
        return;
      }
      final String? title = pullRequest['title'] as String?;
      if (title == null) {
        return;
      }
      final String? mergedAt = pullRequest['merged_at'] as String?;
      if (mergedAt == null) {
        return;
      }
      final DateTime mergeTime = DateTime.parse(mergedAt);
      if (DateTime.now().difference(mergeTime) > const Duration(minutes: 5)) {
        return;
      }
      final String? htmlUrl = pullRequest['html_url'] as String?;
      print('New commit "$title" merged at $mergedAt: url: $htmlUrl');
      try {
        await onCommit(title, htmlUrl);
      } on Exception catch (e) {
        print('onCommit failed: $e');
      }
    });
  }

  Future<void> unwatch(String org, String repo) async {
    final g.EventPoller? eventPoller = _eventPollers.remove('$org/$repo');
    if (eventPoller == null) {
      return;
    }
    await eventPoller.stop();
  }
}
