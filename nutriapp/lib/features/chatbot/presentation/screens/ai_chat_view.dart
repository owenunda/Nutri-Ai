import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_session_model.dart';
import '../controllers/chat_view_model.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_welcome_header.dart';
import '../widgets/recipe_card_widget.dart';

class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  late final ChatViewModel _viewModel;
  late final ChatRepository _repository;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel();
    _repository = ChatRepository();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openDrawer() async {
    final notifier = ValueNotifier<({List<ChatSessionModel> sessions, bool loading})>(
      (sessions: [], loading: true),
    );

    unawaited(showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar historial',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        final size = MediaQuery.sizeOf(ctx);
        return Material(
          color: Colors.transparent,
          child: SizedBox(
            width: size.width * 0.78,
            height: size.height,
            child: ValueListenableBuilder(
              valueListenable: notifier,
              builder: (context, value, child) => ChatHistoryDrawer(
                sessions: value.sessions,
                isLoading: value.loading,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    ).whenComplete(notifier.dispose));

    try {
      final sessions = await _repository.getSessions();
      if (mounted) notifier.value = (sessions: sessions, loading: false);
    } catch (_) {
      if (mounted) notifier.value = (sessions: [], loading: false);
    }
  }

  Future<void> _handleSend(String message) async {
    await _viewModel.sendMessage(message);
    _scrollToBottom();
  }

  Future<void> _handleNewChat() async {
    await _viewModel.deleteChat();
  }

  Future<void> _handleDeleteChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar chat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('¿Seguro que quieres eliminar esta conversación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _viewModel.deleteChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              _TopBarButton(
                icon: Icons.menu_rounded,
                tooltip: 'Historial',
                onTap: _openDrawer,
              ),
              const Spacer(),
              _TopBarButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Nueva conversación',
                onTap: _handleNewChat,
              ),
              const SizedBox(width: 8),
              _TopBarButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Eliminar chat',
                onTap: _handleDeleteChat,
                color: Colors.red,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.messages.isEmpty) {
                return const SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: ChatWelcomeHeader(),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _viewModel.messages.length +
                    (_viewModel.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _viewModel.messages.length) {
                    return const _TypingIndicator();
                  }
                  return _ChatBubble(message: _viewModel.messages[index]);
                },
              );
            },
          ),
        ),
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => ChatInputField(
            onSend: _handleSend,
            isLoading: _viewModel.isLoading,
          ),
        ),
      ],
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = const Color(0xFF64748B),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _AnimatedAppear(
        slideFrom: _SlideFrom.right,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0A6B3F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    // Recipe message: text bubble + recipe card staggered
    if (message.isRecipe) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedAppear(
            child: _BotTextBubble(message: message),
          ),
          _AnimatedAppear(
            delay: const Duration(milliseconds: 180),
            child: RecipeCardWidget(recipe: message.recipeData!),
          ),
        ],
      );
    }

    return _AnimatedAppear(
      child: _BotTextBubble(message: message),
    );
  }
}

class _BotTextBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _BotTextBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/nutria_logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.70,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Color(0xFF2C2F31),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/nutria_logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                    final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(100, 116, 139, opacity.clamp(0.3, 1.0)),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appear animation ──────────────────────────────────────────────────────────

enum _SlideFrom { left, right, bottom }

class _AnimatedAppear extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final _SlideFrom slideFrom;

  const _AnimatedAppear({
    required this.child,
    this.delay = Duration.zero,
    this.slideFrom = _SlideFrom.bottom,
  });

  @override
  State<_AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<_AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    final begin = switch (widget.slideFrom) {
      _SlideFrom.right => const Offset(0.06, 0),
      _SlideFrom.left => const Offset(-0.06, 0),
      _SlideFrom.bottom => const Offset(0, 0.06),
    };
    _slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
