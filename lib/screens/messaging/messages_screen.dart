import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ConversationModel> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getConversations();
      setState(() {
        _conversations = data
            .map((c) => ConversationModel.fromJson(c as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(title: Text(l.messages)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppColors.textSecondary, size: 64),
                      const SizedBox(height: 16),
                      Text(l.noResultsFound,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(
                      color: AppColors.darkSurface, height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final conv = _conversations[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: conv.userAvatar != null
                            ? NetworkImage(conv.userAvatar!)
                            : null,
                        child: conv.userAvatar == null
                            ? Text(
                                conv.userName.isNotEmpty
                                    ? conv.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      title: Text(conv.userName,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.normal)),
                      subtitle: Text(
                        conv.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeAgo(conv.lastMessageAt),
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11)),
                          if (conv.unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${conv.unreadCount}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => context.push('/chat/${conv.userId}',
                          extra: {'name': conv.userName, 'avatar': conv.userAvatar}),
                    );
                  },
                ),
    );
  }
}
