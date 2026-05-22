import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController messageController = TextEditingController();

  final List<AiChatMessage> messages = [];

  @override
  void initState() {
    super.initState();

    messages.add(
      AiChatMessage(
        text:
            'Hi ${widget.name}! I am your GymSupport AI. Want me to generate a workout plan for you today?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(AiChatMessage(text: text, isUser: true));

      messages.add(AiChatMessage(text: generateDemoReply(text), isUser: false));
    });

    messageController.clear();
    FocusScope.of(context).unfocus();
  }

  String generateDemoReply(String userMessage) {
    return '''
Dựa trên hồ sơ của bạn:
• Mục tiêu: ${widget.goal}
• Lịch tập: ${widget.schedule}
• BMI: ${widget.bmi.isEmpty ? '--' : widget.bmi}

Gợi ý nhanh:
Hôm nay bạn có thể tập 45 phút gồm khởi động, bài compound chính và 2 bài phụ. Mình sẽ kết nối AI thật ở bước backend sau.
''';
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
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return AiMessageBubble(message: message);
              },
            ),
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

  const AiInputBar({super.key, required this.controller, required this.onSend});

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
                hintText: 'E.g. Give me a chest workout...',
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
            onTap: onSend,
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
        child: Text(
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
      ),
    );
  }
}

class AiChatMessage {
  final String text;
  final bool isUser;

  const AiChatMessage({required this.text, required this.isUser});
}
