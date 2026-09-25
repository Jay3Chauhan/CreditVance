import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized Iconography tokens for CardSage.
/// All icons throughout the app MUST be referenced from here.
class AppIcons {
  const AppIcons._();

  // Navigation Bar Icons
  static const IconData navAdvisor = CupertinoIcons.sparkles;
  static const IconData navAdvisorActive = CupertinoIcons.sparkles;

  static const IconData navWallet = CupertinoIcons.creditcard;
  static const IconData navWalletActive = CupertinoIcons.creditcard_fill;

  static const IconData navCatalog = CupertinoIcons.compass;
  static const IconData navCatalogActive = CupertinoIcons.compass_fill;

  static const IconData navCalculator = CupertinoIcons.chart_pie;
  static const IconData navCalculatorActive = CupertinoIcons.chart_pie_fill;

  static const IconData navProfile = CupertinoIcons.person_crop_circle;
  static const IconData navProfileActive = CupertinoIcons.person_crop_circle_fill;

  // Actions & Buttons
  static const IconData add = CupertinoIcons.add;
  static const IconData copy = CupertinoIcons.doc_on_doc;
  static const IconData check = CupertinoIcons.check_mark_circled_solid;
  static const IconData lock = CupertinoIcons.lock_shield;
  static const IconData unlock = CupertinoIcons.lock_open;
  static const IconData search = CupertinoIcons.search;
  static const IconData filter = CupertinoIcons.slider_horizontal_3;
  static const IconData sort = CupertinoIcons.arrow_up_arrow_down;
  static const IconData back = CupertinoIcons.back;
  static const IconData close = CupertinoIcons.clear_thick_circled;
  static const IconData refresh = CupertinoIcons.refresh;
  static const IconData share = CupertinoIcons.share;
  static const IconData delete = CupertinoIcons.trash;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData info = CupertinoIcons.info_circle;
  static const IconData alertCircle = CupertinoIcons.exclamationmark_circle_fill;
  static const IconData mail = CupertinoIcons.mail_solid;
  static const IconData user = CupertinoIcons.person_solid;
  static const IconData chevronRight = CupertinoIcons.chevron_right;
  static const IconData chevronDown = CupertinoIcons.chevron_down;

  // Vault & Security
  static const IconData faceId = CupertinoIcons.viewfinder;
  static const IconData touchId = Icons.fingerprint_rounded;
  static const IconData shieldCheck = CupertinoIcons.shield_lefthalf_fill;
  static const IconData eye = CupertinoIcons.eye;
  static const IconData eyeSlash = CupertinoIcons.eye_slash;

  // Spend Categories
  static const IconData dining = Icons.restaurant_rounded;
  static const IconData flights = Icons.flight_takeoff_rounded;
  static const IconData fuel = Icons.local_gas_station_rounded;
  static const IconData grocery = Icons.shopping_basket_rounded;
  static const IconData shopping = Icons.shopping_bag_rounded;
  static const IconData rent = Icons.home_work_rounded;
  static const IconData travel = Icons.luggage_rounded;
  static const IconData utilities = Icons.bolt_rounded;
  static const IconData entertainment = Icons.movie_filter_rounded;
  static const IconData medical = Icons.medical_services_rounded;
  static const IconData education = Icons.school_rounded;
  static const IconData international = Icons.public_rounded;

  // Perks & Badges
  static const IconData lounge = Icons.airline_seat_recline_extra_rounded;
  static const IconData milestone = Icons.flag_rounded;
  static const IconData cashback = Icons.account_balance_wallet_rounded;
  static const IconData rewardPoints = Icons.stars_rounded;
  static const IconData feeFree = Icons.money_off_rounded;
  static const IconData star = CupertinoIcons.star_fill;
}
