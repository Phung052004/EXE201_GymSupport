import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/app_colors.dart';
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
            verificationData:
                purchase.verificationData.serverVerificationData,
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
            _error = 'Store đã ghi nhận giao dịch nhưng backend chưa xác minh: $error';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = (_subscription['planName'] ?? _subscription['PlanName'])
        ?.toString() ?? 'Free';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Premium'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Gói hiện tại: $currentPlan',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mở AI tạo lịch tập, quét máy, kiểm tra form và phân tích body.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  if (_product != null) _productCard(_product!),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _purchasePending ? null : _restore,
                    child: const Text('Khôi phục giao dịch'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _productCard(ProductDetails product) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(product.description, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Text(
              product.price,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _purchasePending ? null : _buy,
                child: Text(_purchasePending ? 'Đang xử lý...' : 'Đăng ký Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
