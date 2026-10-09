import 'package:flutter/widgets.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../domain/entities/spend_category.dart';

/// Presentation mapping from [SpendCategory] to centralised icon and colour tokens.
extension SpendCategoryVisuals on SpendCategory {
  IconData get icon => switch (this) {
        SpendCategory.dining => AppIcons.dining,
        SpendCategory.groceries => AppIcons.grocery,
        SpendCategory.shopping => AppIcons.shopping,
        SpendCategory.travel => AppIcons.travel,
        SpendCategory.fuel => AppIcons.fuel,
        SpendCategory.utilities => AppIcons.utilities,
        SpendCategory.entertainment => AppIcons.entertainment,
        SpendCategory.subscriptions => AppIcons.subscriptions,
        SpendCategory.health => AppIcons.medical,
        SpendCategory.education => AppIcons.education,
        SpendCategory.rent => AppIcons.rent,
        SpendCategory.fees => AppIcons.fees,
        SpendCategory.wallet => AppIcons.walletTransfer,
        SpendCategory.other => AppIcons.otherCategory,
      };

  Color get color => switch (this) {
        SpendCategory.dining => AppColors.orange,
        SpendCategory.groceries => AppColors.lime,
        SpendCategory.shopping => AppColors.pink,
        SpendCategory.travel => AppColors.sapphire,
        SpendCategory.fuel => AppColors.amber,
        SpendCategory.utilities => AppColors.cyan,
        SpendCategory.entertainment => AppColors.purple,
        SpendCategory.subscriptions => AppColors.indigo,
        SpendCategory.health => AppColors.emerald,
        SpendCategory.education => AppColors.teal,
        SpendCategory.rent => AppColors.gold,
        SpendCategory.fees => AppColors.rose,
        SpendCategory.wallet => AppColors.sapphireLight,
        SpendCategory.other => AppColors.slate,
      };
}
