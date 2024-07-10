abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  Future<String?> generateText(
      String url, String prompt, Map<String, dynamic> parameters);
}
