import 'package:flutter/material.dart';

import '../widgets/chat_input_field.dart';
import '../widgets/chat_welcome_header.dart';

class AiChatView extends StatelessWidget {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ChatWelcomeHeader(),
          ),
        ),
        // Input Area
        const ChatInputField(),
      ],
    );
  }
}
