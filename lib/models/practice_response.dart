import 'scenario.dart';

enum EvaluationSource { guided, ai, offline }

extension EvaluationSourceLabel on EvaluationSource {
  String get label => switch (this) {
    EvaluationSource.guided => 'Guided practice',
    EvaluationSource.ai => 'AI coach',
    EvaluationSource.offline => 'Offline coach',
  };
}

class PracticeResponse {
  const PracticeResponse({
    required this.text,
    required this.scoreDelta,
    required this.feedback,
    required this.clarity,
    required this.empathy,
    required this.directness,
    required this.confidence,
    required this.source,
    this.employeeReply,
  });

  factory PracticeResponse.fromChoice(ResponseChoice choice) {
    return PracticeResponse(
      text: choice.text,
      scoreDelta: choice.scoreDelta,
      feedback: choice.feedback,
      clarity: choice.clarity,
      empathy: choice.empathy,
      directness: choice.directness,
      confidence: choice.confidence,
      source: EvaluationSource.guided,
    );
  }

  factory PracticeResponse.fromJson(
    Map<String, dynamic> json, {
    required String text,
    required EvaluationSource source,
  }) {
    int readInt(String key, {required int min, required int max}) {
      final value = json[key];
      if (value is! num) {
        throw const FormatException('Coach response contains invalid scores.');
      }
      return value.round().clamp(min, max);
    }

    final feedback = json['feedback'];
    final employeeReply = json['employee_reply'];
    if (feedback is! String || feedback.trim().isEmpty) {
      throw const FormatException('Coach response is missing feedback.');
    }

    return PracticeResponse(
      text: text,
      scoreDelta: readInt('score_delta', min: -10, max: 14),
      feedback: feedback.trim(),
      clarity: readInt('clarity', min: -2, max: 2),
      empathy: readInt('empathy', min: -2, max: 2),
      directness: readInt('directness', min: -2, max: 2),
      confidence: readInt('confidence', min: -2, max: 2),
      source: source,
      employeeReply: employeeReply is String && employeeReply.trim().isNotEmpty
          ? employeeReply.trim()
          : null,
    );
  }

  final String text;
  final int scoreDelta;
  final String feedback;
  final int clarity;
  final int empathy;
  final int directness;
  final int confidence;
  final EvaluationSource source;
  final String? employeeReply;
}

enum PracticeMode { freestyle, guided }

extension PracticeModeLabel on PracticeMode {
  String get label => switch (this) {
    PracticeMode.freestyle => 'Speak freely',
    PracticeMode.guided => 'Guided choices',
  };
}
