# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-05-22

A major release with significant architectural changes. **This release contains breaking API changes** — see the *Breaking Changes* section below for the migration steps.

### Added
- **SQLite-backed `EventStore`** for disk-persisted event queueing so events survive process death and slow networks.
- **`SubmissionPipeline`** that builds and dispatches events strictly in submission order, eliminating race conditions between fast follow-up events (e.g. `pause` → `seeking` → `seeked`).
- **`ScalingTracker`** for time-weighted video scaling analytics (up-scale / down-scale durations and percentages).
- **Request-level events**: `requestCompleted`, `requestCanceled`, `requestFailed` for HTTP/segment-fetch instrumentation.
- **App lifecycle handling**: automatic background flushing and `viewCompleted` emission on app kill.
- **Independent view and player sequence counters** so cross-counter ordering matches the wire-format spec.
- **Exponential backoff** for failed event deliveries.
- **Synchronous playhead polling pattern** — hosts cache the playhead and the SDK reads it synchronously, avoiding platform-channel deadlocks during codec init.
- **Enhanced `MetricsLogger`** with ANSI color coding and debug trace points (`dispatch:received`, `process:start`, etc.).
- **Comprehensive example app** for Android and iOS demonstrating BetterPlayer integration.
- New `VariantChangedEvent` field-level fallback: when `ChangeTrack` is missing or contains placeholder `'0'`/empty values (e.g. from BetterPlayer's HLS-parser defaults), the SDK now falls back to the `PlayerObserver` for `videoSourceWidth`, `videoSourceHeight`, `mimeType`, `frameRate`, and `bitrate`.
- Expanded `PlayerObserver` interface with: `playerHeight`, `playerWidth`, `videoSourceWidth`, `videoSourceHeight`, `playHeadTime`, `mimeType`, `sourceFps`, `sourceAdvertisedBitrate`, `sourceAdvertiseFrameRate`, `sourceDuration`, `isPause`, `isAutoPlay`, `preLoad`, `isBuffering`, `playerCodec`, `sourceHostName`, `isLive`, `sourceUrl`, `isFullScreen`, `getPlayerError`, `getVideoCodec`, `getSoftwareName`, `getSoftwareVersion`.
- Expanded `VideoData` with `videoCDN`, `videoDrmType`, `videoSeries`, `videoProducer`, `videoContentType`, `videoVariant`, `videoLanguage`, `fpPlaybackId`, `foMediaId`, `fpLiveStreamId`.

### Changed
- **`PlayerObserver` is now an `abstract interface class`** (formerly a mixin). Hosts must `implement` it and provide every getter.
- **`FastPixMetricsBuilder` API**: replaces the per-field setters on `FastPixMetrics.builder()`. The new builder takes a `MetricsConfiguration` object and a `PlayerObserver` instance.
- **`CustomData`** is now a single object with `customField1`–`customField10` (formerly a `List<CustomData>` with a `value` field).
- `MetricsConfiguration.customData` is now `CustomData?` (singular) instead of `List<CustomData>?`.
- Repository and homepage URLs updated to the `fastpix.com` domain.

### Breaking Changes

Migrating from `1.x` to `2.0.0`:

1. **Implement `PlayerObserver`** on your host player class. Every getter must return real data from your player. See README for the full interface and a BetterPlayer reference implementation.
2. **Replace the old builder** with the new one:
   ```dart
   // Before (1.x)
   final metrics = FastPixMetrics.builder()
     .setWorkSpaceId('ws')
     .setBeaconUrl('https://beacon')
     .setViewerId('v1')
     .build();

   // After (2.0.0)
   final metrics = FastPixMetricsBuilder()
     .setPlayerObserver(myPlayerObserver)
     .setMetricsConfiguration(MetricsConfiguration(
       workspaceId: 'ws',
       beaconUrl: 'https://beacon',
       viewerId: 'v1',
     ))
     .build();
   ```
3. **Update `CustomData` usage** — pass a single object with named fields:
   ```dart
   // Before (1.x)
   final customData = [CustomData(value: 'movie'), CustomData(value: 'action')];

   // After (2.0.0)
   final customData = CustomData(
     'movie',  // customField1
     'action', // customField2
     // ...customField3..10
   );
   ```
4. **Cache the playhead in your host** and return it synchronously from `PlayerObserver.playHeadTime()`. The SDK no longer awaits the platform channel during event dispatch.

### Fixed
- `_handleChangedTrackEvent` previously poisoned `ChangeTrack` with placeholder zeros/empty strings on the BetterPlayer init-time `defaultTrack` dispatch, masking real values on subsequent events. Subsequent event builds now coalesce empty/`'0'` track values to the observer fallback.

## [1.0.2] - 2025-08-29

### Added
- Made beacon url non mandatory and updated with production one

## [1.0.1] - 2025-08-29

### Added
- Exposed Error model import via the library entrypoint, allowing direct access without separate imports.


## [1.0.0] - 2025-08-28

### Added
- Initial release of the Flutter Core SDK
- Core functionality:
  - Video playback event tracking and analytics
  - Device information utilities and platform detection
  - Network connectivity monitoring and status tracking
  - Session management and lifecycle handling
  - Event dispatching system with buffering capabilities
  - Configuration management with flexible builder pattern
- Documentation files:
  - Comprehensive README.md with setup instructions
  - Usage examples and integration guides
  - API reference documentation
  - Contributing guidelines and development setup
- Basic project structure:
  - Flutter package build system and configuration
  - Pubspec.yaml with dependency management
  - Test framework integration and example tests
  - Code quality tools (lints, analysis options)
  - CI/CD pipeline configuration (Azure Pipelines)
  - SonarQube integration for code quality analysis
