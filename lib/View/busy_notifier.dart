import 'package:flutter/material.dart';

mixin BusyNotifier on ChangeNotifier {
  bool _busy = false;
  bool get busy => _busy;
  set busy(bool busy) {
    _busy = busy;
    notifyListeners();
  }
}
