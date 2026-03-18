abstract class PushTokenManager {
  Stream<PushMessageEvent> get messages;

  Future<void> initialize();

  Future<void> onAuthenticated();

  Future<void> onUnauthenticated();
}

class PushMessageEvent {
  const PushMessageEvent({required this.title, required this.body, required this.data, required this.openedApp});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final bool openedApp;
}
