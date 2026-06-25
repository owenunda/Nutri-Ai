import 'package:flutter/material.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatViewModel({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessageModel(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(text.trim());
      _messages.add(ChatMessageModel(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _messages.add(ChatMessageModel(
        text: 'Lo siento, ocurrió un error. Intenta de nuevo.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
