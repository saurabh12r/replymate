import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStateService {
  static const String _firstTimeUserKey = 'isFirstTimeUser';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Safe before [init] completes (defaults to first-time until prefs load).
  bool get isFirstTimeUser {
    final p = _prefs;
    if (p == null) return true;
    return p.getBool(_firstTimeUserKey) ?? true;
  }

  Future<void> markOnboardingComplete() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setBool(_firstTimeUserKey, false);
  }
}
