import '../../features/catalog/data/models/bank_model.dart';
import '../../features/catalog/data/models/catalog_card_model.dart';
import '../../features/catalog/data/models/category_model.dart';
import '../../features/catalog/domain/entities/catalog_card.dart';

/// Embedded mock dataset for sub-second offline loading and reliable testing
class MockSeedData {
  const MockSeedData._();

  static const List<BankModel> banks = [
    BankModel(id: 1, name: 'HDFC Bank', slug: 'hdfc-bank', cardCount: 84),
    BankModel(id: 2, name: 'SBI Card', slug: 'sbi-card', cardCount: 72),
    BankModel(id: 3, name: 'Axis Bank', slug: 'axis-bank', cardCount: 65),
    BankModel(id: 4, name: 'ICICI Bank', slug: 'icici-bank', cardCount: 58),
    BankModel(id: 5, name: 'American Express', slug: 'american-express', cardCount: 22),
    BankModel(id: 6, name: 'Standard Chartered', slug: 'standard-chartered', cardCount: 26),
    BankModel(id: 7, name: 'Kotak Mahindra Bank', slug: 'kotak-mahindra-bank', cardCount: 38),
    BankModel(id: 8, name: 'IndusInd Bank', slug: 'indusind-bank', cardCount: 31),
    BankModel(id: 9, name: 'HSBC', slug: 'hsbc', cardCount: 16),
    BankModel(id: 10, name: 'Tata Neu', slug: 'tata-neu', cardCount: 4),
    BankModel(id: 11, name: 'AU Small Finance Bank', slug: 'au-bank', cardCount: 19),
    BankModel(id: 12, name: 'RBL Bank', slug: 'rbl-bank', cardCount: 29),
  ];

  static const List<CategoryModel> categories = [
    CategoryModel(id: 1, name: 'Dining', slug: 'Dining', iconName: 'dining', description: 'Restaurants, cafes & food delivery'),
    CategoryModel(id: 2, name: 'Flights', slug: 'Flights', iconName: 'flights', description: 'Domestic & international flights'),
    CategoryModel(id: 3, name: 'Fuel', slug: 'Fuel', iconName: 'fuel', description: 'Petrol pumps & EV charging'),
    CategoryModel(id: 4, name: 'Grocery', slug: 'Grocery', iconName: 'grocery', description: 'Supermarkets & quick commerce'),
    CategoryModel(id: 5, name: 'Online Shopping', slug: 'Online Shopping', iconName: 'shopping', description: 'Amazon, Flipkart, Myntra'),
    CategoryModel(id: 7, name: 'Travel', slug: 'Travel', iconName: 'travel', description: 'Hotels, stays & car rentals'),
    CategoryModel(id: 6, name: 'Rent', slug: 'Rent', iconName: 'rent', description: 'House rent payments'),
    CategoryModel(id: 8, name: 'Utilities', slug: 'Utilities', iconName: 'utilities', description: 'Electricity, water, gas & recharges'),
    CategoryModel(id: 16, name: 'UPI', slug: 'UPI', iconName: 'upi', description: 'RuPay credit on UPI'),
    CategoryModel(id: 13, name: 'International', slug: 'International', iconName: 'international', description: 'Overseas & foreign currency spends'),
  ];

  static final List<CatalogCardModel> sampleCards = [
    CatalogCardModel(
      id: 1,
      name: 'HDFC Infinia Metal Edition',
      slug: 'hdfc-infinia-metal',
      bankName: 'HDFC Bank',
      bankSlug: 'hdfc-bank',
      network: 'Visa Infinite',
      cardType: 'Super Premium',
      annualFee: 12500,
      joiningFee: 12500,
      feeWaiverSpend: 1000000,
      rewardType: 'Reward Points',
      baseReturnRate: 3.3,
      isPopular: true,
      rating: 4.9,
      keyPerks: [
        '5 Reward Points per ₹150 (3.3% flat return)',
        'Up to 10X points (33% return) on SmartBuy travel',
        'Unlimited domestic & international lounge access + guests',
        '24/7 Global Concierge & ITC Hotel 1+1 buffet dining',
      ],
      tabs: const {
        'earn-categories': CardTabDetail(
          title: 'Reward Multipliers',
          description: 'Top-of-market reward generation across multiple spending verticals',
          bulletPoints: [
            'Dining & Hotels via SmartBuy: 10X Points (33% return)',
            'Flight Bookings on SmartBuy: 5X Points (16.5% return)',
            'Base Retail Spend: 5 points per ₹150 (3.33% value)',
            '1 Reward Point = ₹1 on flight/hotel bookings via SmartBuy',
          ],
        ),
        'lounge-access': CardTabDetail(
          title: 'Airport Lounge Privileges',
          description: 'Comprehensive complimentary lounge coverage globally',
          bulletPoints: [
            'Unlimited Complimentary Domestic Lounge Access via Priority Pass',
            'Unlimited Complimentary International Lounge Access globally',
            'Complimentary Lounge Access for Add-on cardholders + 4 guest visits',
          ],
        ),
        'milestones': CardTabDetail(
          title: 'Fee Waiver & Milestones',
          description: 'Annual fee waiver criteria',
          bulletPoints: [
            'Renewal fee of ₹12,500 waived on spending ₹10,00,000+ in an anniversary year',
            '12,500 Reward Points awarded upon renewal fee payment',
          ],
        ),
      },
    ),
    CatalogCardModel(
      id: 2,
      name: 'SBI Cashback Credit Card',
      slug: 'sbi-cashback',
      bankName: 'SBI Card',
      bankSlug: 'sbi-card',
      network: 'Mastercard World',
      cardType: 'Cashback',
      annualFee: 999,
      joiningFee: 999,
      feeWaiverSpend: 200000,
      rewardType: 'Direct Cashback',
      baseReturnRate: 5.0,
      isPopular: true,
      rating: 4.8,
      keyPerks: [
        '5% Direct Cashback on almost all online transactions',
        '1% Cashback on offline retail spends',
        'Direct statement credit within 2 days of statement generation',
        'Annual fee waived on ₹2,00,000 spend',
      ],
      tabs: const {
        'earn-categories': CardTabDetail(
          title: 'Cashback Rules',
          description: 'No merchant restrictions, direct statement cash back',
          bulletPoints: [
            '5% Cashback on Amazon, Flipkart, Swiggy, Zomato, Uber, Myntra, etc.',
            'Capped at ₹5,000 cashback per monthly billing cycle',
            '1% Cashback on all other eligible retail transactions',
            'Exclusions: Rent, Wallet loads, Fuel, School fees',
          ],
        ),
        'milestones': CardTabDetail(
          title: 'Fee Waiver',
          description: 'Zero fee threshold',
          bulletPoints: [
            'Spend ₹2 Lakhs in previous year to waive ₹999 annual fee',
          ],
        ),
      },
    ),
    CatalogCardModel(
      id: 3,
      name: 'Axis Bank Atlas Credit Card',
      slug: 'axis-atlas',
      bankName: 'Axis Bank',
      bankSlug: 'axis-bank',
      network: 'Visa Signature',
      cardType: 'Travel',
      annualFee: 5000,
      joiningFee: 5000,
      feeWaiverSpend: null,
      rewardType: 'EDGE Miles',
      baseReturnRate: 4.0,
      isPopular: true,
      rating: 4.7,
      keyPerks: [
        '5 EDGE Miles per ₹100 on Airline & Hotel bookings',
        '2 EDGE Miles per ₹100 on all other spends',
        '1:2 or 1:1 conversion to Singapore Krisflyer, Accor, Marriott, United',
        'Silver/Gold/Platinum tier progression based on annual spend',
      ],
      tabs: const {
        'earn-categories': CardTabDetail(
          title: 'Airline & Hotel Acceleration',
          description: 'The preferred card for frequent flyers',
          bulletPoints: [
            'Direct bookings on airline websites earn 5 EDGE Miles per ₹100 (~10% return)',
            'General spends earn 2 EDGE Miles per ₹100 (~4% return)',
            'Tier bonuses: 2,500 miles on reaching Gold, 10,000 miles on Platinum',
          ],
        ),
        'lounge-access': CardTabDetail(
          title: 'Lounge Allocation',
          description: 'Tier-based lounge access',
          bulletPoints: [
            'Up to 18 domestic and 12 international lounge visits based on tier status',
            'Priority Pass provided for international access',
          ],
        ),
      },
    ),
    CatalogCardModel(
      id: 4,
      name: 'ICICI Amazon Pay Credit Card',
      slug: 'icici-amazon-pay',
      bankName: 'ICICI Bank',
      bankSlug: 'icici-bank',
      network: 'Visa Platinum',
      cardType: 'Entry & Cashback',
      annualFee: 0,
      joiningFee: 0,
      feeWaiverSpend: 0,
      rewardType: 'Amazon Pay Balance',
      baseReturnRate: 2.0,
      isPopular: true,
      rating: 4.7,
      keyPerks: [
        'Lifetime Free credit card with ₹0 annual / joining fees',
        '5% unlimited cashback for Amazon Prime members',
        '2% cashback on 100+ partner merchants (Swiggy, Uber, etc.)',
        '1% cashback on all other retail transactions',
      ],
      tabs: const {
        'earn-categories': CardTabDetail(
          title: 'Amazon & Partner Earnings',
          description: 'Unlimited cashback directly to Amazon Pay wallet',
          bulletPoints: [
            '5% Cashback on Amazon.in purchases for Prime members',
            '3% Cashback on Amazon.in for non-Prime members',
            '2% Cashback on flight bookings, bill payments on Amazon',
            '1% Cashback on offline retail and international spends',
          ],
        ),
      },
    ),
    CatalogCardModel(
      id: 5,
      name: 'American Express Platinum Travel',
      slug: 'amex-plat-travel',
      bankName: 'American Express',
      bankSlug: 'american-express',
      network: 'American Express',
      cardType: 'Travel & Lifestyle',
      annualFee: 5000,
      joiningFee: 3500,
      feeWaiverSpend: null,
      rewardType: 'Membership Rewards',
      baseReturnRate: 8.0,
      isPopular: true,
      rating: 4.6,
      keyPerks: [
        '₹48,000+ value in Taj vouchers & Indigo tickets on ₹4L annual spend',
        '15,000 MR points + ₹7,500 Indigo voucher on ₹1.9L milestone',
        '25,000 MR points + ₹10,000 Taj voucher on ₹4L milestone',
        '8 complimentary domestic airport lounge visits/year',
      ],
      tabs: const {
        'milestones': CardTabDetail(
          title: 'Milestone Structure',
          description: 'Highest ROI card at exactly ₹4 Lakhs spend per year',
          bulletPoints: [
            'Spend ₹1,90,000: Receive 15,000 bonus MR points + ₹7,500 Indigo voucher',
            'Spend ₹4,00,000: Receive 25,000 bonus MR points + ₹10,000 Taj Experiences voucher',
            'Net annual return reaches 9% to 11% when reaching ₹4 Lakhs',
          ],
        ),
      },
    ),
    CatalogCardModel(
      id: 6,
      name: 'Tata Neu Infinity HDFC Bank',
      slug: 'tata-neu-infinity',
      bankName: 'HDFC Bank',
      bankSlug: 'hdfc-bank',
      network: 'RuPay / Visa',
      cardType: 'Co-Branded',
      annualFee: 1499,
      joiningFee: 1499,
      feeWaiverSpend: 300000,
      rewardType: 'NeuCoins',
      baseReturnRate: 5.0,
      isPopular: false,
      rating: 4.5,
      keyPerks: [
        '10% NeuCoins on Tata Neu app purchases (BigBasket, 1mg, Croma, Air India Express)',
        '1.5% NeuCoins on UPI payments via RuPay',
        '8 domestic and 4 international lounge visits',
        '1 NeuCoin = ₹1 across the Tata Ecosystem',
      ],
      tabs: const {
        'earn-categories': CardTabDetail(
          title: 'Tata Ecosystem Multipliers',
          description: 'Massive returns on grocery, electronics, and Air India',
          bulletPoints: [
            '5% back on Tata Neu + 5% additional NeuPass member coins = 10% total',
            '1.5% back on merchant UPI QR code scans',
            '1.5% back on domestic offline retail spends',
          ],
        ),
      },
    ),
  ];
}
