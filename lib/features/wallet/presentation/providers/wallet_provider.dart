import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_vault_service.dart';
import '../../../../core/utils/view_state.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../domain/entities/user_card.dart';
import '../../domain/repositories/wallet_repository.dart';

enum WalletViewMode { stack, list }

/// Wallet state machine: cards, focus, view mode, and the timed reveal window.
class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;

  WalletProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<UserCard> _cards = [];
  List<UserCard> get cards => List.unmodifiable(_cards);

  int _focusedIndex = 0;
  int get focusedIndex => _cards.isEmpty ? 0 : _focusedIndex.clamp(0, _cards.length - 1);
  UserCard? get focusedCard => _cards.isEmpty ? null : _cards[focusedIndex];

  WalletViewMode _viewMode = WalletViewMode.stack;
  WalletViewMode get viewMode => _viewMode;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Duration clipboardDuration = const Duration(seconds: 30);
  Duration revealDuration = const Duration(seconds: 30);

  // Reveal window (single card at a time).
  int? _revealedId;
  VaultSecrets? _secrets;
  Timer? _revealTimer;
  final ValueNotifier<int> _revealRemaining = ValueNotifier<int>(0);
  ValueListenable<int> get revealRemaining => _revealRemaining;

  bool isRevealed(int userCardId) => _revealedId == userCardId && _secrets != null;
  VaultSecrets? secretsFor(int userCardId) => isRevealed(userCardId) ? _secrets : null;

  double get totalAnnualFees => _cards.fold(0.0, (sum, c) => sum + c.annualFee);

  UserCard? get nextDueCard {
    final withDue = _cards.where((c) => c.estimatedDueDate != null).toList()
      ..sort((a, b) => a.estimatedDueDate!.compareTo(b.estimatedDueDate!));
    return withDue.isEmpty ? null : withDue.first;
  }

  Future<void> init() async {
    if (_state != ViewState.initial) return;
    await loadCards();
  }

  Future<void> loadCards({bool isRefresh = false}) async {
    _setState(isRefresh && _cards.isNotEmpty ? ViewState.refreshing : ViewState.loading);
    final result = await _repository.getUserCards(forceRefresh: isRefresh);
    result.when(
      success: (userCards) {
        _cards = userCards;
        _errorMessage = null;
        _setState(_cards.isEmpty ? ViewState.empty : ViewState.loaded);
      },
      failure: (message, _) {
        _errorMessage = message;
        _setState(_cards.isEmpty ? ViewState.error : ViewState.loaded);
      },
    );
  }

  void setFocusedIndex(int index) {
    if (_focusedIndex == index) return;
    _focusedIndex = index;
    notifyListeners();
  }

  void focusCard(int userCardId) {
    final idx = _cards.indexWhere((c) => c.id == userCardId);
    if (idx != -1) setFocusedIndex(idx);
  }

  void toggleViewMode() {
    _viewMode = _viewMode == WalletViewMode.stack ? WalletViewMode.list : WalletViewMode.stack;
    notifyListeners();
  }

  Future<VaultStatus> copyCardNumber(int userCardId) =>
      _repository.copyCardNumber(userCardId, clearAfter: clipboardDuration);

  Future<VaultStatus> copyCvv(int userCardId) =>
      _repository.copyField(userCardId, 'cvv', clearAfter: clipboardDuration);

  Future<VaultStatus> copyExpiry(int userCardId) =>
      _repository.copyField(userCardId, 'exp', clearAfter: clipboardDuration);

  /// Toggles the reveal window. Returns the vault status of the attempt
  /// (or success when hiding).
  Future<VaultStatus> toggleReveal(int userCardId) async {
    if (isRevealed(userCardId)) {
      hideSecrets();
      return VaultStatus.success;
    }
    final (status, secrets) = await _repository.readSecrets(userCardId);
    if (!status.isSuccess || secrets == null) return status;

    _revealTimer?.cancel();
    _revealedId = userCardId;
    _secrets = secrets;
    _revealRemaining.value = revealDuration.inSeconds;
    _revealTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = _revealRemaining.value - 1;
      if (next <= 0) {
        hideSecrets();
      } else {
        _revealRemaining.value = next;
      }
    });
    notifyListeners();
    return VaultStatus.success;
  }

  void hideSecrets() {
    _revealTimer?.cancel();
    _revealTimer = null;
    final wasRevealed = _revealedId != null;
    _revealedId = null;
    _secrets = null;
    _revealRemaining.value = 0;
    if (wasRevealed) notifyListeners();
  }

  Future<UserCard?> addCard({
    required CatalogCard card,
    required String nickname,
    required String last4Digits,
    int? billingCycleDay,
    String? fullCardNumber,
    String? cvv,
    String? expiry,
  }) async {
    final result = await _repository.addUserCard(
      card: card,
      nickname: nickname,
      last4Digits: last4Digits,
      billingCycleDay: billingCycleDay,
      fullCardNumber: fullCardNumber,
      cvv: cvv,
      expiry: expiry,
    );
    return result.when(
      success: (created) {
        _cards = [..._cards, created];
        _focusedIndex = _cards.length - 1;
        _errorMessage = null;
        _setState(ViewState.loaded);
        return created;
      },
      failure: (message, _) {
        _errorMessage = message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<bool> updateCard(UserCard card, {String? nickname, int? billingCycleDay}) async {
    final result = await _repository.updateUserCard(card, nickname: nickname, billingCycleDay: billingCycleDay);
    return result.when(
      success: (updated) {
        _cards = _cards.map((c) => c.id == updated.id ? updated : c).toList();
        notifyListeners();
        return true;
      },
      failure: (message, _) {
        _errorMessage = message;
        notifyListeners();
        return false;
      },
    );
  }

  /// Optimistic delete with undo support: returns the removed card and index.
  Future<(UserCard, int)?> deleteCard(int userCardId) async {
    final index = _cards.indexWhere((c) => c.id == userCardId);
    if (index == -1) return null;
    final removed = _cards[index];
    if (_revealedId == userCardId) hideSecrets();

    final result = await _repository.deleteUserCard(userCardId);
    if (!result.isSuccess) {
      _errorMessage = result.errorOrNull;
      notifyListeners();
      return null;
    }
    _cards = [..._cards]..removeAt(index);
    if (_focusedIndex >= _cards.length) _focusedIndex = _cards.isEmpty ? 0 : _cards.length - 1;
    _setState(_cards.isEmpty ? ViewState.empty : ViewState.loaded);
    return (removed, index);
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final focusedId = focusedCard?.id;
    final list = [..._cards];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _cards = list;
    if (focusedId != null) _focusedIndex = _cards.indexWhere((c) => c.id == focusedId);
    notifyListeners();
    _repository.saveOrder(_cards.map((c) => c.id).toList());
  }

  Future<void> loadSampleCards() async {
    _setState(ViewState.loading);
    await _repository.loadSampleCards();
    await loadCards();
  }

  /// Called on sign-out / erase: wipes local wallet and in-memory secrets.
  Future<void> reset({bool eraseLocal = false}) async {
    hideSecrets();
    if (eraseLocal) await _repository.clearLocalWallet();
    _cards = [];
    _focusedIndex = 0;
    _state = ViewState.initial;
    notifyListeners();
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _revealRemaining.dispose();
    super.dispose();
  }
}
