import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import 'scan_equipment_screen.dart';

class AiCoachScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;

  const AiCoachScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
  });

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen>
    with TickerProviderStateMixin {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AiChatMessage> messages = [];
  bool _sending = false;
  List<Exercise> _suggestions = const [];

  @override
  void initState() {
    super.initState();

    _loadHistory();
    _loadSuggestions();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final list = await BackendApi.getExercises();
      if (!mounted) return;
      setState(() {
        _suggestions = list.take(6).toList();
      });
    } catch (_) {
      // Keep suggestions empty when backend is unavailable.
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await BackendApi.getAiHistory();
      if (!mounted) return;
      if (history.isEmpty) {
        setState(() {
          messages.add(
            AiChatMessage(
              text:
                  'Hi ${widget.name}! I am your GymSupport AI. Want me to generate a workout plan for you today?',
              isUser: false,
            ),
          );
        });
        return;
      }

      setState(() {
        messages.addAll(
          history.map((item) {
            final role =
                item['role']?.toString().toLowerCase() ??
                item['Role']?.toString().toLowerCase() ??
                '';
            return AiChatMessage(
              text:
                  item['content']?.toString() ??
                  item['Content']?.toString() ??
                  '',
              isUser: role == 'user',
            );
          }),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages.add(
          AiChatMessage(
            text:
                'Hi ${widget.name}! I am your GymSupport AI. Want me to generate a workout plan for you today?',
            isUser: false,
          ),
        );
      });
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() {
      messages.add(AiChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _scrollToBottom();

    messageController.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      final reply = await BackendApi.sendAiCoachMessage(
        message: text,
        email: email,
      );
      if (!mounted) return;
      setState(() {
        messages.add(AiChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI vừa gửi tin nhắn mới')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        messages.add(
          AiChatMessage(
            text: 'Không thể kết nối AI coach: $error',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
        FocusScope.of(context).unfocus();
      }
    }
  }

  Future<void> _openScanEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(SessionStore.emailKey);
    if (!mounted) return;

    final String? mode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI ANALYSIS MODES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 20),
            _buildModeItem(ctx, 'Equipment Scan', 'Identify gym gear & get guides', Icons.fitness_center_rounded, 'equipment_info'),
            _buildModeItem(ctx, 'Form Check', 'Analyze your exercise posture', Icons.accessibility_new_rounded, 'form_check'),
            _buildModeItem(ctx, 'Body Analysis', 'Check body shape & progress', Icons.person_search_rounded, 'body_check'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (!mounted || mode == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanEquipmentScreen(email: email, initialMode: mode)),
    );

    if (!mounted || result == null) return;
    if (result is Map) {
      final text = result['text']?.toString() ?? '';
      final imagePath = result['imagePath']?.toString();
      if (text.trim().isEmpty) return;
      setState(() {
        messages.add(
          AiChatMessage(text: text, isUser: false, imagePath: imagePath),
        );
      });
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm kết quả phân tích vào chat')),
      );
    }
  }

  Widget _buildModeItem(BuildContext context, String title, String sub, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'AI Coach',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 17,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Powered by GymSupport AI',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == messages.length) {
                  return const _TypingIndicator();
                }
                final message = messages[index];

                return AiMessageBubble(message: message);
              },
            ),
          ),

          _ExerciseSuggestions(
            suggestions: _suggestions,
            onTapSuggestion: (exerciseName) {
              if (_sending) return;
              messageController.text = 'Thêm $exerciseName vào workout của tôi';
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              10,
              22,
              MediaQuery.of(context).viewInsets.bottom > 0 ? 14 : 18,
            ),
            child: AiInputBar(
              controller: messageController,
              onSend: sendMessage,
              onCameraTap: _openScanEquipment,
              isSending: _sending,
            ),
          ),
        ],
      ),
    );
  }
}

class AiInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCameraTap;
  final bool isSending;

  const AiInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onCameraTap,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCameraTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: isSending
                    ? 'AI is typing...'
                    : 'E.g. Give me a chest workout...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),

          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.textDark,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;

  const AiMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null && message.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(message.imagePath!),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? AppColors.textDark
                    : Colors.white.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(active: t < 0.33),
                const SizedBox(width: 6),
                _Dot(active: t >= 0.33 && t < 0.66),
                const SizedBox(width: 6),
                _Dot(active: t >= 0.66),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 8 : 6,
      height: active ? 8 : 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.9 : 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ExerciseSuggestions extends StatelessWidget {
  final List<Exercise> suggestions;
  final ValueChanged<String> onTapSuggestion;

  const _ExerciseSuggestions({
    required this.suggestions,
    required this.onTapSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý bài tập',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions
                  .map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.18,
                        ),
                        onPressed: () => onTapSuggestion(exercise.name),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AiChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
  });
}
