A command line program that creates a desktop notification on commits to github
repositories.

On Linux, notifications are sent using `package:desktop_notifications`.

Installing the `BurntToast` Powershell module will improve the notifications on
Windows.

```
> Install-Module -Name BurntToast -Scope CurrentUser
```

If `BurntToast` is not available, the fallback is to use WinRT APIs through
Powershell scripts, which may be deprecated in the future.

Installing the `terminal-notifier` program through `brew` will improve the
notifications on macOS.

https://github.com/julienXX/terminal-notifier

```
$ brew install terminal-notifier
```

If `terminal-notifier` is not available, the fallback is to use the
`display notification` AppleScript command.

https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/DisplayNotifications.html
