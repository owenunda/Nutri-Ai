import 'package:flutter/material.dart';
import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/l10n.dart';
import '../../data/models/chat_session_model.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSessionModel> sessions;
  final bool isLoading;
  final VoidCallback onClose;
  final ValueChanged<ChatSessionModel> onSelect;

  const ChatHistoryDrawer({
    super.key,
    required this.sessions,
    required this.isLoading,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(onClose: onClose),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A6B3F),
                        strokeWidth: 2,
                      ),
                    )
                  : sessions.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: sessions.length,
                          separatorBuilder: (context, i) => const Divider(
                            height: 1,
                            indent: 56,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (_, i) => _SessionTile(
                            session: sessions[i],
                            onTap: () => onSelect(sessions[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DrawerHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.chatHistoryTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C2F31),
                letterSpacing: -0.3,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback onTap;

  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = session.recipeTitle ??
        session.preview ??
        context.l10n.chatSessionFallbackTitle;
    final dateStr = _formatDate(context, session.createdAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: session.active
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                session.recipeTitle != null
                    ? Icons.restaurant_menu_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 18,
                color: session.active
                    ? const Color(0xFF0A6B3F)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2F31),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (session.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.l10n.chatSessionActive,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A6B3F),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');

    if (d == today) return l10n.chatHistoryToday('$hh:$mm');
    if (d == yesterday) return l10n.chatHistoryYesterday('$hh:$mm');

    final languageCode = Localizations.localeOf(context).languageCode;
    return l10n.chatHistoryDate(date.day, shortMonth(date, languageCode));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            context.l10n.chatHistoryEmpty,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
