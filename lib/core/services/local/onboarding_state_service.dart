import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStateService {
  static const String _firstTimeUserKey = 'isFirstTimeUser';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isFirstTimeUser => _prefs.getBool(_firstTimeUserKey) ?? true;

  Future<void> markOnboardingComplete() {
    return _prefs.setBool(_firstTimeUserKey, false);
  }
}
