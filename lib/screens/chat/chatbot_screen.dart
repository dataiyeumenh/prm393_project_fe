import 'package:flutter/material.dart';

import '../../models/api/chat_dto.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<ChatSessionDTO> _sessions = [];
  List<ChatMessageDTO> _messages = [];
  String? _activeSessionId;

  bool _loadingInit = true;
  bool _loadingMessages = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingInit = true);

    final sessionsResult = await ChatService.getSessions(page: 0, size: 10);
    if (!mounted) return;

    if (sessionsResult.isSuccess && sessionsResult.data != null) {
      _sessions = sessionsResult.data!;
      if (_sessions.isNotEmpty) {
        _activeSessionId = _sessions.first.id;
      }
    }

    if (_activeSessionId == null) {
      final createResult = await ChatService.createSession();
      if (!mounted) return;
      if (createResult.isSuccess && createResult.data != null) {
        _activeSessionId = createResult.data!.id;
        _sessions = [createResult.data!, ..._sessions];
      } else {
        _showError(createResult.error ?? 'Không thể tạo phiên chat');
      }
    }

    await _loadMessages();
    if (!mounted) return;
    setState(() => _loadingInit = false);
  }

  Future<void> _loadMessages({bool showLoader = true}) async {
    final sessionId = _activeSessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    if (showLoader) {
      setState(() => _loadingMessages = true);
    }

    final result = await ChatService.getMessages(sessionId);
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      setState(() => _messages = result.data!);
      _scrollToBottom();
    } else {
      _showError(result.error ?? 'Không thể tải tin nhắn');
    }

    if (showLoader && mounted) {
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _startNewChat() async {
    final result = await ChatService.createSession();
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      setState(() {
        _sessions = [result.data!, ..._sessions];
        _activeSessionId = result.data!.id;
        _messages = [];
      });
      _inputCtrl.clear();
    } else {
      _showError(result.error ?? 'Không thể tạo phiên chat mới');
    }
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final text = _inputCtrl.text.trim();
    final sessionId = _activeSessionId;

    if (text.isEmpty || sessionId == null || sessionId.isEmpty) return;

    FocusScope.of(context).unfocus();
    _inputCtrl.clear();
    setState(() => _sending = true);

    final result = await ChatService.sendMessage(
      sessionId: sessionId,
      content: text,
    );
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final payload = result.data!;
      if (payload.allMessages.isNotEmpty) {
        setState(() => _messages = payload.allMessages);
      } else {
        final next = [..._messages];
        if (payload.userMessage != null) {
          next.add(payload.userMessage!);
        } else {
          next.add(
            ChatMessageDTO(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              role: 'user',
              content: text,
            ),
          );
        }
        if (payload.aiMessage != null) {
          next.add(payload.aiMessage!);
        }
        setState(() => _messages = next);
        if (payload.aiMessage == null) {
          await _loadMessages(showLoader: false);
        }
      }
      _scrollToBottom();
    } else {
      _showError(result.error ?? 'Gửi tin nhắn thất bại');
      _inputCtrl.text = text;
      _inputCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputCtrl.text.length),
      );
    }

    if (mounted) {
      setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('AI Chatbot', style: AppTypography.headingLg),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadingInit ? null : () => _loadMessages(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: _sending ? null : _startNewChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_sessions.isNotEmpty)
            SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                scrollDirection: Axis.horizontal,
                itemCount: _sessions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _sessions[i];
                  final selected = s.id == _activeSessionId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      s.title.trim().isEmpty ? 'Phiên ${i + 1}' : s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onSelected: (_) async {
                      if (selected) return;
                      setState(() {
                        _activeSessionId = s.id;
                        _messages = [];
                      });
                      await _loadMessages();
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: _loadingInit || _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _EmptyChat(onTry: _startNewChat)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _messages.length) {
                        return const _TypingBubble();
                      }

                      final m = _messages[i];
                      return _ChatBubble(message: m);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.accentPinkDeep,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: _sending ? null : _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessageDTO message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? AppColors.ink : AppColors.softCloud;
    final textColor = isUser ? AppColors.onPrimary : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: AppTypography.bodyMd.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.softCloud,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'AI đang trả lời...',
          style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onTry});

  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.softCloud,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 40,
                color: AppColors.accentPinkDeep,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hãy bắt đầu cuộc trò chuyện mới',
              style: AppTypography.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể hỏi về sản phẩm, cách dùng hoặc gợi ý theo nhu cầu của boss.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTry,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Tạo cuộc trò chuyện'),
            ),
          ],
        ),
      ),
    );
  }
}
