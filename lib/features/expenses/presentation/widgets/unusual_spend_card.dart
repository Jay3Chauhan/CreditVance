import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/card_transaction.dart';
import 'insights_section.dart';

/// Highlights debits far above the user's usual ticket size (possible fraud or one-offs).
class UnusualSpendCard extends StatelessWidget {
  final List<CardTransaction> transactions;
  final int index;

  const UnusualSpendCard({super.key, required this.transactions, this.index = 0});

  static final DateFormat _dateFormat = DateFormat('d MMM, h:mm a');

  @override
  Widget build(BuildContext context) {
    return InsightsSection(
      title: 'Unusual spends',
      subtitle: 'Much larger than your typical purchase — verify these',
      icon: AppIcons.warning,
      accent: AppColors.rose,
      index: index,
      child: Column(
        children: [
          for (final t in transactions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.p8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.merchantName, style: AppTypography.titleSmall),
                        Text(
                          '${_dateFormat.format(t.occurredAt)}${t.cardLast4 == null ? '' : ' • •• ${t.cardLast4}'}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(t.amount),
                    style: AppTypography.titleSmall.copyWith(color: AppColors.rose),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
