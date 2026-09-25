import 'package:flutter/foundation.dart';

/// Navigation state provider for managing bottom navigation tabs.
/// Strictly Zero setState: Uses Provider & ChangeNotifier.
class NavigationProvider extends ChangeNotifier {
  int _currentIndex;

  NavigationProvider({int initialIndex = 0}) : _currentIndex = initialIndex;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
