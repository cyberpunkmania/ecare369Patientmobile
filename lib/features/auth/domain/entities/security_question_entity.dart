import 'package:equatable/equatable.dart';

/// Represents a security question (used in onboarding and reactivation).
class SecurityQuestionEntity extends Equatable {
  /// Question ID (only present for user-specific questions in Flow C).
  final String? questionId;

  /// The question text.
  final String question;

  const SecurityQuestionEntity({this.questionId, required this.question});

  @override
  List<Object?> get props => [questionId, question];
}

/// Response from fetching user's security questions (Flow C).
class UserSecurityQuestionsEntity extends Equatable {
  final String userId;
  final String? tenantId;
  final List<SecurityQuestionEntity> questions;

  const UserSecurityQuestionsEntity({
    required this.userId,
    this.tenantId,
    required this.questions,
  });

  @override
  List<Object?> get props => [userId, tenantId, questions];
}

/// A security question with the user's answer (for setup/activation requests).
class SecurityQuestionAnswer extends Equatable {
  /// For Flow C (reactivation) - the question ID.
  final String? questionId;

  /// For Flow B (onboarding) - the question text.
  final String? question;

  /// The user's answer.
  final String answer;

  const SecurityQuestionAnswer({
    this.questionId,
    this.question,
    required this.answer,
  });

  /// Create for Flow B (onboarding) with question text.
  factory SecurityQuestionAnswer.forOnboarding({
    required String question,
    required String answer,
  }) {
    return SecurityQuestionAnswer(question: question, answer: answer);
  }

  /// Create for Flow C (reactivation) with question ID.
  factory SecurityQuestionAnswer.forReactivation({
    required String questionId,
    required String answer,
  }) {
    return SecurityQuestionAnswer(questionId: questionId, answer: answer);
  }

  @override
  List<Object?> get props => [questionId, question, answer];
}
