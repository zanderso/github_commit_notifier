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
  }) async {}
}
