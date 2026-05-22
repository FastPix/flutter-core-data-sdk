import 'dart:async';
import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';
import 'package:fastpix_flutter_core_data_example/library_info.dart';
import 'package:fastpix_flutter_core_data_example/valid_events.dart';
import 'package:flutter/material.dart';

class FastPixBaseBetterPlayer implements PlayerObserver {
  final BetterPlayerController playerController;
  final String workspaceId;
  final String? beaconUrl;
  final bool enabledLogging;
  final PlayerData? playerData;
  final VideoData? videoData;
  final CustomData? customData;
  final String viewerId;
  bool _isPlayerResolutionCalculationDone = false;
  PlayerEvent? _lastDispatchedEvent;
  bool _isEndedCalled = false;
  DateTime? _lastEndedAt;
  DateTime? _lastSeekAt;

  String audioLanguage = 'en';
  double playerWidthSize = 0;
  double playerHeightSize = 0;
  GlobalKey _playerDimensionKey = GlobalKey();
  late FastPixMetrics fastPixMetrics;
  ErrorModel? _errorModel;

  // Pulse lifecycle — mirrors Android's FastPixBaseMedia3Player.
  // 10s cadence, schedule on viewBegin/play/playing/buffering,
  // cancel on pause/ended/error/release. seeked is conditional on play state.
  static const Duration _pulseInterval = Duration(seconds: 10);
  Timer? _pulseTimer;

  // Cached playhead in ms, refreshed every 250ms by [_positionPoller].
  // The SDK calls `playerPlayHeadTime()` synchronously at event-submission
  // time and reads this cache directly — never awaits the platform channel,
  // which can hang during the player's codec init window.
  int _lastKnownPlayheadMs = 0;
  Timer? _positionPoller;
  static const Duration _positionPollInterval = Duration(milliseconds: 250);

  FastPixBaseBetterPlayer._builder(FastPixBaseVideoPlayerBuilder builder)
    : playerController = builder._playerController,
      workspaceId = builder._workspaceId,
      beaconUrl = builder._beaconUrl,
      customData = builder._customData,
      viewerId = builder._viewerId,
      enabledLogging = builder._enabledLogging,
      playerData = builder._playerData,

      videoData = builder._videoData {
    final audioTrack = playerController.betterPlayerAsmsAudioTrack;
    audioLanguage = audioTrack?.language ?? 'en';
    for (var track in playerController.betterPlayerAsmsAudioTracks ?? []) {
      if (track.language != null) {
        audioLanguage = track.language ?? 'en';
        break;
      }
    }
  }

  /// Order matters here — matches FastPixBaseMedia3Player.release():
  ///   1. Stop the 10s pulse loop so it can't race with shutdown.
  ///   2. Detach player-event listeners so no more dispatches arrive.
  ///   3. Stop the position poller (final cached value is the last we read).
  ///   4. Tear down the SDK while playerController is still alive — the
  ///      viewCompleted event built inside dispose() reads cached state via
  ///      this observer; the player is queried via sync getters only.
  ///   5. Only THEN dispose the player controller itself.
  Future<void> disposeMetrix() async {
    _cancelPulse();
    _positionPoller?.cancel();
    _positionPoller = null;
    playerController.removeEventsListener(_onPlayerEvent);
    playerController.removeEventsListener(_oniOSPlayerEvent);
    await fastPixMetrics.dispose(true, playheadOverride: _lastKnownPlayheadMs);
    playerController.dispose();
  }

  /// Polls the BetterPlayer's position every [_positionPollInterval] and
  /// caches the latest value in [_lastKnownPlayheadMs]. This is what backs
  /// the sync `playerPlayHeadTime()` getter the SDK calls.
  void _startPositionPolling() {
    _positionPoller?.cancel();
    _positionPoller = Timer.periodic(_positionPollInterval, (_) async {
      try {
        final position = await playerController.videoPlayerController?.position;
        if (position != null) {
          _lastKnownPlayheadMs = position.inMilliseconds;
        }
      } catch (_) {
        // Player not ready / disposed — keep the previous cached value.
      }
    });
  }

  /// Starts the 10s pulse loop. Idempotent — repeated calls while a timer is
  /// already running are a no-op (matches Android's `if (isPulseScheduled) return`).
  void _schedulePulse() {
    if (_pulseTimer?.isActive == true) return;
    _pulseTimer = Timer.periodic(_pulseInterval, (_) {
      fastPixMetrics.dispatchEvent(PlayerEvent.pulse);
    });
  }

  /// Stops the pulse loop. Idempotent.
  void _cancelPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  /// Applies the pulse start/stop policy after a successful dispatch.
  /// Mirrors FastPixBaseMedia3Player.kt:
  ///   schedule on viewBegin/play/playing/buffering;
  ///   cancel on pause/ended/error;
  ///   on seeked, schedule if the player is currently playing, else cancel;
  ///   everything else leaves the timer alone.
  void _applyPulsePolicy(PlayerEvent dispatched) {
    switch (dispatched) {
      case PlayerEvent.viewBegin:
      case PlayerEvent.play:
      case PlayerEvent.playing:
      case PlayerEvent.buffering:
        _schedulePulse();
        break;
      case PlayerEvent.pause:
      case PlayerEvent.ended:
      case PlayerEvent.error:
        _cancelPulse();
        break;
      case PlayerEvent.seeked:
        if (playerController.isPlaying() == true) {
          _schedulePulse();
        } else {
          _cancelPulse();
        }
        break;
      default:
        // buffered, seeking, variantChanged, playerReady, pulse, request*
        break;
    }
  }

  void start() {
    try {
      // Validate required data before starting
      if (videoData == null || videoData?.videoSourceUrl?.isEmpty == true) {
        throw Exception(
          'Invalid video data: videoData or videoUrl is null/empty',
        );
      }

      if (workspaceId.isEmpty) {
        throw Exception(
          'Invalid configuration: workspaceId is empty',
        );
      }

      if (viewerId.isEmpty) {
        throw Exception('Viewer Id cannot be empty');
      }

      fastPixMetrics =
          FastPixMetricsBuilder()
              .setPlayerObserver(this)
              .setMetricsConfiguration(
                MetricsConfiguration(
                  workspaceId: workspaceId,
                  beaconUrl: beaconUrl,
                  viewerId: viewerId,
                  videoData: videoData,
                  enableLogging: true,
                  playerData: playerData ?? PlayerData("better_player", playerController.betterPlayerConfiguration.aspectRatio.toString()),
                  customData: customData,
                ),
              )
              .build();
      _setupEventListener();
      _startPositionPolling();
      fastPixMetrics.dispatchEvent(PlayerEvent.playerReady);
      fastPixMetrics.dispatchEvent(PlayerEvent.viewBegin);
    } catch (e) {
      print('Error starting FastPix metrics: $e');
      rethrow;
    }
  }

  void _tryDispatch(PlayerEvent next, {BetterPlayerEvent? event}) {
    final allowed = validTransitions[_lastDispatchedEvent] ?? {};
    if (allowed.contains(next)) {
      if (_lastDispatchedEvent == PlayerEvent.ended &&
          next == PlayerEvent.play) {
        return;
      }
      if (next == PlayerEvent.variantChanged) {
        _handleChangedTrackEvent(event!);
        return;
      }
      if (next == PlayerEvent.error) {
        _errorModel = ErrorModel(
          event?.parameters?['exception'] ?? 'Unknown error',
          event?.parameters?['source'] ?? '503',
        );
      }
      fastPixMetrics.dispatchEvent(next);
      _lastDispatchedEvent = next;
      if (next == PlayerEvent.playing) {
        _isEndedCalled = false;
      }
      _applyPulsePolicy(next);
    } else {

      // ignore invalid transitions
    }
  }

  void _oniOSPlayerEvent(BetterPlayerEvent event) {
    if (!_isPlayerResolutionCalculationDone) {
      _calculatePlayerSize();
    }
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.play:
        _tryDispatch(PlayerEvent.play);
        break;

      case BetterPlayerEventType.progress:
        _calculatePlayerSize();
        if (_lastDispatchedEvent == PlayerEvent.buffering) {
          _tryDispatch(PlayerEvent.buffered);
        }
        if (_lastDispatchedEvent == PlayerEvent.seeking) {
          _tryDispatch(PlayerEvent.seeked);
        }
        if (_lastDispatchedEvent == PlayerEvent.seeked) {
          _tryDispatch(PlayerEvent.play);
        }
        if (_lastDispatchedEvent == PlayerEvent.play) {
          _tryDispatch(PlayerEvent.playing);
        }
        break;

      case BetterPlayerEventType.finished:
        final now = DateTime.now();
        if (_lastEndedAt != null &&
            now.difference(_lastEndedAt!).inSeconds < 2) {
          return;
        }
        _lastEndedAt = now;
        if (!_isEndedCalled) {
          _isEndedCalled = true;
          _lastEndedAt = now;
          _tryDispatch(PlayerEvent.pause);
          _tryDispatch(PlayerEvent.ended);
        }
        break;

      case BetterPlayerEventType.changedTrack:
        _tryDispatch(PlayerEvent.variantChanged, event: event);
        break;

      case BetterPlayerEventType.bufferingStart:
        _tryDispatch(PlayerEvent.buffering);
        break;

      case BetterPlayerEventType.bufferingEnd:
        _tryDispatch(PlayerEvent.buffered);
        break;

      case BetterPlayerEventType.pause:
        _tryDispatch(PlayerEvent.pause);
        break;

      case BetterPlayerEventType.seekTo:
        final now = DateTime.now();
        if (_lastSeekAt != null &&
            now.difference(_lastSeekAt!).inMilliseconds < 500) {
          return;
        }
        _lastSeekAt = now;
        if (_lastDispatchedEvent == PlayerEvent.seeking) {
          _tryDispatch(PlayerEvent.seeked);
        }
        if (_lastDispatchedEvent == PlayerEvent.buffering) {
          _tryDispatch(PlayerEvent.buffered);
        }
        _tryDispatch(PlayerEvent.pause);
        _tryDispatch(PlayerEvent.seeking);
        break;

      case BetterPlayerEventType.exception:
        _tryDispatch(PlayerEvent.error, event: event);
        break;

      default:
        break;
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!_isPlayerResolutionCalculationDone) {
      _calculatePlayerSize();
    }
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.play:
        _tryDispatch(PlayerEvent.play);
        break;

      case BetterPlayerEventType.progress:
        _calculatePlayerSize();
        if (_lastDispatchedEvent == PlayerEvent.buffering) {
          _tryDispatch(PlayerEvent.buffered);
        }
        if (_lastDispatchedEvent == PlayerEvent.seeking) {
          _tryDispatch(PlayerEvent.seeked);
        }
        if (_lastDispatchedEvent == PlayerEvent.seeked) {
          _tryDispatch(PlayerEvent.play);
        }
        if (_lastDispatchedEvent == PlayerEvent.play) {
          _tryDispatch(PlayerEvent.playing);
        }
        break;

      case BetterPlayerEventType.finished:
        final now = DateTime.now();
        if (_lastEndedAt != null &&
            now.difference(_lastEndedAt!).inSeconds < 2) {
          return;
        }
        _lastEndedAt = now;
        if (!_isEndedCalled) {
          _isEndedCalled = true;
          _lastEndedAt = now;
          _tryDispatch(PlayerEvent.pause);
          _tryDispatch(PlayerEvent.ended);
        }
        break;

      case BetterPlayerEventType.changedTrack:
        _tryDispatch(PlayerEvent.variantChanged, event: event);
        break;

      case BetterPlayerEventType.bufferingStart:
        _tryDispatch(PlayerEvent.buffering);
        break;

      case BetterPlayerEventType.bufferingEnd:
        _tryDispatch(PlayerEvent.buffered);
        break;

      case BetterPlayerEventType.pause:
        _tryDispatch(PlayerEvent.pause);
        break;

      case BetterPlayerEventType.seekTo:
        if (_lastDispatchedEvent == PlayerEvent.seeking) {
          _tryDispatch(PlayerEvent.seeked);
        }
        if (_lastDispatchedEvent == PlayerEvent.buffering) {
          _tryDispatch(PlayerEvent.buffered);
        }
        _tryDispatch(PlayerEvent.pause);
        _tryDispatch(PlayerEvent.seeking);
        break;

      case BetterPlayerEventType.exception:
        _tryDispatch(PlayerEvent.error, event: event);
        break;

      default:
        break;
    }
  }

  void _handleChangedTrackEvent(BetterPlayerEvent event) {
    final paramWidth = event.parameters?['width'];
    final paramHeight = event.parameters?['height'];
    final bitRate = event.parameters?['bitrate'];
    final frameRate = event.parameters?['frameRate'];
    final codec = event.parameters?['codecs'];
    final mimeType = event.parameters?['mimeType'];
    debugPrint("Video Width ===================> $paramWidth");
    debugPrint("Video Height ===================> $paramHeight");
    debugPrint("Video BitRate ===================> $bitRate");
    debugPrint("Video FrameRate ===================> $frameRate");
    debugPrint("Video Codec ===================> $codec");
    debugPrint("Video MimeType ===================> $mimeType");
    final Map<String, String> attributes = {};
    attributes['width'] =
        (paramWidth ??
                playerController.videoPlayerController?.value.size?.width
                    .toInt())
            .toString();
    attributes['height'] =
        (paramHeight ??
                playerController.videoPlayerController?.value.size?.height
                    .toInt())
            .toString();
    attributes['bitrate'] = bitRate.toString();
    attributes['frameRate'] = frameRate.toString();
    attributes['codecs'] = codec.toString();
    attributes['mimeType'] = mimeType.toString();

    fastPixMetrics.dispatchEvent(
      PlayerEvent.variantChanged,
      attributes: attributes,
    );
  }

  String _inferMimeTypeFromUrl(String url) {
    if (url.endsWith(".mp4")) return "video/mp4";
    if (url.endsWith(".m3u8")) return "application/x-mpegURL";
    if (url.endsWith(".webm")) return "video/webm";
    if (url.endsWith(".mov")) return "video/quicktime";
    return "application/octet-stream"; // fallback
  }



  void _calculatePlayerSize() {
    void tryReadSize() {
      final context = _playerDimensionKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null &&
            renderBox.hasSize &&
            renderBox.size.width > 0) {
          playerHeightSize = renderBox.size.height;
          playerWidthSize = renderBox.size.width;
          _isPlayerResolutionCalculationDone = true;
          debugPrint("=====================> Player Height $playerHeightSize}");
          debugPrint("=====================> Player Width $playerWidthSize}");
          return;
        }
      }
      // Try again on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => tryReadSize());
    }

    // Start checking size
    WidgetsBinding.instance.addPostFrameCallback((_) => tryReadSize());
  }

  void reportPlayerSize(GlobalKey key) {
    _playerDimensionKey = key;
  }


  void _setupEventListener() {
    if (Platform.isIOS) {
      playerController.addEventsListener(_oniOSPlayerEvent);
    } else {
      playerController.addEventsListener(_onPlayerEvent);
    }
  }

  BetterPlayerAsmsTrack? get _activeTrack =>
      playerController.betterPlayerAsmsTrack;

  Size? get _videoSize => playerController.videoPlayerController?.value.size;

  @override
  int? playerHeight() =>
      playerHeightSize > 0 ? playerHeightSize.toInt() : null;

  @override
  int? playerWidth() =>
      playerWidthSize > 0 ? playerWidthSize.toInt() : null;

  @override
  int? videoSourceWidth() {
    final trackWidth = _activeTrack?.width;
    if (trackWidth != null && trackWidth > 0) return trackWidth;
    return _videoSize?.width.toInt();
  }

  @override
  int? videoSourceHeight() {
    final trackHeight = _activeTrack?.height;
    if (trackHeight != null && trackHeight > 0) return trackHeight;
    return _videoSize?.height.toInt();
  }

  // Reads the cached playhead populated by [_startPositionPolling] — the SDK
  // calls this synchronously and cannot await the platform channel.
  @override
  int? playHeadTime() => _lastKnownPlayheadMs;

  @override
  String? mimeType() {
    final trackMime = _activeTrack?.mimeType;
    if (trackMime != null && trackMime.isNotEmpty) return trackMime;
    final url = playerController.betterPlayerDataSource?.url;
    if (url == null || url.isEmpty) return null;
    return _inferMimeTypeFromUrl(url);
  }

  @override
  int? sourceFps() => _activeTrack?.frameRate;

  @override
  String? sourceAdvertisedBitrate() => _activeTrack?.bitrate?.toString();

  @override
  int? sourceAdvertiseFrameRate() => _activeTrack?.frameRate;

  @override
  int? sourceDuration() => playerController
      .videoPlayerController
      ?.value
      .duration
      ?.inMilliseconds;

  @override
  bool? isPause() {
    final playing = playerController.isPlaying();
    if (playing == null) return null;
    return !playing;
  }

  @override
  bool? isAutoPlay() => playerController.betterPlayerConfiguration.autoPlay;

  @override
  bool? preLoad() => false;

  @override
  bool? isBuffering() =>
      playerController.videoPlayerController?.value.isBuffering;

  @override
  String? playerCodec() {
    final codecs = _activeTrack?.codecs;
    return (codecs == null || codecs.isEmpty) ? null : codecs;
  }

  @override
  String? sourceHostName() {
    final url = playerController.betterPlayerDataSource?.url;
    if (url == null || url.isEmpty) return null;
    final host = Uri.tryParse(url)?.host;
    return (host == null || host.isEmpty) ? null : host;
  }

  @override
  bool? isLive() => playerController.isLiveStream();

  @override
  String? sourceUrl() => playerController.betterPlayerDataSource?.url;

  @override
  bool? isFullScreen() => playerController.isFullScreen;

  @override
  ErrorModel getPlayerError() =>
      _errorModel ?? ErrorModel('', '');

  @override
  String? getVideoCodec() => playerCodec();

  @override
  String? getSoftwareName() => LibraryInfo.libraryName;

  @override
  String? getSoftwareVersion() => LibraryInfo.libraryVersion;
}

class FastPixBaseVideoPlayerBuilder {
  // Required
  final BetterPlayerController _playerController;
  final String _workspaceId;
  final String? _beaconUrl;
  final String _viewerId;

  // Optional with default
  bool _enabledLogging = false;
  PlayerData? _playerData;
  VideoData? _videoData;
  CustomData? _customData;

  FastPixBaseVideoPlayerBuilder({
    required BetterPlayerController playerController,
    required String workspaceId,
    String? beaconUrl,
    required String viewerId,
  }) : _beaconUrl = beaconUrl,
       _workspaceId = workspaceId,
       _playerController = playerController,
       _viewerId = viewerId;

  FastPixBaseVideoPlayerBuilder setEnabledLogging(bool value) {
    _enabledLogging = value;
    return this;
  }

  FastPixBaseVideoPlayerBuilder setCustomData(CustomData value) {
    _customData = value;
    return this;
  }

  FastPixBaseVideoPlayerBuilder setPlayerData(PlayerData? value) {
    _playerData = value;
    return this;
  }

  FastPixBaseVideoPlayerBuilder setVideoData(VideoData? value) {
    _videoData = value;
    return this;
  }

  FastPixBaseBetterPlayer build() {
    return FastPixBaseBetterPlayer._builder(this);
  }
}
