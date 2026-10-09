import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/luxury_badge.dart';
import '../../domain/entities/bill_notice.dart';
import 'insights_section.dart';

/// Upcoming credit card bills parsed from statement / due-reminder SMS.
class BillRemindersCard extends StatelessWidget {
  final List<BillStatus> bills;
  final int index;

  const BillRemindersCard({super.key, required this.bills, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final unpaid = bills.where((b) => b.state != BillPaymentState.paid).length;
    return InsightsSection(
      title: 'Upcoming bills',
      subtitle: unpaid == 0 ? 'All caught up' : '$unpaid to pay',
      icon: AppIcons.bell,
      accent: unpaid == 0 ? AppColors.emeraldLight : AppColors.amber,
      index: index,
      child: Column(children: [for (final b in bills) _BillRow(status: b)]),
    );
  }
}

class _BillRow extends StatelessWidget {
  final BillStatus status;

  const _BillRow({required this.status});

  static final DateFormat _dateFormat = DateFormat('d MMM');

  (String, LuxuryBadgeVariant) _badge() {
    switch (status.state) {
      case BillPaymentState.paid:
        return ('Paid', LuxuryBadgeVariant.emerald);
      case BillPaymentState.minimumPaid:
        return ('Min. paid', LuxuryBadgeVariant.sapphire);
      case BillPaymentState.overdue:
        return ('Overdue', LuxuryBadgeVariant.danger);
      case BillPaymentState.unpaid:
        final days = status.daysUntilDue;
        if (days == null) return ('Due', LuxuryBadgeVariant.gold);
        if (days == 0) return ('Due today', LuxuryBadgeVariant.danger);
        return ('Due in $days d', days <= 3 ? LuxuryBadgeVariant.danger : LuxuryBadgeVariant.gold);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = status.notice;
    final (label, variant) = _badge();
    final title = notice.cardLast4 == null ? notice.bankName : '${notice.bankName} •• ${notice.cardLast4}';
    final due = notice.dueDate == null ? 'Due date not in SMS' : 'Due ${_dateFormat.format(notice.dueDate!)}';
    final minimum = notice.minimumDue == null ? '' : ' • Min ${CurrencyFormatter.format(notice.minimumDue!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.p12),
      child: Row(
        children: [
          const CategoryIconTile(icon: AppIcons.receipt, color: AppColors.amber, size: AppDimensions.avatarSm),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                Text('$due$minimum', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                notice.totalDue == null ? '—' : CurrencyFormatter.format(notice.totalDue!, showDecimals: true),
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: AppDimensions.p4),
              LuxuryBadge(label: label, variant: variant, isSmall: true),
            ],
          ),
        ],
      ),
    );
  }
}
