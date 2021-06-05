# github_commit_notifier

A command line program that creates a desktop notification on commits to github
repositories.

## Usage

```
$ [GITHUB_TOKEN=<token>] dart bin/main.dart --repos <repo-list>
```

Where `<token>` is a GitHub App or Personal Access token. Supplying the token
through the environment variable is optional, but request quotas will be
smaller without one.

And Where `<repo-list>` is a comma-separated list of GitHub repositories
like `flutter/flutter,flutter/engine,dart-lang/sdk`.

## Implementation

### Linux

On Linux, notifications are sent using `package:desktop_notifications`.

That package uses `package:dbus` to connect to the DBus session. If the
DBus session on your system is listening on an "abstract" address, you'll
need Dart SDK >= 2.14.0-170.0.dev and a `package:dbus` that includes [this
patch](https://github.com/canonical/dbus.dart/pull/246).

### Windows

On Windows this program generates notification by invoking a baked in
PowerShell script.

Installing the `BurntToast` Powershell module will improve the notifications.

```
> Install-Module -Name BurntToast -Scope CurrentUser
```

If `BurntToast` is not available, the fallback is to use WinRT APIs through
PowerShell scripts, which may be deprecated in the future.

### macOS

Installing the `terminal-notifier` ([here](https://github.com/julienXX/terminal-notifier))
program through `brew` will improve the notifications.


```
$ brew install terminal-notifier
```

If `terminal-notifier` is not available, the fallback is to use the
`display notification` [AppleScript command](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/DisplayNotifications.html).

## Support

This program is an unsupported toy/demo.
