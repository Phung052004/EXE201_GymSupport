import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:gym_support/core/widgets/premium_gate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/exercise.dart';
import 'generate_plan_screen.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _sending = false;
  List<Exercise> _suggestions = const [];

  static const _quickPrompts = [
    'Gợi ý bài tập hôm nay',
    'Cách tăng cơ hiệu quả',
    'Bài tập giảm mỡ bụng',
    'Lịch tập 3 buổi/tuần',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final list = await BackendApi.getExercises();
      if (!mounted) return;
      setState(() => _suggestions = list.take(6).toList());
    } catch (_) {}
  }

  static const _maxHistoryMessages = 20;

  Future<void> _loadHistory() async {
    try {
      final history = await BackendApi.getAiHistory();
      if (!mounted) return;
      if (history.isEmpty) {
        setState(() {
          _messages.add(AiChatMessage(
            text:
                'Xin chào ${widget.name}! 👋\n\nMình là AI Coach của GymSupport. Hãy hỏi mình bất cứ điều gì về luyện tập nhé!',
            isUser: false,
          ));
        });
        return;
      }
      // Only load last N messages to avoid context overflow on AI
      final recent = history.length > _maxHistoryMessages
          ? history.sublist(history.length - _maxHistoryMessages)
          : history;
      setState(() {
        if (history.length > _maxHistoryMessages) {
          _messages.add(const AiChatMessage(
            text: '— Chỉ hiển thị 20 tin nhắn gần nhất —',
            isUser: false,
            isSystemNote: true,
          ));
        }
        _messages.addAll(recent.map((item) {
          final role = item['role']?.toString().toLowerCase() ??
              item['Role']?.toString().toLowerCase() ??
              '';
          return AiChatMessage(
            text: item['content']?.toString() ??
                item['Content']?.toString() ??
                '',
            isUser: role == 'user',
          );
        }));
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiChatMessage(
          text:
              'Xin chào ${widget.name}! 👋\n\nMình là AI Coach của GymSupport. Hãy hỏi mình bất cứ điều gì về luyện tập nhé!',
          isUser: false,
        ));
      });
    }
  }

  Future<void> _clearChat() async {
    try {
      await BackendApi.clearAiHistory();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.add(AiChatMessage(
        text:
            'Xin chào ${widget.name}! 👋\n\nMình là AI Coach của GymSupport. Hãy hỏi mình bất cứ điều gì về luyện tập nhé!',
        isUser: false,
      ));
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    if (!await PremiumGate.check(context)) return;

    setState(() {
      _messages.add(AiChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _scrollToBottom();
    _messageController.clear();

    // If user asks to generate a plan — switch to Generate tab
    if (_looksLikePlanGenerationRequest(text)) {
      if (!mounted) return;
      setState(() {
        _messages.add(const AiChatMessage(
          text: 'Mình đã chuyển bạn sang tab "Tạo lịch AI". Hãy chọn các tuỳ chọn và bấm Tạo lịch tập nhé! 🏋️',
          isUser: false,
        ));
        _sending = false;
      });
      _scrollToBottom();
      FocusScope.of(context).unfocus();
      // Switch to Generate tab
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _tabController.animateTo(1);
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      final result = await BackendApi.sendAiCoachMessageDetailed(
          message: text, email: email);
      var reply =
          result['response']?.toString() ?? 'Mình có thể giúp gì thêm?';
      final rawSuggestions = result['suggestions'];
      final suggestions = rawSuggestions is List
          ? rawSuggestions
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (suggestions.isNotEmpty) {
        try {
          await BackendApi.applyAiSuggestions({'suggestions': suggestions});
          reply = '✅ Đã lưu thay đổi vào lịch tập của bạn.\n\n$reply';
        } catch (_) {
          reply =
              '$reply\n\n🔒 Nâng cấp Premium để lưu và áp dụng lịch tập trực tiếp.';
        }
      }
      if (!mounted) return;
      setState(() => _messages.add(AiChatMessage(text: reply, isUser: false)));
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      final errStr = error.toString().toLowerCase();
      final isContextOverflow = errStr.contains('context') ||
          errStr.contains('token') ||
          errStr.contains('limit') ||
          errStr.contains('too long') ||
          errStr.contains('413') ||
          errStr.contains('400');
      setState(() {
        _messages.add(AiChatMessage(
          text: isContextOverflow
              ? 'Cuộc trò chuyện quá dài. Nhấn nút xóa lịch sử (🗑) để bắt đầu hội thoại mới.'
              : 'Không thể kết nối. Vui lòng thử lại sau.',
          isUser: false,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        FocusScope.of(context).unfocus();
      }
    }
  }

  bool _looksLikePlanGenerationRequest(String text) {
    final v = text.toLowerCase();
    final asksForPlan = v.contains('lịch tập') ||
        v.contains('workout plan') ||
        v.contains('tạo lịch') ||
        v.contains('generate plan');
    final createIntent = v.contains('tạo') ||
        v.contains('lên') ||
        v.contains('generate') ||
        v.contains('build');
    return asksForPlan && createIntent;
  }

  Future<void> _openScanEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(SessionStore.emailKey);
    if (!mounted) return;

    final String? mode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Chế độ phân tích AI', style: AppTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildModeItem(ctx, 'Quét thiết bị',
                'Nhận diện dụng cụ gym',
                PhosphorIconsBold.barbell, 'equipment_info'),
            const SizedBox(height: 10),
            _buildModeItem(ctx, 'Kiểm tra tư thế',
                'Phân tích kỹ thuật tập',
                PhosphorIconsBold.person, 'form_check'),
            const SizedBox(height: 10),
            _buildModeItem(ctx, 'Phân tích cơ thể',
                'Đánh giá vóc dáng',
                PhosphorIconsBold.magnifyingGlass, 'body_check'),
          ],
        ),
      ),
    );

    if (!mounted || mode == null) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              ScanEquipmentScreen(email: email, initialMode: mode)),
    );

    if (!mounted || result == null) return;
    if (result is Map) {
      final text = result['text']?.toString() ?? '';
      final imagePath = result['imagePath']?.toString();
      if (text.trim().isEmpty) return;
      setState(() => _messages
          .add(AiChatMessage(text: text, isUser: false, imagePath: imagePath)));
      _scrollToBottom();
    }
  }

  Widget _buildModeItem(BuildContext ctx, String title, String sub,
      IconData icon, String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(ctx, value),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(color: AppColors.surface2),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(sub, style: AppTheme.caption),
                  ],
                ),
              ),
              const Icon(PhosphorIconsBold.caretRight,
                  color: AppColors.textSecondary, size: 14),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.violet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(PhosphorIconsBold.robot,
                        color: AppColors.textDark, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Coach', style: AppTheme.headlineMedium),
                        Text(
                          'Powered by GymSupport AI',
                          style: TextStyle(
                            color: AppColors.primary, fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Xóa lịch sử chat',
                              style: TextStyle(color: AppColors.textPrimary)),
                          content: const Text(
                            'Xóa toàn bộ tin nhắn trong phiên này để tránh lỗi vượt giới hạn AI?',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Huỷ',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _clearChat();
                              },
                              child: const Text('Xóa',
                                  style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(PhosphorIconsBold.trash,
                        color: AppColors.textSecondary, size: 20),
                    tooltip: 'Xóa lịch sử chat',
                  ),
                ],
              ),
            ),

            // ── Tab Bar ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.outline),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: AppTheme.cyanGradient,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
                  labelColor: AppColors.textDark,
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Chat'),
                    Tab(text: 'Tạo lịch AI'),
                  ],
                ),
              ),
            ),

            // ── Tab Body ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Chat Tab ────────────────────────────────────────────────
                  Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (_sending && index == _messages.length) {
                              return const _TypingIndicator();
                            }
                            return _AiMessageBubble(
                                message: _messages[index]);
                          },
                        ),
                      ),
                      if (_messages.length <= 1) _buildQuickPrompts(),
                      _buildInputBar(),
                    ],
                  ),

                  // ── Generate Tab ────────────────────────────────────────────
                  GeneratePlanScreen(
                    goal: widget.goal,
                    embedded: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Gợi ý nhanh',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12, fontWeight: FontWeight.w700,
              )),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () {
                _messageController.text = _quickPrompts[i];
                _sendMessage();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.outlineStrong),
                ),
                child: Text(
                  _quickPrompts[i],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.only(left: 16, right: 6, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.outlineStrong),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _openScanEquipment,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsBold.camera,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1, maxLines: 4,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText:
                      _sending ? 'AI đang soạn...' : 'Hỏi AI Coach của bạn...',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _sending
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark),
                      )
                    : const Icon(PhosphorIconsBold.paperPlaneTilt,
                        color: AppColors.textDark, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;
  const _AiMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystemNote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message.text,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser)
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.violet]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsBold.robot,
                    color: AppColors.textDark, size: 16),
              ),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imagePath?.isNotEmpty == true) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(message.imagePath!),
                          width: double.infinity, height: 160,
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
                            : AppColors.textPrimary,
                        fontSize: 14, height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.violet]),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsBold.robot,
                  color: AppColors.textDark, size: 16),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.outline),
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final t = _ctrl.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(active: t < 0.33),
                      const SizedBox(width: 5),
                      _Dot(active: t >= 0.33 && t < 0.66),
                      const SizedBox(width: 5),
                      _Dot(active: t >= 0.66),
                    ],
                  );
                },
              ),
            ),
          ],
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
        color: AppColors.primary.withValues(alpha: active ? 1.0 : 0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────────────────────────

class AiChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final bool isSystemNote;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.isSystemNote = false,
  });
}
