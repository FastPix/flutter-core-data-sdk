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
  flutter_core_sdk: ^1.0.2
```

Then run:

```bash
flutter pub get
```

## Quick Start

Here's a minimal example to get you started:

```dart
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';

void main() {
  // Configure the SDK
  final metrics = FastPixMetrics.builder()
    .setWorkSpaceId('your-workspace-id')
    .setBeaconUrl('https://your-beacon-url.com')
    .setViewerId('user-123')
    .build();

  // Track player events - only dispatch play event
  // SDK automatically handles viewBegin and playerReady internally
  metrics.dispatchEvent(PlayerEvent.play);
}
```

## Usage / API Reference

### Core Classes

#### FastPixMetrics
The main entry point for the SDK. Handles event dispatching and configuration management.

```dart
class FastPixMetrics {
  // Dispatch player events
  // Note: Only dispatch play event - SDK automatically handles viewBegin and playerReady
  Future<void> dispatchEvent(PlayerEvent event, {Map<String, String>? attributes});
  
  // Get current player observer
  PlayerObserver get playerObserver;
}
```

#### MetricsConfiguration
Configuration class for setting up the SDK with required parameters.

```dart
class MetricsConfiguration {
  final PlayerData? playerData;
  final String? workspaceId;
  final String? beaconUrl;
  final String? viewerId;
  final VideoData? videoData;
  final bool enableLogging;
  final List<CustomData>? customData;
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

The SDK uses a builder pattern for easy configuration:

```dart
final metrics = FastPixMetrics.builder()
  .setWorkSpaceId('workspace-123')
  .setBeaconUrl('https://analytics.example.com')
  .setViewerId('user-456')
  .setPlayerData(playerData)
  .setVideoData(videoData)
  .setCustomData(customDataList)
  .isEnableLogging(true)
  .build();
```

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
  
  @override
  void initState() {
    super.initState();
    
    // Initialize SDK
    metrics = FastPixMetrics.builder()
      .setWorkSpaceId('video-app-123')
      .setBeaconUrl('https://analytics.videoapp.com')
      .setViewerId('user-${DateTime.now().millisecondsSinceEpoch}')
      .build();
      
    // Note: No need to dispatch playerReady or viewBegin events
    // SDK handles these automatically when play event is dispatched
  }
  
  void onPlay() {
    // Only dispatch play event - SDK automatically handles viewBegin and playerReady
    metrics.dispatchEvent(PlayerEvent.play);
  }
  
  void onPause() {
    metrics.dispatchEvent(PlayerEvent.pause);
  }
  
  void onSeek(Duration position) {
    metrics.dispatchEvent(PlayerEvent.seeking);
    // After seek completes
    metrics.dispatchEvent(PlayerEvent.seeked);
  }
}
```

### Custom Data Integration

```dart
// Create custom data fields
final customData = [
  CustomData(value: 'movie'),
  CustomData(value: 'action'),
  CustomData(value: '2024'),
];

// Configure SDK with custom data
final metrics = FastPixMetrics.builder()
  .setWorkSpaceId('workspace-123')
  .setBeaconUrl('https://beacon.example.com')
  .setViewerId('user-789')
  .setCustomData(customData)
  .build();
```

### Advanced Event Tracking

```dart
// Track events with additional attributes
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
- **Email**: support@fastpix.io

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes and updates.

---

**Made with ❤️ by the Flutter Core SDK Team**
