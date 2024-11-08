class MessageContext {
  String query;
  int seed;
  late List<MessageContextData> contextList;

  MessageContext({
    required this.query,
    required this.seed,
    required this.contextList,
  });

  MessageContext.fromMap(Map<String, dynamic> map)
      : query = map['query'],
        seed = map['seed'] {
    var rawList = List.from(map['context_list']);
    contextList = List.generate(
      rawList.length,
      (index) => MessageContextData.fromMap(rawList[index]),
    );
  }

  Map<String, Object> toMap() => {
        'query': query,
        'seed': seed,
        'context_list': contextList.map((context) => context.toMap()).toList(),
      };
}

class MessageContextData {
  final String filename, contextText;
  final double score;
  final int pageNumber;

  MessageContextData({
    required this.filename,
    required this.contextText,
    required this.score,
    required this.pageNumber,
  });

  MessageContextData.fromMap(Map<String, Object?> map)
      : filename = map['filename'] as String,
        contextText = map['context_text'] as String,
        score = map['score'] as double,
        pageNumber = map['page_number'] as int;

  Map<String, Object> toMap() => {
        'filename': filename,
        'context_text': contextText,
        'score': score,
        'page_number': pageNumber,
      };
}
