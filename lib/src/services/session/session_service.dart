import 'package:flutter/foundation.dart';
import '../service_locator.dart';
import '../configuration/configuration_service.dart';

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  final ConfigurationService _configService =
      ServiceLocator().configurationService;

  String? _sessionId;
  int? _sessionStartTime;
  int? _sessionExpiryTime;
  bool _isSessionValid = false;

  factory SessionService() => _instance;

  SessionService._internal();

  String? get sessionId => _sessionId;
  int? get sessionStartTime => _sessionStartTime;
  int? get sessionExpiryTime => _sessionExpiryTime;
  bool get isSessionValid => _isSessionValid;

  void initializeSession() {
    final currentTime = _configService.currentTimeStamp();
    _sessionId = _configService.generateUUID();
    _sessionStartTime = currentTime;
    _sessionExpiryTime =
        currentTime + (24 * 60 * 60 * 1000); // 24 hours in milliseconds
    _isSessionValid = true;
    notifyListeners();
  }

  bool validateSession() {
    if (!_isSessionValid || _sessionExpiryTime == null) {
      return false;
    }

    final currentTime = _configService.currentTimeStamp();
    if (currentTime >= _sessionExpiryTime!) {
      _isSessionValid = false;
      notifyListeners();
      return false;
    }

    return true;
  }

  void invalidateSession() {
    _isSessionValid = false;
    notifyListeners();
  }

  void reset() {
    _sessionId = null;
    _sessionStartTime = null;
    _sessionExpiryTime = null;
    _isSessionValid = false;
    notifyListeners();
  }
}
