import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/backend_api.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const String _androidProductId = String.fromEnvironment(
    'GOOGLE_PLAY_PREMIUM_PRODUCT_ID',
    defaultValue: 'gymsupport_premium_monthly',
  );
  static const String _iosProductId = String.fromEnvironment(
    'APP_STORE_PREMIUM_PRODUCT_ID',
    defaultValue: 'gymsupport_premium_monthly',
  );

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  Map<String, dynamic> _subscription = const {};
  bool _loading = true;
  bool _purchasePending = false;
  String? _error;

  bool get _isMobileStore =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  String get _productId => defaultTargetPlatform == TargetPlatform.iOS
      ? _iosProductId
      : _androidProductId;
  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _purchasePending = false;
          _error = error.toString();
        });
      },
    );
    _load();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final subscription = await BackendApi.getSubscription();
      if (!_isMobileStore) {
        if (!mounted) return;
        setState(() {
          _subscription = subscription;
          _loading = false;
          _error = 'Store Billing chỉ khả dụng trên Android hoặc iOS.';
        });
        return;
      }

      final available = await _store.isAvailable();
      if (!available) throw Exception('Cửa hàng ứng dụng hiện không khả dụng.');
      final response = await _store.queryProductDetails({_productId});
      if (response.error != null) throw Exception(response.error!.message);
      if (response.productDetails.isEmpty) {
        throw Exception(
          'Không tìm thấy product $_productId. Hãy kích hoạt subscription trong Store Console.',
        );
      }

      if (!mounted) return;
      setState(() {
        _subscription = subscription;
        _product = response.productDetails.single;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _buy() async {
    final product = _product;
    if (product == null || _purchasePending) return;
    setState(() => _purchasePending = true);
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started && mounted) setState(() => _purchasePending = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _purchasePending = false);
      _showMessage('Không thể mở thanh toán Store: $error');
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;

      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _purchasePending = true);
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        if (mounted) setState(() => _purchasePending = false);
        _showMessage(purchase.error?.message ?? 'Thanh toán không thành công.');
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _purchasePending = false);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await BackendApi.verifyStorePurchase(
            platform: _platform,
            productId: purchase.productID,
            verificationData: purchase.verificationData.serverVerificationData,
            transactionId: purchase.purchaseID,
          );
          if (purchase.pendingCompletePurchase) {
            await _store.completePurchase(purchase);
          }
          final current = await BackendApi.getSubscription();
          if (!mounted) return;
          setState(() {
            _subscription = current;
            _purchasePending = false;
            _error = null;
          });
          _showMessage('Premium đã được kích hoạt!');
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _purchasePending = false;
            _error =
                'Store đã ghi nhận giao dịch nhưng backend chưa xác minh: $error';
          });
        }
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasePending = true);
    try {
      await _store.restorePurchases();
    } catch (error) {
      if (mounted) setState(() => _purchasePending = false);
      _showMessage('Không thể khôi phục giao dịch: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan =
        (_subscription['planName'] ?? _subscription['PlanName'])?.toString() ??
            'Free';
    final isPremium =
        currentPlan.toLowerCase().contains('premium');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // ── Hero Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF003D4D),
                          Color(0xFF001820),
                          AppColors.background,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                        child: Column(
                          children: [
                            // Back button row
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    PhosphorIconsBold.caretLeft,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Crown icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AppTheme.cyanGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                PhosphorIconsBold.crown,
                                color: AppColors.textDark,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'GymSupport Premium',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPremium
                                  ? 'Bạn đang dùng gói $currentPlan'
                                  : 'Mở khoá toàn bộ sức mạnh của AI Coach',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isPremium) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Text(
                                  '✓ ĐANG HOẠT ĐỘNG',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Features ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        _FeatureItem(
                          icon: PhosphorIconsBold.sparkle,
                          iconColor: AppColors.primary,
                          title: 'AI Coach trò chuyện',
                          subtitle:
                              'Hỏi đáp không giới hạn với AI Coach cá nhân',
                        ),
                        _FeatureItem(
                          icon: PhosphorIconsBold.notepad,
                          iconColor: AppColors.blue,
                          title: 'Tạo lịch tập AI',
                          subtitle:
                              'Lịch tập thông minh dựa trên mục tiêu và thể trạng',
                        ),
                        _FeatureItem(
                          icon: PhosphorIconsBold.camera,
                          iconColor: AppColors.orange,
                          title: 'Quét thiết bị gym',
                          subtitle:
                              'Nhận diện máy móc và gợi ý bài tập ngay lập tức',
                        ),
                        _FeatureItem(
                          icon: PhosphorIconsBold.person,
                          iconColor: AppColors.violet,
                          title: 'Kiểm tra tư thế',
                          subtitle:
                              'Phân tích kỹ thuật tập luyện qua camera',
                        ),
                        _FeatureItem(
                          icon: PhosphorIconsBold.trendUp,
                          iconColor: AppColors.success,
                          title: 'Theo dõi tiến bộ nâng cao',
                          subtitle:
                              'Biểu đồ chi tiết, XP và cấp độ cơ bắp',
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Error ─────────────────────────────────────────────────────
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.info,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Product Card ─────────────────────────────────────────────
                if (_product != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _ProductCard(
                        product: _product!,
                        isPending: _purchasePending,
                        onBuy: _buy,
                      ),
                    ),
                  ),

                // ── Restore ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: _purchasePending ? null : _restore,
                      child: const Text(
                        'Khôi phục giao dịch',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }
}

// ── Feature Item ──────────────────────────────────────────────────────────────

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              PhosphorIconsBold.checkCircle,
              color: AppColors.success,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductDetails product;
  final bool isPending;
  final VoidCallback onBuy;

  const _ProductCard({
    required this.product,
    required this.isPending,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'HÀNG THÁNG',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            product.price,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'tự động gia hạn, huỷ bất cứ lúc nào',
            style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isPending ? null : AppTheme.cyanGradient,
                color: isPending ? AppColors.surface2 : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: ElevatedButton(
                onPressed: isPending ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textDark,
                  disabledForegroundColor: AppColors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: isPending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.textSecondary, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Đăng ký Premium ngay',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
