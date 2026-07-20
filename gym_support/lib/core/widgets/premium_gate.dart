import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../services/backend_api.dart';
import '../services/session_store.dart';
import '../../features/profile/screens/subscription_screen.dart';

/// Call [PremiumGate.check] before any premium feature.
/// Returns true if user is premium (proceed), false if not (gate shown).
///
/// Example:
/// ```dart
/// if (!await PremiumGate.check(context)) return;
/// // proceed with premium feature
/// ```
class PremiumGate {
  PremiumGate._();

  static Future<bool> check(BuildContext context) async {
    final premium = await _isPremiumLive();
    if (premium) return true;
    if (!context.mounted) return false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PremiumSheet(),
    );
    // Re-check after sheet closes (user may have just subscribed)
    return _isPremiumLive();
  }

  /// Hỏi thẳng backend (nguồn chân lý) thay vì chỉ tin cache local — vì gói
  /// Premium giờ có thể được mua qua website (PayOS), không đi qua màn hình
  /// Subscription trong app nên cache local có thể chưa từng được cập nhật.
  /// Nếu gọi mạng lỗi (vd offline) thì fallback về cache đã lưu gần nhất.
  static Future<bool> _isPremiumLive() async {
    try {
      final subscription = await BackendApi.getSubscription();
      if (subscription.isNotEmpty) {
        final flag = subscription['isPremium'] ?? subscription['IsPremium'];
        final isPremium = flag is bool ? flag : false;
        await SessionStore.savePremiumStatus(isPremium);
        return isPremium;
      }
    } catch (_) {
      // Lỗi mạng — rơi xuống cache bên dưới.
    }
    return SessionStore.isPremium();
  }
}

class _PremiumSheet extends StatelessWidget {
  const _PremiumSheet();

  static const _features = [
    (PhosphorIconsBold.robot,      AppColors.primary,  'AI Coach Chat',          'Trò chuyện không giới hạn với AI Coach'),
    (PhosphorIconsBold.sparkle,    AppColors.violet,   'Tạo lịch tập AI',        'AI tự động tạo lịch tập cá nhân hóa'),
    (PhosphorIconsBold.chartLine,  AppColors.blue,     'Phân tích tiến trình',   'Báo cáo chuyên sâu về cơ bắp & sức mạnh'),
    (PhosphorIconsBold.camera,     AppColors.orange,   'Scan thiết bị',          'Nhận diện thiết bị bằng camera AI'),
    (PhosphorIconsBold.lightning,  AppColors.gold,     'Ưu tiên hỗ trợ',         'Hỗ trợ ưu tiên từ đội ngũ GymSupport'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                // Crown icon with glow
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyanGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.40),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIconsBold.crown,
                      color: AppColors.textDark, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tính năng Premium',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nâng cấp để mở khóa toàn bộ sức mạnh của AI Coach',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Feature list
                ...(_features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: f.$2.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.$1, color: f.$2, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.$3, style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13, fontWeight: FontWeight.w800,
                              height: 1,
                            )),
                            const SizedBox(height: 2),
                            Text(f.$4, style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            )),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIconsBold.checkCircle,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ))),
                const SizedBox(height: 8),
                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cyanGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.textDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsBold.crown, size: 18),
                          SizedBox(width: 8),
                          Text('Nâng cấp Premium',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Skip button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Để sau',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
