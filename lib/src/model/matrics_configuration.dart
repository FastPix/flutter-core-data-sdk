import '../../fastpix_flutter_core_data.dart';

class MetricsConfiguration {
  final PlayerData? playerData;
  final String? workspaceId;
  final String? beaconUrl;
  final String? viewerId;
  final VideoData? videoData;
  final bool enableLogging;
  final List<CustomData>? customData;

  MetricsConfiguration._builder(MetricsBuilder builder)
      : playerData = builder._playerData,
        workspaceId = builder._workspaceId,
        beaconUrl = builder._beaconUrl,
        viewerId = builder._viewerId,
        videoData = builder._videoData,
        enableLogging = builder._enableLogging,
        customData = builder._customData;

  MetricsConfiguration(
      {this.playerData,
      required this.workspaceId,
      required this.beaconUrl,
      required this.viewerId,
      this.videoData,
      this.enableLogging = false,
      this.customData});
}

class MetricsBuilder {
  PlayerData? _playerData;
  String? _workspaceId;
  String? _beaconUrl;
  VideoData? _videoData;
  bool _enableLogging = false;
  String? _viewerId;
  List<CustomData>? _customData;

  MetricsBuilder setPlayerData(PlayerData playerData) {
    _playerData = playerData;
    return this;
  }

  MetricsBuilder setViewerId(String viewerId) {
    _viewerId = viewerId;
    return this;
  }

  MetricsBuilder setCustomData(List<CustomData> customData) {
    _customData = customData;
    return this;
  }

  MetricsBuilder isEnableLogging(bool enableLogging) {
    _enableLogging = enableLogging;
    return this;
  }

  MetricsBuilder setWorkSpaceId(String workSpaceId) {
    _workspaceId = workSpaceId;
    return this;
  }

  MetricsBuilder setVideoData(VideoData videoData) {
    _videoData = videoData;
    return this;
  }

  MetricsBuilder setBeaconUrl(String beaconUrl) {
    _beaconUrl = beaconUrl;
    return this;
  }

  MetricsConfiguration build() {
    if (_workspaceId == null) {
      throw Exception("WorkspaceId is required");
    }
    if (_beaconUrl == null) {
      throw Exception("BeaconUrl is required");
    }
    return MetricsConfiguration._builder(this);
  }
}
