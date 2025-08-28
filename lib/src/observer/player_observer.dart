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

  Future<int> playerPlayHeadTime();
}
