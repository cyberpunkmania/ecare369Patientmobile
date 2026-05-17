import '../../domain/entities/security_question_entity.dart';

/// Data model for SecurityQuestionDto.
class SecurityQuestionModel extends SecurityQuestionEntity {
  const SecurityQuestionModel({super.questionId, required super.question});

  factory SecurityQuestionModel.fromJson(Map<String, dynamic> json) {
    return SecurityQuestionModel(
      questionId: json['questionId'] as String?,
      question: json['question'] as String? ?? '',
    );
  }

  /// Create from a plain string (for GET /security-questions which returns string[]).
  factory SecurityQuestionModel.fromString(String question) {
    return SecurityQuestionModel(question: question);
  }

  Map<String, dynamic> toJson() {
    return {
      if (questionId != null) 'questionId': questionId,
      'question': question,
    };
  }
}

/// Data model for FetchSecurityQuestionsResponseDto.
class UserSecurityQuestionsModel extends UserSecurityQuestionsEntity {
  const UserSecurityQuestionsModel({
    required super.userId,
    super.tenantId,
    required super.questions,
  });

  factory UserSecurityQuestionsModel.fromJson(Map<String, dynamic> json) {
    return UserSecurityQuestionsModel(
      userId: json['userId'] as String? ?? '',
      tenantId: json['tenantId'] as String?,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SecurityQuestionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tenantId': tenantId,
      'questions': questions
          .map((e) => (e as SecurityQuestionModel).toJson())
          .toList(),
    };
  }
}

/// Model for security question answers in requests.
class SecurityQuestionAnswerModel extends SecurityQuestionAnswer {
  const SecurityQuestionAnswerModel({
    super.questionId,
    super.question,
    required super.answer,
  });

  /// For Flow B (onboarding) - SecurityQuestionRequestItem.
  Map<String, dynamic> toOnboardingJson() {
    return {'question': question ?? '', 'answer': answer};
  }

  /// For Flow C (reactivation) - SecurityAnswerRequestItem.
  Map<String, dynamic> toReactivationJson() {
    return {'questionId': questionId ?? '', 'answer': answer};
  }
}
