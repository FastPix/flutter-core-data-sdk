import '../services/service_locator.dart';
import '../util/scaling_tracker.dart';
import 'event_base.dart';

class ViewCompletedEvent extends BaseEvent {
  final String? videoContentPlaybackTime;
  final String? viewTotalContentPlayBackTime;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final double? viewMaxUpScalePercentage;
  final double? viewMaxDownScalePercentage;
  final double? viewTotalUpScaling;
  final double? viewTotalDownScaling;
  final String? videoDuration;
  final String? playerWidth;
  final String? playerHeight;
  final String? videoWidth;
  final String? videoHeight;

  ViewCompletedEvent({
    super.workSpaceId,
    super.viewId,
    super.viewSequenceNumber,
    super.playerSequenceNumber,
    super.beaconDomain,
    super.playheadTime,
    super.viewerTimeStamp,
    super.playerInstanceId,
    super.viewWatchTime,
    super.connectionType,
    super.isPlayerFullScreen,
    this.videoContentPlaybackTime,
    this.viewTotalContentPlayBackTime,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
    this.viewMaxUpScalePercentage,
    this.viewMaxDownScalePercentage,
    this.viewTotalUpScaling,
    this.viewTotalDownScaling,
    this.videoDuration,
    this.playerWidth,
    this.playerHeight,
    this.videoWidth,
    this.videoHeight,
  }) : super(eventName: 'viewCompleted');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vectpbti': videoContentPlaybackTime,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'vdsodu': videoDuration,
      'plwt': playerWidth,
      'plht': playerHeight,
      'rqvdwt': videoWidth,
      'rqvdht': videoHeight,
    };
  }

  /// Synchronous on purpose. The `async` keyword would force a synthetic
  /// Future + microtask hop on the return path, which is invisible in
  /// normal runtime but gets starved during Android's `detached` lifecycle
  /// window when this event is fired by dispose(). Building viewCompleted
  /// is pure data assembly — no awaits needed — so making it sync
  /// guarantees we reach `_eventDispatcher.dispatch()` (the sqflite
  /// persistence step) before the OS reclaims the isolate.
  static ViewCompletedEvent createViewCompletedEvent({
    int? playheadOverride,
  }) {
    final configService = ServiceLocator().configurationService;
    final baseData = BaseEvent.getBaseEventData(configService);
    final metrix = ServiceLocator().metricsStateManager;
    final playerObserver = configService.playerObserver;
    configService.calculateScalingForCurrentInterval(
      playheadOverride: playheadOverride,
    );
    final tracker = ScalingTracker.instance;
    final bufferFrequency = metrix.getRebufferFrequency();
    return ViewCompletedEvent(
      workSpaceId: baseData.workSpaceId,
      viewId: baseData.viewId,
      viewSequenceNumber: baseData.viewSequenceNumber,
      playerSequenceNumber: baseData.playerSequenceNumber,
      beaconDomain: baseData.beaconDomain,
      playheadTime: playheadOverride ?? baseData.playheadTime,
      viewerTimeStamp: baseData.viewerTimeStamp,
      playerInstanceId: baseData.playerInstanceId,
      viewWatchTime: baseData.viewWatchTime,
      connectionType: baseData.connectionType,
      isPlayerFullScreen: baseData.isPlayerFullScreen,
      videoContentPlaybackTime: tracker.totalPlaybackTime.toString(),
      viewTotalContentPlayBackTime: tracker.totalPlaybackTime.toString(),
      viewMaxUpScalePercentage: tracker.currentMaxUpscale,
      viewMaxDownScalePercentage: tracker.currentMaxDownscale,
      viewTotalUpScaling: tracker.totalUpscalingTimeWeighted,
      viewTotalDownScaling: tracker.totalDownscalingTimeWeighted,
      viewRebufferDuration: metrix.viewRebufferDuration.toString(),
      viewBufferPercentage: metrix.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      videoDuration: playerObserver?.videoSourceDuration().toString(),
      playerWidth: playerObserver?.playerWidth().round().toString(),
      playerHeight: playerObserver?.playerHeight().round().toString(),
      videoWidth: configService.changeTrack?.width == null
          ? playerObserver?.videoSourceWidth().toString()
          : configService.changeTrack?.width?.toString(),
      videoHeight: configService.changeTrack?.height == null
          ? playerObserver?.videoSourceHeight().toString()
          : configService.changeTrack?.height?.toString(),
    );
  }
}
