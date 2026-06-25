import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/backend_api.dart';

class AdminUserSubscriptionsScreen extends StatefulWidget {
  final bool embedded;
  const AdminUserSubscriptionsScreen({super.key, this.embedded = false});

  @override
  State<AdminUserSubscriptionsScreen> createState() =>
      _AdminUserSubscriptionsScreenState();
}

class _AdminUserSubscriptionsScreenState
    extends State<AdminUserSubscriptionsScreen> {
  List<Map<String, dynamic>> _subs = const [];
  List<Map<String, dynamic>> _filtered = const [];
  bool _loading = true;
  String _filter = 'all'; // all | active | expired | cancelled

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final subs = await BackendApi.adminGetUserSubscriptions();
    if (!mounted) return;
    setState(() {
      _subs     = subs;
      _loading  = false;
    });
    _applyFilter(_filter);
  }

  void _applyFilter(String filter) {
    setState(() {
      _filter = filter;
      if (filter == 'all') {
        _filtered = _subs;
      } else {
        _filtered = _subs
            .where((s) =>
                (s['status'] as String? ?? '').toLowerCase() ==
                filter)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount    = _subs.where((s) => (s['status'] as String? ?? '').toLowerCase() == 'active').length;
    final expiredCount   = _subs.where((s) => (s['status'] as String? ?? '').toLowerCase() == 'expired').length;
    final cancelledCount = _subs.where((s) => (s['status'] as String? ?? '').toLowerCase() == 'cancelled').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Đăng ký người dùng',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Summary row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label: 'Tất cả',
                        count: _subs.length,
                        selected: _filter == 'all',
                        color: AppColors.primary,
                        onTap: () => _applyFilter('all'),
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Active',
                        count: activeCount,
                        selected: _filter == 'active',
                        color: AppColors.success,
                        onTap: () => _applyFilter('active'),
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Expired',
                        count: expiredCount,
                        selected: _filter == 'expired',
                        color: AppColors.textTertiary,
                        onTap: () => _applyFilter('expired'),
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        label: 'Huỷ',
                        count: cancelledCount,
                        selected: _filter == 'cancelled',
                        color: AppColors.danger,
                        onTap: () => _applyFilter('cancelled'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Không có đăng ký nào',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, i) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _SubCard(sub: _filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : AppColors.outline,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? color : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final Map<String, dynamic> sub;

  const _SubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final email       = sub['userEmail']?.toString() ?? '';
    final name        = sub['userName']?.toString() ?? '';
    final planName    = sub['planName']?.toString() ?? '';
    final status      = (sub['status']?.toString() ?? '').toLowerCase();
    final daysLeft    = (sub['daysRemaining'] as num?)?.toInt() ?? 0;
    final endDateRaw  = sub['endDate']?.toString();
    final startDateRaw = sub['startDate']?.toString();

    final endDate   = endDateRaw != null ? _fmtDate(endDateRaw) : '--';
    final startDate = startDateRaw != null ? _fmtDate(startDateRaw) : '--';

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'expired':
        statusColor = AppColors.textTertiary;
        break;
      case 'cancelled':
        statusColor = AppColors.danger;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final statusLabel = status == 'active'
        ? 'Active'
        : status == 'expired'
            ? 'Hết hạn'
            : status == 'cancelled'
                ? 'Đã huỷ'
                : status;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: status == 'active'
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar initials
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty
                        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                        : (email.isNotEmpty ? email[0].toUpperCase() : '?'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      Text(name,
                          style: AppTheme.titleMedium,
                          overflow: TextOverflow.ellipsis),
                    Text(
                      email.isNotEmpty ? email : 'Chưa có email',
                      style: AppTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outline, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.crown,
                  color: AppColors.gold, size: 14),
              const SizedBox(width: 6),
              Text(planName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (status == 'active')
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.clockCountdown,
                        color: AppColors.primary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$daysLeft ngày còn lại',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Bắt đầu: $startDate',
                  style: AppTheme.caption),
              const SizedBox(width: 12),
              Text('Hết hạn: $endDate',
                  style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
