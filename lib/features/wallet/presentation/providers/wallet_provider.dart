import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/user_card.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Provider for User Wallet and Zero-Knowledge Vault.
/// Strictly ZERO setState: uses ChangeNotifier and notifies listeners.
class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;

  WalletProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<UserCard> _cards = [];
  List<UserCard> get cards => _cards;

  int _focusedIndex = 0;
  int get focusedIndex => _focusedIndex;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Cache of temporarily unmasked vault credentials (auto-clears after 30 seconds)
  final Map<int, Map<String, String>> _unmaskedCards = {};
  final Map<int, Timer> _unmaskTimers = {};

  bool isCardUnmasked(int userCardId) => _unmaskedCards.containsKey(userCardId);
  Map<String, String>? getUnmaskedData(int userCardId) => _unmaskedCards[userCardId];

  /// Initialize and load wallet cards
  Future<void> init() async {
    if (_state != ViewState.initial) return;
    await loadCards();
  }

  Future<void> loadCards({bool isRefresh = false}) async {
    if (isRefresh) {
      _setState(ViewState.refreshing);
    } else {
      _setState(ViewState.loading);
    }

    final result = await _repository.getUserCards(forceRefresh: isRefresh);

    result.when(
      success: (userCards) {
        _cards = userCards;
        _errorMessage = null;
        if (_focusedIndex >= _cards.length) {
          _focusedIndex = _cards.isEmpty ? 0 : _cards.length - 1;
        }

        if (_cards.isEmpty) {
          _setState(ViewState.empty);
        } else {
          _setState(ViewState.loaded);
        }
      },
      failure: (message, statusCode) {
        _errorMessage = message;
        if (_cards.isEmpty) {
          _setState(ViewState.error);
        } else {
          _setState(ViewState.loaded);
        }
      },
    );
  }

  void setFocusedIndex(int index) {
    if (_focusedIndex == index) return;
    _focusedIndex = index;
    notifyListeners();
  }

  /// Copies 16-digit card number to clipboard after biometric verification
  Future<bool> copyCardNumber(int userCardId) async {
    return await _repository.copyCardNumberWithBiometrics(userCardId);
  }

  /// Reveals card details (PAN, CVV, Expiry) in UI with biometric check and 30s auto-hide
  Future<bool> revealCardDetails(int userCardId) async {
    if (isCardUnmasked(userCardId)) {
      hideCardDetails(userCardId);
      return false;
    }

    final data = await _repository.getCardDetailsWithBiometrics(userCardId);
    if (data != null) {
      _unmaskedCards[userCardId] = data;
      _unmaskTimers[userCardId]?.cancel();
      _unmaskTimers[userCardId] = Timer(const Duration(seconds: 30), () {
        hideCardDetails(userCardId);
      });
      notifyListeners();
      return true;
    }
    return false;
  }

  void hideCardDetails(int userCardId) {
    _unmaskTimers[userCardId]?.cancel();
    _unmaskTimers.remove(userCardId);
    _unmaskedCards.remove(userCardId);
    notifyListeners();
  }

  /// Adds a new card to user wallet and hardware vault
  Future<bool> addCard({
    required int cardId,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  }) async {
    final result = await _repository.addUserCard(
      cardId: cardId,
      nickname: nickname,
      last4Digits: last4Digits,
      billingCycleDay: billingCycleDay,
      fullCardNumber: fullCardNumber,
      cvv: cvv,
      expiry: expiry,
    );

    if (result.isSuccess) {
      _cards.add(result.dataOrNull!);
      _focusedIndex = _cards.length - 1;
      _setState(ViewState.loaded);
      return true;
    }
    return false;
  }

  /// Deletes a card from user wallet and clears from secure vault
  Future<bool> deleteCard(int userCardId) async {
    final result = await _repository.deleteUserCard(userCardId);
    if (result.isSuccess) {
      _cards.removeWhere((c) => c.id == userCardId);
      hideCardDetails(userCardId);
      if (_focusedIndex >= _cards.length && _cards.isNotEmpty) {
        _focusedIndex = _cards.length - 1;
      }
      if (_cards.isEmpty) {
        _setState(ViewState.empty);
      } else {
        _setState(ViewState.loaded);
      }
      return true;
    }
    return false;
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _unmaskTimers.values) {
      timer.cancel();
    }
    _unmaskTimers.clear();
    _unmaskedCards.clear();
    super.dispose();
  }
}
