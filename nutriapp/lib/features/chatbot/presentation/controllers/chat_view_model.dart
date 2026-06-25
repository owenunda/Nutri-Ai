import 'dart:async';
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
  Timer? _typingTimer;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearMessages() {
    _typingTimer?.cancel();
    _messages.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _typingTimer?.cancel();

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
      if (reply.recipe != null) {
        _messages.add(ChatMessageModel(
          text: reply.text,
          isUser: false,
          timestamp: DateTime.now(),
          recipeData: reply.recipe,
        ));
        notifyListeners();
      } else {
        _startTypewriter(reply.text);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _startTypewriter('Lo siento, ocurrió un error. Intenta de nuevo.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTypewriter(String fullText) {
    final msg = ChatMessageModel.animating(
      text: fullText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    notifyListeners();

    int charIndex = 0;
    // 2 chars per tick at 18ms ≈ 110 chars/s — natural typing feel
    _typingTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      charIndex = (charIndex + 2).clamp(0, fullText.length);
      msg.displayedText = fullText.substring(0, charIndex);
      notifyListeners();
      if (charIndex >= fullText.length) timer.cancel();
    });
  }
}
