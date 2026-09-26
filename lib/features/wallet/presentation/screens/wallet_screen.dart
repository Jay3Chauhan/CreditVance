import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/context_ext.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptics_helper.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/card_thumb.dart';
import '../../../../core/widgets/countdown_ring.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../catalog/presentation/screens/card_detail_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/user_card.dart';
import '../providers/wallet_provider.dart';
import '../widgets/edit_card_sheet.dart';
import '../widgets/visual_credit_card.dart';
import 'add_card_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final hasCards = wallet.cards.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<WalletProvider>().loadCards(isRefresh: true),
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _WalletAppBar(count: wallet.cards.length, mode: wallet.viewMode, hasCards: hasCards),
            if (wallet.state == ViewState.loading && !hasCards)
              const SliverToBoxAdapter(child: _WalletSkeleton())
            else if (wallet.state == ViewState.error && !hasCards)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateView(
                  message: wallet.errorMessage ?? AppStrings.generalError,
                  onRetry: () => context.read<WalletProvider>().loadCards(),
                ),
              )
            else if (!hasCards)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: AppIcons.cardholder,
                  title: AppStrings.walletEmptyTitle,
                  message: AppStrings.walletEmptyBody,
                  actionLabel: AppStrings.walletAddFirst,
                  onAction: () => AddCardScreen.open(context),
                  secondaryLabel: AppStrings.walletLoadSamples,
                  onSecondary: () => context.read<WalletProvider>().loadSampleCards(),
                ),
              )
            else if (wallet.viewMode == WalletViewMode.stack) ...[
              const SliverToBoxAdapter(child: _CardCarousel()),
              const SliverToBoxAdapter(child: _FocusedCardDetails()),
            ] else
              const _ManageList(),
            SliverToBoxAdapter(child: SizedBox(height: context.navClearance)),
          ],
        ),
      ),
    );
  }
}

class _WalletAppBar extends StatelessWidget {
  final int count;
  final WalletViewMode mode;
  final bool hasCards;

  const _WalletAppBar({required this.count, required this.mode, required this.hasCards});

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    return SliverAppBar(
      pinned: true,
      titleSpacing: gutter,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.walletTitle, style: context.text.headlineMedium),
          if (hasCards) Text('$count card${count == 1 ? '' : 's'} · secured on device', style: context.text.bodySmall),
        ],
      ),
      toolbarHeight: 64,
      actions: [
        if (hasCards)
          AppIconButton(
            icon: mode == WalletViewMode.stack ? AppIcons.viewList : AppIcons.viewStack,
            tooltip: mode == WalletViewMode.stack ? 'Manage & reorder' : 'Card view',
            onPressed: () => context.read<WalletProvider>().toggleViewMode(),
          ),
        const SizedBox(width: 8),
        Padding(
          padding: EdgeInsets.only(right: gutter),
          child: AppIconButton(
            icon: AppIcons.add,
            tooltip: 'Add card',
            onPressed: () => AddCardScreen.open(context),
          ),
        ),
      ],
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter(), vertical: 12),
      child: const Column(
        children: [
          AspectRatio(aspectRatio: AppDimensions.cardAspectRatio, child: SkeletonBox(height: double.infinity, borderRadius: AppDimensions.roundedXl)),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
        ],
      ),
    );
  }
}

class _CardCarousel extends StatefulWidget {
  const _CardCarousel();

  @override
  State<_CardCarousel> createState() => _CardCarouselState();
}

/// Owns the PageController and the flip notifier.
class _CardCarouselState extends State<_CardCarousel> {
  late final PageController _pages;
  final ValueNotifier<bool> _showBack = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: context.read<WalletProvider>().focusedIndex, viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _pages.dispose();
    _showBack.dispose();
    super.dispose();
  }

  void _syncPage(int focused) {
    if (!_pages.hasClients) return;
    final current = _pages.page?.round() ?? focused;
    if (current != focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pages.hasClients) {
          _pages.animateToPage(focused, duration: AppDimensions.mediumAnim, curve: Curves.easeOutCubic);
        }
      });
    }
  }

  Future<void> _toggleReveal(UserCard card) async {
    final wallet = context.read<WalletProvider>();
    final status = await wallet.toggleReveal(card.id);
    if (!mounted) return;
    if (!status.isSuccess) {
      AppToast.vault(context, status, successMessage: '');
    } else if (!wallet.isRevealed(card.id)) {
      _showBack.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wallet = context.watch<WalletProvider>();
    final cards = wallet.cards;
    final revealTotal = context.select<SettingsProvider, int>((s) => s.settings.revealSeconds);
    _syncPage(wallet.focusedIndex);

    return LayoutBuilder(builder: (context, box) {
      final maxCard = box.maxWidth >= 700 ? 420.0 : box.maxWidth * 0.86;
      final cardHeight = maxCard / AppDimensions.cardAspectRatio;

      return Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: cardHeight + 24,
            child: PageView.builder(
              controller: _pages,
              padEnds: true,
              itemCount: cards.length,
              onPageChanged: (i) {
                HapticsHelper.selection();
                _showBack.value = false;
                wallet
                  ..hideSecrets()
                  ..setFocusedIndex(i);
              },
              itemBuilder: (context, i) {
                final card = cards[i];
                final secrets = wallet.secretsFor(card.id);
                return AnimatedBuilder(
                  animation: _pages,
                  builder: (context, child) {
                    double delta = 0;
                    if (_pages.hasClients && _pages.position.haveDimensions) {
                      delta = (_pages.page! - i).abs().clamp(0.0, 1.0);
                    } else {
                      delta = i == wallet.focusedIndex ? 0 : 1;
                    }
                    return Transform.scale(
                      scale: 1 - delta * 0.08,
                      child: Opacity(opacity: 1 - delta * 0.45, child: child),
                    );
                  },
                  child: Center(
                    child: SizedBox(
                      width: maxCard - 12,
                      child: PressableScale(
                        pressedScale: 0.98,
                        onTap: () => _toggleReveal(card),
                        onLongPress: () => _showCardActions(context, card),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _showBack,
                          builder: (context, back, _) => VisualCreditCard(
                              showBack: back && i == wallet.focusedIndex,
                              data: CardFaceData(
                                bankName: card.bankName,
                                cardName: card.cardName,
                                network: card.network,
                                last4: card.last4Digits,
                                nickname: card.nickname,
                                fullNumber: secrets?.pan,
                                expiry: secrets?.expiry,
                                cvv: secrets?.cvv,
                              ),
                              overlay: secrets == null
                                  ? null
                                  : Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: CountdownRing(
                                          remaining: wallet.revealRemaining,
                                          total: revealTotal,
                                          size: 28,
                                          color: Colors.white,
                                          trackColor: Colors.white24,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          _PageDots(count: cards.length, index: wallet.focusedIndex),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter()),
            child: _QuickActions(
              card: wallet.focusedCard!,
              revealed: wallet.isRevealed(wallet.focusedCard!.id),
              onReveal: () => _toggleReveal(wallet.focusedCard!),
              showBack: _showBack,
            ),
          ),
          if (!wallet.isRevealed(wallet.focusedCard!.id))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Tap card to reveal · hold for more', style: context.text.bodySmall!.copyWith(color: c.textTertiary)),
            ),
        ],
      );
    });
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (count < 2) return const SizedBox(height: 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDimensions.mediumAnim,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? c.accent : c.borderStrong,
              borderRadius: AppDimensions.roundedFull,
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final UserCard card;
  final bool revealed;
  final VoidCallback onReveal;
  final ValueNotifier<bool> showBack;

  const _QuickActions({required this.card, required this.revealed, required this.onReveal, required this.showBack});

  Future<void> _run(BuildContext context, Future<VaultStatus> Function() action, String message) async {
    final status = await action();
    if (!context.mounted) return;
    final secs = context.read<SettingsProvider>().settings.clipboardClearSeconds;
    AppToast.vault(context, status, successMessage: '$message Clipboard clears in ${secs}s.');
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.read<WalletProvider>();
    final enabled = card.hasVaultDetails;
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: AppIcons.copy,
            label: 'Number',
            enabled: enabled,
            primary: true,
            onTap: () => _run(context, () => wallet.copyCardNumber(card.id), 'Card number copied.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: AppIcons.lockKey,
            label: 'CVV',
            enabled: enabled,
            onTap: () => _run(context, () => wallet.copyCvv(card.id), 'CVV copied.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: AppIcons.calendar,
            label: 'Expiry',
            enabled: enabled,
            onTap: () => _run(context, () => wallet.copyExpiry(card.id), 'Expiry copied.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: showBack,
            builder: (context, back, _) => _ActionTile(
              icon: revealed ? (back ? AppIcons.card : AppIcons.refresh) : AppIcons.eye,
              label: revealed ? (back ? 'Front' : 'Flip') : AppStrings.reveal,
              enabled: enabled,
              onTap: () {
                if (revealed) {
                  showBack.value = !back;
                } else {
                  onReveal();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.enabled, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = primary ? c.canvas : c.textPrimary;
    return AnimatedOpacity(
      duration: AppDimensions.fastAnim,
      opacity: enabled ? 1 : 0.4,
      child: PressableScale(
        onTap: enabled
            ? onTap
            : () => AppToast.info(context, message: 'No secure details saved for this card. Re-add it with the card number to enable.'),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: primary ? c.textPrimary : c.surface,
            borderRadius: AppDimensions.roundedMd,
            border: Border.all(color: primary ? Colors.transparent : c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: fg),
              const SizedBox(height: 5),
              Text(label, style: context.text.labelSmall!.copyWith(color: fg, letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedCardDetails extends StatelessWidget {
  const _FocusedCardDetails();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = context.select<WalletProvider, UserCard?>((w) => w.focusedCard);
    if (card == null) return const SizedBox.shrink();
    final dateFmt = DateFormat('d MMM');
    final statement = card.nextStatementDate;
    final due = card.estimatedDueDate;
    final daysToDue = due?.difference(DateTime.now()).inDays;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.p20),
          AnimatedSwitcher(
            duration: AppDimensions.mediumAnim,
            child: Column(
              key: ValueKey(card.id),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        label: 'Base return',
                        value: CurrencyFormatter.formatPercentage(card.baseReturnRate),
                        icon: AppIcons.percent,
                        color: c.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBlock(
                        label: 'Annual fee',
                        value: card.annualFee == 0 ? 'Free' : CurrencyFormatter.compact(card.annualFee),
                        icon: AppIcons.receipt,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBlock(
                        label: 'Forex',
                        value: card.forexMarkup == null ? '—' : CurrencyFormatter.formatPercentage(card.forexMarkup!),
                        icon: AppIcons.international,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p12),
                AppSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: AppIcons.calendar,
                        title: statement == null ? 'Add statement day' : 'Next statement',
                        value: statement == null ? 'Set' : dateFmt.format(statement),
                        onTap: () => showEditCardSheet(context, card),
                      ),
                      if (due != null) ...[
                        Divider(height: 1, indent: 52, color: c.border),
                        _InfoRow(
                          icon: AppIcons.bell,
                          title: 'Estimated due date',
                          value: '${dateFmt.format(due)} · ${daysToDue! <= 0 ? 'today' : '$daysToDue days'}',
                          valueColor: daysToDue <= 5 ? c.warning : null,
                        ),
                      ],
                      Divider(height: 1, indent: 52, color: c.border),
                      _InfoRow(
                        icon: card.hasVaultDetails ? AppIcons.shieldFill : AppIcons.shield,
                        iconColor: card.hasVaultDetails ? c.success : c.textTertiary,
                        title: card.hasVaultDetails ? 'Secured in hardware vault' : 'Only last 4 digits saved',
                        value: card.hasVaultDetails ? 'Biometric' : '',
                      ),
                      if (card.cardSlug != null) ...[
                        Divider(height: 1, indent: 52, color: c.border),
                        _InfoRow(
                          icon: AppIcons.gift,
                          title: 'Benefits & reward rules',
                          value: '',
                          onTap: () => CardDetailScreen.open(context, slug: card.cardSlug!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.p12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        label: 'Edit',
                        icon: AppIcons.edit,
                        compact: true,
                        onPressed: () => showEditCardSheet(context, card),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Remove',
                        icon: AppIcons.delete,
                        compact: true,
                        variant: AppButtonVariant.danger,
                        onPressed: () => _confirmDelete(context, card),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.lock, size: 13, color: c.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(AppStrings.zeroKnowledgeNote, style: context.text.bodySmall)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDimensions.mediumAnim, delay: 80.ms);
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatBlock({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppSurface(
      padding: const EdgeInsets.all(12),
      borderRadius: AppDimensions.roundedMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color ?? c.textTertiary),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.numeric(16, color: color ?? c.textPrimary), maxLines: 1),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.title, required this.value, this.valueColor, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? c.textSecondary),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: context.text.bodyMedium!.copyWith(color: c.textPrimary))),
            if (value.isNotEmpty) Text(value, style: context.text.labelMedium!.copyWith(color: valueColor ?? c.textSecondary)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(AppIcons.chevronRight, size: 13, color: c.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, UserCard card) async {
  final ok = await showConfirmSheet(
    context,
    title: 'Remove ${card.nickname.isEmpty ? card.cardName : card.nickname}?',
    message: 'The card and its encrypted details will be permanently removed from this device.',
    confirmLabel: 'Remove card',
    icon: AppIcons.delete,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  final removed = await context.read<WalletProvider>().deleteCard(card.id);
  if (!context.mounted) return;
  if (removed != null) {
    AppToast.success(context, message: 'Card removed');
  } else {
    AppToast.error(context, message: context.read<WalletProvider>().errorMessage ?? 'Couldn\'t remove card');
  }
}

void _showCardActions(BuildContext context, UserCard card) {
  showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: card.nickname.isEmpty ? card.cardName : card.nickname, subtitle: '${card.bankName} •• ${card.last4Digits}'),
          ListTile(
            leading: const Icon(AppIcons.edit, size: 20),
            title: const Text('Edit nickname & statement day'),
            onTap: () {
              Navigator.pop(ctx);
              showEditCardSheet(context, card);
            },
          ),
          if (card.cardSlug != null)
            ListTile(
              leading: const Icon(AppIcons.gift, size: 20),
              title: const Text('View benefits'),
              onTap: () {
                Navigator.pop(ctx);
                CardDetailScreen.open(context, slug: card.cardSlug!);
              },
            ),
          ListTile(
            leading: Icon(AppIcons.delete, size: 20, color: ctx.colors.danger),
            title: Text('Remove card', style: ctx.text.bodyLarge!.copyWith(color: ctx.colors.danger)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, card);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Manage mode: drag to reorder, swipe for edit / remove.
class _ManageList extends StatelessWidget {
  const _ManageList();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wallet = context.watch<WalletProvider>();
    final cards = wallet.cards;
    final gutter = context.gutter();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 12),
            child: Row(
              children: [
                Icon(AppIcons.dragHandle, size: 14, color: c.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Drag to reorder · swipe left for actions', style: context.text.bodySmall),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverReorderableList(
            itemCount: cards.length,
            onReorder: (a, b) {
              HapticsHelper.medium();
              context.read<WalletProvider>().reorder(a, b);
            },
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Transform.scale(
                scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
                child: Material(
                  color: Colors.transparent,
                  elevation: 12 * animation.value,
                  shadowColor: c.shadow,
                  borderRadius: AppDimensions.roundedLg,
                  child: child,
                ),
              ),
            ),
            itemBuilder: (context, i) {
              final card = cards[i];
              return Padding(
                key: ValueKey(card.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _ManageTile(card: card, index: i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ManageTile extends StatelessWidget {
  final UserCard card;
  final int index;

  const _ManageTile({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: AppDimensions.roundedLg,
      child: Slidable(
        key: ValueKey('slide-${card.id}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.44,
          children: [
            SlidableAction(
              onPressed: (_) => showEditCardSheet(context, card),
              icon: AppIcons.edit,
              label: 'Edit',
              backgroundColor: c.surfaceHigh,
              foregroundColor: c.textPrimary,
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, card),
              icon: AppIcons.delete,
              label: 'Remove',
              backgroundColor: c.danger,
              foregroundColor: Colors.white,
            ),
          ],
        ),
        child: AppSurface(
          borderRadius: BorderRadius.zero,
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          onTap: () {
            final wallet = context.read<WalletProvider>();
            wallet.focusCard(card.id);
            wallet.toggleViewMode();
          },
          child: Row(
            children: [
              CardThumb(
                cardName: card.cardName,
                bankName: card.bankName,
                network: card.network,
                last4: card.last4Digits,
                width: 62,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nickname.isEmpty ? card.cardName : card.nickname,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('${card.bankName} •• ${card.last4Digits}', style: context.text.bodySmall),
                  ],
                ),
              ),
              if (card.hasVaultDetails) Icon(AppIcons.shieldFill, size: 15, color: c.success),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(AppIcons.dragHandle, size: 20, color: c.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
