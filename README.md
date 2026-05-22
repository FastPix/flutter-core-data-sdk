# Flutter Core SDK

A comprehensive Flutter SDK for video player analytics and event tracking, designed to provide detailed insights into video playback behavior and user engagement metrics.

## Features

- **Comprehensive Event Tracking**: Monitor all video player events including play, pause, seeking, buffering, and more
- **Real-time Analytics**: Track view watch time, player state changes, and user engagement metrics
- **Flexible Configuration**: Customizable workspace IDs, beacon URLs, and custom data fields
- **Lifecycle Management**: Automatic app lifecycle handling and session management
- **Cross-platform Support**: Works seamlessly on both iOS and Android platforms
- **Performance Optimized**: Efficient event dispatching and state management
- **Extensible Architecture**: Easy to extend with custom events and data models

## Installation

Add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  fastpix_resumable_uploader: ^2.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

`FastPixMetrics` now requires a `PlayerObserver` implementation that exposes real-time state from your video player. The SDK reads from the observer synchronously when building events, so all of its getters must return cached/immediate values.

```dart
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';

final metrics = FastPixMetricsBuilder()
  .setPlayerObserver(myPlayerObserver) // your impl of PlayerObserver
  .setMetricsConfiguration(MetricsConfiguration(
    workspaceId: 'your-workspace-id',
    beaconUrl: 'https://your-beacon-url.com',
    viewerId: 'user-123',
    videoData: VideoData(
      videoId: 'movie-42',
      videoTitle: 'Trailer',
      videoSourceUrl: 'https://stream.example.com/movie.m3u8',
    ),
  ))
  .build();

// Dispatch player events as they happen. The SDK serializes them in
// submission order and persists them to a SQLite-backed queue.
metrics.dispatchEvent(PlayerEvent.playerReady);
metrics.dispatchEvent(PlayerEvent.viewBegin);
metrics.dispatchEvent(PlayerEvent.play);
```

See the [example app](example/) for a full BetterPlayer integration including a reference `PlayerObserver` implementation.

## Usage / API Reference

### Core Classes

#### FastPixMetrics
The main entry point for the SDK. Built via `FastPixMetricsBuilder`.

```dart
class FastPixMetrics {
  // Dispatch any player event. Optional `attributes` map is currently used
  // by `variantChanged` to populate ChangeTrack (width, height, bitrate,
  // frameRate, codecs, mimeType).
  Future<void> dispatchEvent(PlayerEvent event, {Map<String, String>? attributes});

  // Flush pending events and finalize the view. Pass `playheadOverride`
  // to record a final playhead value when the player is being torn down.
  Future<void> dispose(bool emitViewCompleted, {int? playheadOverride});
}
```

#### MetricsConfiguration
Configuration object passed to `FastPixMetricsBuilder.setMetricsConfiguration(...)`.

```dart
class MetricsConfiguration {
  final PlayerData? playerData;
  final String? workspaceId;   // required
  final String? beaconUrl;     // required
  final String? viewerId;      // required
  final VideoData? videoData;
  final bool enableLogging;
  final CustomData? customData;
}
```

#### PlayerEvent
Enumeration of all supported video player events:

- `play` - Video playback started *(automatically triggers viewBegin and playerReady)*
- `pause` - Video playback paused
- `playing` - Video is currently playing
- `seeking` - User is seeking to a new position
- `seeked` - Seek operation completed
- `buffering` - Video is buffering
- `buffered` - Buffering completed
- `variantChanged` - Video quality/bitrate changed
- `viewBegin` - Video view session started *(handled automatically by SDK)*
- `viewCompleted` - Video view session completed
- `playerReady` - Player is ready to play *(handled automatically by SDK)*
- `ended` - Video playback ended
- `error` - Player error occurred
- `pulse` - Periodic heartbeat event

### Builder Pattern

```dart
final metrics = FastPixMetricsBuilder()
  .setPlayerObserver(myPlayerObserver)
  .setMetricsConfiguration(MetricsConfiguration(
    workspaceId: 'workspace-123',
    beaconUrl: 'https://analytics.example.com',
    viewerId: 'user-456',
    playerData: playerData,
    videoData: videoData,
    customData: customData,
    enableLogging: true,
  ))
  .build();
```

> **Breaking change in 2.0.0**: the per-field setter style (`setWorkSpaceId`, `setBeaconUrl`, etc.) on `FastPixMetrics.builder()` has been replaced. See [CHANGELOG.md](CHANGELOG.md) for the full migration guide.

### PlayerObserver

`PlayerObserver` is the synchronous bridge between your video player and the SDK. The SDK calls these getters when building each event, so every method must return immediately — never await a platform channel inside an override. Host an internal cache (poll the player at a 250 ms cadence) and serve it from these getters.

```dart
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
```

A reference BetterPlayer-backed implementation lives in [example/lib/fastpix_data_better_player.dart](example/lib/fastpix_data_better_player.dart).

#### Reporting player size (`playerWidth` / `playerHeight`)

Flutter players don't expose their on-screen dimensions through their controllers — those values live on the *widget tree*. The SDK therefore can't pull them for you. Your `PlayerObserver` implementation has to measure the player widget itself and cache the result; `playerWidth()` / `playerHeight()` then return that cache.

The reference impl uses a `GlobalKey` attached to the player widget, reads the `RenderBox` size after the first frame, and updates the cache on layout changes:

```dart
class MyPlayerObserver implements PlayerObserver {
  double _playerWidth = 0;
  double _playerHeight = 0;
  GlobalKey _playerKey = GlobalKey();

  // Call this from your widget once, passing the key you attached to the
  // player widget (see usage below).
  void reportPlayerSize(GlobalKey key) {
    _playerKey = key;
    _measure();
  }

  void _measure() {
    void read() {
      final ctx = _playerKey.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0) {
        _playerWidth = box.size.width;
        _playerHeight = box.size.height;
        return;
      }
      // Layout hasn't settled yet — retry next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => read());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => read());
  }

  @override
  int? playerWidth()  => _playerWidth  > 0 ? _playerWidth.toInt()  : null;
  @override
  int? playerHeight() => _playerHeight > 0 ? _playerHeight.toInt() : null;
  // ...remaining overrides
}
```

Then in your widget, declare a `GlobalKey` on your State, attach it to the player widget, and hand the same key to the observer **after** you've built the metrics object but **before** dispatching the first event. This mirrors the example app exactly — see [example/lib/main.dart](example/lib/main.dart):

```dart
class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late BetterPlayerController _betterPlayerController;
  late FastPixBaseBetterPlayer _fastPixPlayer;
  final GlobalKey _playerKey = GlobalKey(); // 1. declare on the State

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(autoPlay: true, looping: false),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.video.url,
        videoFormat: BetterPlayerVideoFormat.hls,
        useAsmsTracks: true,
      ),
    );

    _fastPixPlayer = FastPixBaseVideoPlayerBuilder(
      playerController: _betterPlayerController,
      workspaceId: 'your-workspace-id',
      viewerId: Uuid().v4(),
    )
      .setVideoData(VideoData(
        videoId: widget.video.id,
        videoSourceUrl: widget.video.url,
        videoTitle: 'video-title',
      ))
      .setPlayerData(PlayerData('better_player', '1.0.8'))
      .setEnabledLogging(true)
      .build();

    // 2. hand the key to the observer AFTER build, BEFORE start
    _fastPixPlayer.reportPlayerSize(_playerKey);
    _fastPixPlayer.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Playing: ${widget.video.id}')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            // 3. attach the same key to the player widget itself —
            //    its RenderBox is what gets measured.
            child: BetterPlayer(
              key: _playerKey,
              controller: _betterPlayerController,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fastPixPlayer.disposeMetrix(); // flushes and tears down the SDK
    super.dispose();
  }
}
```

If you skip this wiring, `playerWidth()` / `playerHeight()` will return `null` and the corresponding analytics fields will not be reported.

## Configuration

### Required Parameters

- **workspaceId**: Unique identifier for your workspace/application
- **beaconUrl**: Endpoint URL for sending analytics data
- **viewerId**: Unique identifier for the current user/viewer

### Important Note

**Automatic Event Handling**: The SDK automatically manages `viewBegin` and `playerReady` events when you dispatch the `play` event. Developers only need to dispatch the `play` event - the SDK handles the rest internally for optimal analytics tracking.

### Optional Parameters

- **playerData**: Information about the video player (name, version, etc.)
- **videoData**: Video metadata (title, duration, quality, etc.)
- **customData**: Additional custom fields for your analytics
- **enableLogging**: Enable/disable debug logging

### Environment Setup

1. **Workspace Configuration**: Set up your analytics workspace and obtain the workspace ID
2. **Beacon Endpoint**: Configure your analytics server endpoint
3. **User Identification**: Implement a system to generate unique viewer IDs

## Examples

### Basic Video Player Integration

```dart
class VideoPlayerWidget extends StatefulWidget {
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late FastPixMetrics metrics;
  late MyPlayerObserver observer; // your impl of PlayerObserver

  @override
  void initState() {
    super.initState();
    observer = MyPlayerObserver(/* hand it your player controller */);

    metrics = FastPixMetricsBuilder()
      .setPlayerObserver(observer)
      .setMetricsConfiguration(MetricsConfiguration(
        workspaceId: 'video-app-123',
        beaconUrl: 'https://analytics.videoapp.com',
        viewerId: 'user-${DateTime.now().millisecondsSinceEpoch}',
        videoData: VideoData(
          videoId: 'movie-42',
          videoSourceUrl: 'https://stream.example.com/movie.m3u8',
        ),
      ))
      .build();

    metrics.dispatchEvent(PlayerEvent.playerReady);
    metrics.dispatchEvent(PlayerEvent.viewBegin);
  }

  void onPlay()  => metrics.dispatchEvent(PlayerEvent.play);
  void onPause() => metrics.dispatchEvent(PlayerEvent.pause);

  void onSeekStart() => metrics.dispatchEvent(PlayerEvent.seeking);
  void onSeekEnd()   => metrics.dispatchEvent(PlayerEvent.seeked);

  @override
  void dispose() {
    // Flushes pending events and emits viewCompleted.
    metrics.dispose(true, playheadOverride: observer.playHeadTime());
    super.dispose();
  }
}
```

### Custom Data Integration

`CustomData` now holds up to 10 named fields on a single object (was a `List<CustomData>` in 1.x).

```dart
final customData = CustomData(
  'movie',   // customField1
  'action',  // customField2
  '2026',    // customField3
  null, null, null, null, null, null, null,
);

final metrics = FastPixMetricsBuilder()
  .setPlayerObserver(observer)
  .setMetricsConfiguration(MetricsConfiguration(
    workspaceId: 'workspace-123',
    beaconUrl: 'https://beacon.example.com',
    viewerId: 'user-789',
    customData: customData,
  ))
  .build();
```

### Advanced Event Tracking

```dart
// Track events with additional attributes. The `variantChanged` event
// reads these and persists them as ChangeTrack; subsequent events
// (pulse, play, error, viewBegin, etc.) will pick them up.
//
// If any of these are missing or set to '0'/empty string, the SDK falls
// back to the corresponding PlayerObserver getter (new in 2.0.0).
await metrics.dispatchEvent(
  PlayerEvent.variantChanged,
  attributes: {
    'height': '1080',
    'width': '1920',
    'bitrate': '5000000',
    'frameRate': '30',
    'codecs': 'avc1.640028',
    'mimeType': 'video/mp4',
  },
);
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support
- **Email**: support@fastpix.com

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes and updates.

---

**Made with ❤️ by the Flutter Core SDK Team**
