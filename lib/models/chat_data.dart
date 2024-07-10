import 'message.dart';

class ChatData {
  late final String id;
  String title;
  int totalToken;
  late Map<String, dynamic> parameters;
  final List<Message> messageList;
  final String dateCreated;

  ChatData({
    this.title = 'Unknown chat ###',
    this.totalToken = 0,
    this.dateCreated = 'Date',
    required this.messageList,
  }) {
    String dateTimeNow = DateTime.now().toUtc().toString();
    id = dateTimeNow
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll(' ', '');

    parameters = {};

    // .toString()
    // dateCreated = dateTimeNow;
  }
}
