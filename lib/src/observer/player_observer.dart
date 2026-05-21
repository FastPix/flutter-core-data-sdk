import 'package:fastpix_flutter_core_data/src/model/error_model.dart';

mixin PlayerObserver {
  ErrorModel? getPlayerError();

  bool isPlayerFullScreen();

  bool isPlayerPaused();

  bool isPlayerAutoPlayOn();

  double playerWidth();

  double playerHeight();

  String playerLanguageCode();

  bool playerPreLoadOn();

  String videoThumbnailUrl();

  String videoSourceUrl();

  String videoSourceMimeType();

  int videoSourceDuration();

  bool isVideoSourceLive();

  int videoSourceHeight();

  int videoSourceWidth();

  /// Returns the player's current playhead position in milliseconds.
  ///
  /// Must be synchronous and non-blocking. Hosts should subscribe to their
  /// player's position stream (e.g. BetterPlayer's `position` poller) and
  /// cache the latest value in a field; this method just returns the cached
  /// `int`. Returning a slightly-stale value is fine — the SDK calls this
  /// at event-submission time and never awaits it. If no position is known
  /// yet, return `0`.
  int playerPlayHeadTime();
}
