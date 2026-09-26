import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/card_formatter.dart';
import '../../../../core/widgets/network_logo_widget.dart';

/// Data needed to paint a card face.
class CardFaceData {
  final String bankName;
  final String cardName;
  final String network;
  final String last4;
  final String? nickname;
  final String? fullNumber;
  final String? expiry;
  final String? cvv;

  const CardFaceData({
    required this.bankName,
    required this.cardName,
    required this.network,
    required this.last4,
    this.nickname,
    this.fullNumber,
    this.expiry,
    this.cvv,
  });

  bool get isRevealed => fullNumber != null;
}

/// Flippable metal card. Front shows the PAN, back shows the CVV.
class VisualCreditCard extends StatefulWidget {
  final CardFaceData data;
  final bool showBack;
  final Widget? overlay;
  final double elevation;

  const VisualCreditCard({
    super.key,
    required this.data,
    this.showBack = false,
    this.overlay,
    this.elevation = 1,
  });

  @override
  State<VisualCreditCard> createState() => _VisualCreditCardState();
}

/// Owns only the flip animation controller.
class _VisualCreditCardState extends State<VisualCreditCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: AppDimensions.slowAnim,
    value: widget.showBack ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant VisualCreditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBack != widget.showBack) {
      widget.showBack ? _flip.forward() : _flip.reverse();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = CardSkin.resolve(cardName: widget.data.cardName, bankName: widget.data.bankName);
    return AspectRatio(
      aspectRatio: AppDimensions.cardAspectRatio,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_flip.value);
          final angle = t * math.pi;
          final isBack = angle > math.pi / 2;
          final face = isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _CardBack(data: widget.data, skin: skin),
                )
              : _CardFront(data: widget.data, skin: skin);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: _CardShell(
              skin: skin,
              elevation: widget.elevation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  face,
                  if (widget.overlay != null && !isBack) widget.overlay!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final CardSkin skin;
  final Widget child;
  final double elevation;

  const _CardShell({required this.skin, required this.child, required this.elevation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final radius = BorderRadius.circular(box.maxWidth * 0.05);
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: skin.gradient,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: skin.colors.last.withValues(alpha: 0.55 * elevation),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                    spreadRadius: -10,
                  ),
                ]
              : null,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft specular sheen.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -1.1),
                  radius: 1.4,
                  colors: [Colors.white.withValues(alpha: 0.13), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              right: -box.maxWidth * 0.25,
              bottom: -box.maxWidth * 0.35,
              child: Container(
                width: box.maxWidth * 0.8,
                height: box.maxWidth * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: skin.accent.withValues(alpha: 0.08), width: box.maxWidth * 0.06),
                ),
              ),
            ),
            child,
          ],
        ),
      );
    });
  }
}

class _CardFront extends StatelessWidget {
  final CardFaceData data;
  final CardSkin skin;

  const _CardFront({required this.data, required this.skin});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final pad = w * 0.065;
      final number = data.fullNumber != null
          ? CardFormatter.formatFullPan(data.fullNumber!)
          : '••••  ••••  ••••  ${data.last4}';

      return Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.bankName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardCaption(color: AppColors.cardTextMuted)
                        .copyWith(fontSize: w * 0.032, letterSpacing: w * 0.004),
                  ),
                ),
                Icon(AppIcons.contactless, color: AppColors.cardTextMuted, size: w * 0.06),
              ],
            ),
            SizedBox(height: w * 0.012),
            Text(
              data.cardName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardCaption(color: skin.accent)
                  .copyWith(fontSize: w * 0.03, letterSpacing: 0.3, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _Chip(width: w * 0.12),
            const Spacer(),
            AnimatedSwitcher(
              duration: AppDimensions.mediumAnim,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: FittedBox(
                key: ValueKey(number),
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(number, style: AppTypography.cardNumber(w * 0.058, color: AppColors.cardText)),
              ),
            ),
            SizedBox(height: w * 0.035),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('CARD', style: AppTypography.cardCaption(color: AppColors.cardTextFaint).copyWith(fontSize: w * 0.022)),
                      const SizedBox(height: 2),
                      Text(
                        (data.nickname?.isNotEmpty ?? false ? data.nickname! : data.cardName).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardCaption(color: AppColors.cardText)
                            .copyWith(fontSize: w * 0.032, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                if (data.expiry != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('VALID THRU', style: AppTypography.cardCaption(color: AppColors.cardTextFaint).copyWith(fontSize: w * 0.022)),
                      const SizedBox(height: 2),
                      Text(data.expiry!, style: AppTypography.cardNumber(w * 0.036, color: AppColors.cardText)),
                    ],
                  ),
                  SizedBox(width: w * 0.05),
                ],
                NetworkLogoWidget(network: data.network, height: w * 0.075),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _CardBack extends StatelessWidget {
  final CardFaceData data;
  final CardSkin skin;

  const _CardBack({required this.data, required this.skin});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final pad = w * 0.065;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: w * 0.08),
          Container(height: w * 0.13, color: AppColors.cardStripe),
          SizedBox(height: w * 0.06),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: w * 0.1,
                    decoration: BoxDecoration(
                      color: AppColors.cardSignature,
                      borderRadius: BorderRadius.circular(w * 0.01),
                    ),
                  ),
                ),
                Container(
                  height: w * 0.1,
                  padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(w * 0.01),
                  ),
                  child: Text(
                    data.cvv ?? '•••',
                    style: AppTypography.cardNumber(w * 0.045, color: AppColors.cardStripe),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Text(
              'CVV',
              textAlign: TextAlign.right,
              style: AppTypography.cardCaption(color: AppColors.cardTextFaint).copyWith(fontSize: w * 0.024),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
            child: Row(
              children: [
                Icon(AppIcons.shieldFill, size: w * 0.04, color: skin.accent),
                SizedBox(width: w * 0.015),
                Expanded(
                  child: Text(
                    'Secured by device hardware',
                    style: AppTypography.cardCaption(color: AppColors.cardTextMuted).copyWith(fontSize: w * 0.026),
                  ),
                ),
                NetworkLogoWidget(network: data.network, height: w * 0.06),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final double width;
  const _Chip({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardChipLight, AppColors.cardChipDark, AppColors.cardChipLight],
        ),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.black.withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(w * 0.33, 0), Offset(w * 0.33, h), p);
    canvas.drawLine(Offset(w * 0.67, 0), Offset(w * 0.67, h), p);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w * 0.33, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.67, h * 0.5), Offset(w, h * 0.5), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.33, h * 0.25, w * 0.34, h * 0.5), Radius.circular(w * 0.08)),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
