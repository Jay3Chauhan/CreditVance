import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/shimmer_card_skeleton.dart';
import '../../domain/entities/bill_notice.dart';
import '../../domain/entities/card_milestone.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/recurring_charge.dart';
import '../../domain/entities/spend_analytics.dart';
import '../providers/expense_provider.dart';
import '../widgets/bill_reminders_card.dart';
import '../widgets/card_spend_card.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/milestone_progress_card.dart';
import '../widgets/monthly_trend_card.dart';
import '../widgets/period_selector.dart';
import '../widgets/recurring_charges_card.dart';
import '../widgets/spend_summary_card.dart';
import '../widgets/top_merchants_card.dart';
import '../widgets/tracking_status_banner.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/unusual_spend_card.dart';
import 'add_transaction_screen.dart';
import 'sms_tracking_settings_sheet.dart';
import 'transactions_screen.dart';

/// Spend analytics dashboard built from on-device parsed card SMS.
/// Strictly Zero setState: each section listens to its own Selector slice.
class SpendInsightsScreen extends StatelessWidget {
  const SpendInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.spendsTitle, style: AppTypography.headlineLarge),
            Text(
              AppStrings.spendsSubtitle,
              style: AppTypography.labelSmall.copyWith(color: AppColors.emeraldLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.list, color: AppColors.textPrimary),
            tooltip: 'All transactions',
            onPressed: () => TransactionsScreen.open(context),
          ),
          IconButton(
            icon: const Icon(AppIcons.add, color: AppColors.gold, size: AppDimensions.iconLg),
            tooltip: 'Add spend',
            onPressed: () => AddTransactionScreen.open(context),
          ),
          IconButton(
            icon: const Icon(AppIcons.settings, color: AppColors.textSecondary),
            tooltip: 'Tracking & privacy',
            onPressed: () => SmsTrackingSettingsSheet.show(context),
          ),
        ],
      ),
      body: Selector<ExpenseProvider, ViewState>(
        selector: (_, p) => p.state,
        builder: (context, state, _) {
          if (state.isInitial || state.isLoading) return const _InsightsSkeleton();
          final provider = context.read<ExpenseProvider>();
          if (state.isError) {
            return ErrorStateView(
              message: provider.errorMessage ?? 'Could not load your spends.',
              onRetry: provider.refresh,
            );
          }
          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surfacePrimary,
            onRefresh: provider.refresh,
            child: state.isEmpty ? const _EmptyInsights() : const _InsightsContent(),
          );
        },
      ),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: [
          ShimmerCardSkeleton(height: AppDimensions.chartHeight),
          SizedBox(height: AppDimensions.p16),
          ShimmerListSkeleton(count: 4),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppDimensions.screenPadding,
      children: [
        const TrackingStatusBanner(),
        const SizedBox(height: AppDimensions.p16),
        EmptyStateView(
          title: AppStrings.emptySpends,
          message: AppStrings.emptySpendsPrompt,
          icon: AppIcons.insights,
          buttonLabel: 'Add a spend',
          onButtonPressed: () => AddTransactionScreen.open(context),
        ),
      ],
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppDimensions.screenPadding,
      children: [
        const TrackingStatusBanner(),
        const SizedBox(height: AppDimensions.p16),
        const PeriodSelector(),
        const SizedBox(height: AppDimensions.p16),
        Selector<ExpenseProvider, SpendAnalytics>(
          selector: (_, p) => p.analytics,
          builder: (context, analytics, _) => SpendSummaryCard(analytics: analytics),
        ),
        Selector<ExpenseProvider, List<BillStatus>>(
          selector: (_, p) => p.billStatuses,
          builder: (context, bills, _) =>
              bills.isEmpty ? const SizedBox.shrink() : _Gap(child: BillRemindersCard(bills: bills, index: 1)),
        ),
        Selector<ExpenseProvider, SpendAnalytics>(
          selector: (_, p) => p.analytics,
          builder: (context, analytics, _) => Column(
            children: [
              if (analytics.unusualTransactions.isNotEmpty)
                _Gap(child: UnusualSpendCard(transactions: analytics.unusualTransactions, index: 2)),
              if (analytics.byCategory.isNotEmpty)
                _Gap(child: CategoryBreakdownCard(categories: analytics.byCategory, index: 3)),
              _Gap(child: MonthlyTrendCard(months: analytics.monthlyTrend, index: 4)),
              if (analytics.byCard.isNotEmpty) _Gap(child: CardSpendCard(cards: analytics.byCard, index: 5)),
            ],
          ),
        ),
        Selector<ExpenseProvider, List<MilestoneProgress>>(
          selector: (_, p) => p.milestoneProgress,
          builder: (context, milestones, _) => milestones.isEmpty
              ? const SizedBox.shrink()
              : _Gap(child: MilestoneProgressCard(milestones: milestones, index: 6)),
        ),
        Selector<ExpenseProvider, List<RecurringCharge>>(
          selector: (_, p) => p.recurringCharges,
          builder: (context, charges, _) => charges.isEmpty
              ? const SizedBox.shrink()
              : _Gap(child: RecurringChargesCard(charges: charges, index: 7)),
        ),
        Selector<ExpenseProvider, SpendAnalytics>(
          selector: (_, p) => p.analytics,
          builder: (context, analytics, _) => analytics.topMerchants.isEmpty
              ? const SizedBox.shrink()
              : _Gap(child: TopMerchantsCard(merchants: analytics.topMerchants, index: 8)),
        ),
        Selector<ExpenseProvider, List<CardTransaction>>(
          selector: (_, p) => p.transactions,
          builder: (context, txns, _) => txns.isEmpty
              ? const SizedBox.shrink()
              : _Gap(
                  child: RecentTransactionsCard(
                    transactions: txns.take(5).toList(),
                    index: 9,
                    onViewAll: () {
                      HapticsHelper.light();
                      TransactionsScreen.open(context);
                    },
                  ),
                ),
        ),
        const SizedBox(height: AppDimensions.p32),
      ],
    );
  }
}

class _Gap extends StatelessWidget {
  final Widget child;

  const _Gap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(top: AppDimensions.p16), child: child);
  }
}
