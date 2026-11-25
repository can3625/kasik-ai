import 'package:flutter/foundation.dart';
import '../models/food_analysis_model.dart';

class AppProvider with ChangeNotifier {
  UserProfile _userProfile = UserProfile(
    age: null,
    weight: null,
    height: null,
  );

  UserProfile get userProfile => _userProfile;

  void updateProfile({
    int? age,
    double? weight,
    double? height,
  }) {
    _userProfile = UserProfile(
      age: age ?? _userProfile.age,
      weight: weight ?? _userProfile.weight,
      height: height ?? _userProfile.height,
    );

    notifyListeners();
  }
}
