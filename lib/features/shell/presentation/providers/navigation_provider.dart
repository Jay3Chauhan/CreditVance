import 'package:flutter/foundation.dart';

/// Shell tab state. Tabs are built lazily the first time they're visited.
class NavigationProvider extends ChangeNotifier {
  static const int home = 0;
  static const int wallet = 1;
  static const int explore = 2;
  static const int rewards = 3;
  static const int account = 4;

  int _currentIndex;
  final Set<int> _visited;

  NavigationProvider({int initialIndex = 0})
      : _currentIndex = initialIndex,
        _visited = {initialIndex};

  int get currentIndex => _currentIndex;
  bool isVisited(int index) => _visited.contains(index);

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _visited.add(index);
    notifyListeners();
  }
}
