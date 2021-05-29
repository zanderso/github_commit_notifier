import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'notifier.dart';

class WindowsNotifier implements Notifier {
  WindowsNotifier();

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
    final bool burntToastResult = await _burntToastNotifier(
      appName: appName,
      title: title,
      body: body,
      image: image,
      url: url,
      onOpen: onOpen,
      onClose: onClose,
    );
    if (burntToastResult) {
      return;
    }
    await _fallbackNotifier(
      appName: appName,
      title: title,
      body: body,
      image: image,
      url: url,
      onOpen: onOpen,
      onClose: onClose,
    );
  }

  Future<bool> _burntToastNotifier({
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  }) {
    return _notify(
      _windowsPopupPS1,
      appName: appName,
      title: title,
      body: body,
      image: image,
      url: url,
      onOpen: onOpen,
      onClose: onClose,
    );
  }

  Future<bool> _fallbackNotifier({
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  }) {
    return _notify(
      _fallbackWindowsPopupPS1,
      appName: appName,
      title: title,
      body: body,
      image: image,
      url: url,
      onOpen: onOpen,
      onClose: onClose,
    );
  }

  Future<bool> _notify(
    String scriptBody, {
    required String appName,
    required String title,
    required String body,
    String? image,
    String? url,
    dynamic Function()? onOpen,
    dynamic Function()? onClose,
  }) async {
    io.Directory? tempDir;
    try {
      tempDir = io.Directory.systemTemp.createTempSync(
        'github',
      );
      final io.File scriptFile = io.File(path.join(tempDir.path, 'script.ps1'))
        ..createSync(recursive: true)
        ..writeAsStringSync(scriptBody);
      final io.File? imageFile = image == null ? null : io.File(image).absolute;
      final String imageArg = imageFile == null ? '' : " -image '${imageFile.path}'";
      final String urlArg = url == null ? '' : " -url '$url'";
      final io.ProcessResult result = await io.Process.run(
        'powershell.exe',
        <String>[
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          "${scriptFile.path} -appName '$appName' -headline '$title' -body '$body'$imageArg$urlArg",
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
      print('Error while running powershell script: $e');
      return false;
    } finally {
      try {
        tempDir?.deleteSync(recursive: true);
      } on io.FileSystemException {
        // ignore.
      }
    }
  }
}

const String _windowsPopupPS1 = r'''
param(
  [Parameter(Mandatory=$true)][string]$appName,
  [Parameter(Mandatory=$true)][string]$headline,
  [Parameter(Mandatory=$true)][string]$body,
  [string]$url,
  [string]$image
)

#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
#Install-Module -Name BurntToast -Scope CurrentUser

$ToastHeader = New-BTHeader -Id '001' -Title "$headline"

$Buttons = New-Object Collections.Generic.List[Object]
if ($url -ne '') {
  $OpenButton = New-BTButton -Content 'Open PR' -Arguments "$url"
  $Buttons.add($OpenButton)
}
$CloseButton = New-BTButton -Dismiss
$Buttons.add($CloseButton)

if ($image -eq '') {
  New-BurntToastNotification -Text "$body" -Header $ToastHeader -Button $Buttons
} else {
  New-BurntToastNotification -AppLogo "$image" -Text "$body" -Header $ToastHeader -Button $Buttons
}
''';

const String _fallbackWindowsPopupPS1 = r'''
param(
  [Parameter(Mandatory=$true)][string]$appName,
  [Parameter(Mandatory=$true)][string]$headline,
  [Parameter(Mandatory=$true)][string]$body,
  [string]$url,
  [string]$image = $null
)

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]

if ($image -eq '') {
  $Template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
  #Gets the Template XML so we can manipulate the values
  [xml]$ToastTemplate = ([Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($Template).GetXml())
  [xml]$ToastTemplate = @"
<toast launch="app-defined-string">
  <visual>
    <binding template="ToastText02">
      <text id="1">$headline</text>
      <text id="2">$body</text>
    </binding>
  </visual>
</toast>
"@
} else {
  $Template = [Windows.UI.Notifications.ToastTemplateType]::ToastImageAndText02
  #Gets the Template XML so we can manipulate the values
  [xml]$ToastTemplate = ([Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($Template).GetXml())
  [xml]$ToastTemplate = @"
<toast launch="app-defined-string">
  <visual>
    <binding template="ToastImageAndText02">
      <image id="1" src="$image" alt="image1"/>
      <text id="1">$headline</text>
      <text id="2">$body</text>
    </binding>
  </visual>
</toast>
"@
}

$ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$ToastXml.LoadXml($ToastTemplate.OuterXml)

$toast = [Windows.UI.Notifications.ToastNotification]::new($ToastXml)

$notify = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appName)
$notify.Show($toast)
''';
