import 'message.dart';

class ChatData {
  late final String id;
  String title;
  int totalToken;
  late Map<String, dynamic> parameters;
  List<bool> usePreprompt = [false];
  String? prePrompt;
  List<bool> useChatConversationContext = [true];
  final List<Message> messageList;
  late final String dateCreated;
  late final List<Map<String, String>> knowledges;

  ChatData({
    this.title = 'Unknown chat ###',
    this.totalToken = 0,
    required this.messageList,
  }) {
    String dateTimeNow = DateTime.now().toUtc().toString();
    id = dateTimeNow
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll(' ', '');

    parameters = {};

    dateCreated = dateTimeNow.substring(0, dateTimeNow.indexOf(' '));

    knowledges = [];
  }
}
