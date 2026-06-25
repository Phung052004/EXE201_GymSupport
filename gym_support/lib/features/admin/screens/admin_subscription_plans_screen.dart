import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/backend_api.dart';

class AdminSubscriptionPlansScreen extends StatefulWidget {
  final bool embedded;
  const AdminSubscriptionPlansScreen({super.key, this.embedded = false});

  @override
  State<AdminSubscriptionPlansScreen> createState() =>
      _AdminSubscriptionPlansScreenState();
}

class _AdminSubscriptionPlansScreenState
    extends State<AdminSubscriptionPlansScreen> {
  List<Map<String, dynamic>> _plans = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final plans = await BackendApi.adminGetAllPlans();
    if (!mounted) return;
    setState(() {
      _plans   = plans;
      _loading = false;
    });
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final nameCtrl     = TextEditingController(text: plan?['name']?.toString() ?? '');
    final priceCtrl    = TextEditingController(
        text: plan?['price']?.toString() ?? '');
    final durationCtrl = TextEditingController(
        text: plan?['durationMonths']?.toString() ?? '1');
    var isActive       = plan?['isActive'] as bool? ?? true;
    var saving         = false;
    final isEdit       = plan != null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            isEdit ? 'Sửa gói' : 'Tạo gói mới',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(controller: nameCtrl, label: 'Tên gói'),
                const SizedBox(height: 14),
                _Field(
                  controller: priceCtrl,
                  label: 'Giá (VND)',
                  inputType: const TextInputType.numberWithOptions(decimal: true),
                  formatter: FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: durationCtrl,
                  label: 'Thời hạn (tháng)',
                  inputType: TextInputType.number,
                  formatter: FilteringTextInputFormatter.digitsOnly,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Kích hoạt',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name     = nameCtrl.text.trim();
                      final price    = double.tryParse(priceCtrl.text) ?? 0;
                      final duration = int.tryParse(durationCtrl.text) ?? 1;
                      if (name.isEmpty || price < 0 || duration < 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kiểm tra lại thông tin')),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      bool ok;
                      if (isEdit) {
                        ok = await BackendApi.adminUpdatePlan(
                          id: plan['id']?.toString() ?? '',
                          name: name,
                          durationMonths: duration,
                          price: price,
                          isActive: isActive,
                        );
                      } else {
                        ok = await BackendApi.adminCreatePlan(
                          name: name,
                          durationMonths: duration,
                          price: price,
                          isActive: isActive,
                        );
                      }
                      if (!mounted || !ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _load();
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Có lỗi xảy ra'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
              child: Text(
                isEdit ? 'Lưu' : 'Tạo',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa gói?',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Xóa gói "${plan['name']}"?\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await BackendApi.adminDeletePlan(
        plan['id']?.toString() ?? '');
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không thể xóa'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Gói Subscription',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textDark,
        child: const Icon(PhosphorIconsBold.plus),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _plans.isEmpty
              ? const Center(
                  child: Text('Chưa có gói nào',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _plans.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final plan    = _plans[i];
                      final name    = plan['name']?.toString() ?? '';
                      final price   = (plan['price'] as num?)?.toDouble() ?? 0;
                      final months  = (plan['durationMonths'] as num?)?.toInt() ?? 0;
                      final active  = plan['isActive'] as bool? ?? false;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: active
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(name,
                                          style: AppTheme.titleMedium),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColors.success
                                                  .withValues(alpha: 0.15)
                                              : AppColors.textTertiary
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Text(
                                          active ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: active
                                                ? AppColors.success
                                                : AppColors.textTertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_fmtPrice(price)}  ·  $months tháng',
                                    style: AppTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showPlanDialog(plan: plan),
                              icon: const Icon(PhosphorIconsRegular.pencilSimple,
                                  color: AppColors.textSecondary, size: 20),
                            ),
                            IconButton(
                              onPressed: () => _deletePlan(plan),
                              icon: const Icon(PhosphorIconsRegular.trash,
                                  color: AppColors.danger, size: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  static String _fmtPrice(double price) {
    if (price <= 0) return 'Miễn phí';
    final n = price.toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf đ';
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType inputType;
  final TextInputFormatter? formatter;

  const _Field({
    required this.controller,
    required this.label,
    this.inputType = TextInputType.text,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: formatter != null ? [formatter!] : null,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
