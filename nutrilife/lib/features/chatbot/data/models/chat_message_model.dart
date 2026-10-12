import '../../../nutrition/data/models/fridge_item_model.dart';
import 'chat_actions_model.dart';
import 'recipe_model.dart';

class ChatMessageModel {
  final String fullText;
  String displayedText;
  final bool isUser;
  final DateTime timestamp;
  final RecipeModel? recipeData;

  /// Los alimentos que el usuario adjuntó con este mensaje. Viven solo en la
  /// sesión en curso: el historial no repinta mensajes viejos.
  final List<FridgeItemModel> attachedFoods;

  /// Tarjetas interactivas bajo una respuesta del bot (paso a paso, tip).
  final ChatActions? actions;

  ChatMessageModel({
    required String text,
    required this.isUser,
    required this.timestamp,
    this.recipeData,
    this.attachedFoods = const [],
    this.actions,
  })  : fullText = text,
        displayedText = text;

  ChatMessageModel.animating({
    required String text,
    required this.isUser,
    required this.timestamp,
    this.actions,
  })  : fullText = text,
        displayedText = '',
        recipeData = null,
        attachedFoods = const [];

  String get text => displayedText;
  bool get isRecipe => recipeData != null;
}
