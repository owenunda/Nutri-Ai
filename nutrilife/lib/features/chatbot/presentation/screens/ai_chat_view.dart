import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/state/bot_mood_state.dart';
import '../../../bot/domain/bot_mood.dart';
import '../../../nutrition/data/models/fridge_item_model.dart';
import '../../../premium/presentation/screens/premium_screen.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_session_model.dart';
import '../controllers/chat_view_model.dart';
import '../../data/models/recipe_model.dart';
import '../widgets/answer_actions.dart';
import '../widgets/attached_food_chips.dart';
import '../widgets/bot_message_text.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_quota_blocked_card.dart';
import '../widgets/chat_quota_chip.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_welcome_header.dart';
import '../widgets/rate_limit_chip.dart';
import '../widgets/recipe_card_widget.dart';

class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> with WidgetsBindingObserver {
  late final ChatViewModel _viewModel;
  late final ChatRepository _repository;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = ChatViewModel();
    _repository = ChatRepository();
    DioClient.rateLimit.addListener(_syncBotSleep);
    unawaited(_viewModel.loadActiveSession().then((_) => _scrollToBottom()));
    unawaited(_viewModel.loadQuota());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de segundo plano puede haber cambiado el día.
    if (state == AppLifecycleState.resumed) unawaited(_viewModel.loadQuota());
  }

  Future<void> _openPremium() async {
    final becamePro = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
    if (becamePro == true) unawaited(_viewModel.loadQuota());
  }

  void _syncBotSleep() {
    BotMoodState.instance.hold(
      DioClient.rateLimit.isExhausted ? BotMood.sleeping : BotMood.idle,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DioClient.rateLimit.removeListener(_syncBotSleep);
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
      barrierLabel: context.l10n.chatHistoryBarrierLabel,
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
                onSelect: (session) {
                  Navigator.of(ctx).pop();
                  _handleOpenSession(session.sessionId);
                },
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

  Future<void> _handleOpenSession(int sessionId) async {
    if (_viewModel.isLoading) {
      _showSnack(context.l10n.chatWaitForReply);
      return;
    }
    await _viewModel.openSession(sessionId);
    if (!mounted) return;
    final error = _viewModel.errorMessage;
    if (error != null) {
      _showSnack(error);
      return;
    }
    _scrollToBottom();
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handleSend(String message, List<FridgeItemModel> foods) async {
    await _viewModel.sendMessage(message, foods: foods);
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
        title: Text(
          ctx.l10n.chatDeleteTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(ctx.l10n.chatDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel,
                style: const TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.chatDeleteButton,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
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
                tooltip: context.l10n.chatTooltipHistory,
                onTap: _openDrawer,
              ),
              const Spacer(),
              _TopBarButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: context.l10n.chatTooltipNewChat,
                onTap: _handleNewChat,
              ),
              const SizedBox(width: 8),
              _TopBarButton(
                icon: Icons.delete_outline_rounded,
                tooltip: context.l10n.chatDeleteTitle,
                onTap: _handleDeleteChat,
                color: Colors.red,
              ),
            ],
          ),
        ),
        const RateLimitChip(),
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => ChatQuotaChip(quota: _viewModel.quota),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.messages.isEmpty) {
                return const SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: ChatWelcomeHeader(),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _viewModel.messages.length +
                    (_viewModel.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _viewModel.messages.length) {
                    return const _TypingIndicator();
                  }
                  return _ChatBubble(
                    message: _viewModel.messages[index],
                    recipe: ChatViewModel.recipeBefore(
                      _viewModel.messages,
                      index,
                    ),
                  );
                },
              );
            },
          ),
        ),
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final quota = _viewModel.quota;
            if (_viewModel.isQuotaExhausted && quota != null) {
              return ChatQuotaBlockedCard(
                quota: quota,
                onGoPremium: quota.unlimited ? null : _openPremium,
              );
            }
            return ChatInputField(
              onSend: _handleSend,
              isLoading: _viewModel.isLoading,
            );
          },
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

  /// Receta de la conversación, para el paso a paso de las acciones.
  final RecipeModel? recipe;

  const _ChatBubble({required this.message, this.recipe});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                if (message.attachedFoods.isNotEmpty) ...[
                  if (message.text.isNotEmpty) const SizedBox(height: 10),
                  AttachedFoodChips(foods: message.attachedFoods),
                ],
              ],
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

    final actions = message.actions;
    // Las tarjetas aparecen cuando el bot termina de escribir.
    if (actions != null && message.text.length == message.fullText.length) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedAppear(
            child: _BotTextBubble(message: message),
          ),
          _AnimatedAppear(
            delay: const Duration(milliseconds: 120),
            child: AnswerActions(actions: actions, recipe: recipe),
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
              'assets/images/nutria_saludando.png',
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
              child: BotMessageText(text: message.text),
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
              'assets/images/nutria_pensando2.png',
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
