
import 'package:flutter/material.dart';

enum UtilityType { luce, gas }

class SelectUtilityController extends ChangeNotifier {
  UtilityType? selectedUtility;

  void selectUtility(UtilityType type) {
    selectedUtility = type;
    notifyListeners();
  }

  bool get isSelected => selectedUtility != null;
  bool get isLuce => selectedUtility == UtilityType.luce;
  bool get isGas => selectedUtility == UtilityType.gas;
}
