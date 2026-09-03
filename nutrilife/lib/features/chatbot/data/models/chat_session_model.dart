class ChatSessionModel {
  final int sessionId;
  final bool active;
  final DateTime createdAt;
  final String? recipeTitle;

  const ChatSessionModel({
    required this.sessionId,
    required this.active,
    required this.createdAt,
    this.recipeTitle,
  });

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    final state = map['conversationState'] as Map<String, dynamic>?;
    final recipe = state?['recipe'] as Map<String, dynamic>?;
    final title = recipe?['title'] as String? ?? recipe?['recipe_title'] as String?;

    return ChatSessionModel(
      sessionId: (map['sessionId'] as num).toInt(),
      active: map['active'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      recipeTitle: (title != null && title.isNotEmpty) ? title : null,
    );
  }
}
