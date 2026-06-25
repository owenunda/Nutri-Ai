import 'recipe_model.dart';

class ChatMessageModel {
  final String fullText;
  String displayedText;
  final bool isUser;
  final DateTime timestamp;
  final RecipeModel? recipeData;

  ChatMessageModel({
    required String text,
    required this.isUser,
    required this.timestamp,
    this.recipeData,
  })  : fullText = text,
        displayedText = text;

  ChatMessageModel.animating({
    required String text,
    required this.isUser,
    required this.timestamp,
  })  : fullText = text,
        displayedText = '',
        recipeData = null;

  String get text => displayedText;
  bool get isRecipe => recipeData != null;
}
