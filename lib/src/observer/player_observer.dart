import 'package:fastpix_flutter_core_data/src/model/error_model.dart';

abstract interface class PlayerObserver {
  int? playerHeight();

  int? playerWidth();

  int? videoSourceWidth();

  int? videoSourceHeight();

  int? playHeadTime();

  String? mimeType();

  int? sourceFps();

  String? sourceAdvertisedBitrate();

  int? sourceAdvertiseFrameRate();

  int? sourceDuration();

  bool? isPause();

  bool? isAutoPlay();

  bool? preLoad();

  bool? isBuffering();

  String? playerCodec();

  String? sourceHostName();

  bool? isLive();

  String? sourceUrl();

  bool? isFullScreen();

  ErrorModel getPlayerError();

  String? getVideoCodec();

  String? getSoftwareName();

  String? getSoftwareVersion();
}
