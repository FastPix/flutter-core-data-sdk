---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Reproduction Steps

1. **Setup Environment**

```yaml
dependencies:
  flutter_core_sdk: ^1.0.2
```

2. **Code To Reproduce**

```dart
// If you added/updated code examples, include them here
  final metrics = FastPixMetrics.builder()
    .setWorkSpaceId('your-workspace-id')
    .setBeaconUrl('https://your-beacon-url.com')
    .setViewerId('user-123')
    .build();

  metrics.dispatchEvent(PlayerEvent.play);
```

3. **Expected Behavior**
```
<!-- A clear and concise description of what you expected to happen.  -->
```

4. **Actual Behavior**
```
<!-- A clear and concise description of what actually happened. -->
```

5. **Environment**

- **SDK Version**: [e.g., 1.2.2]
- **Android Version**: [e.g., Android 12]
- **Min SDK Version**: [e.g., 24]
- **Target SDK Version**: [e.g., 35]
- **Device/Emulator**: [e.g., Pixel 5, Android Emulator]
- **Player**: [e.g., ExoPlayer 2.19.0, VideoView, etc.]
- **Kotlin Version**: [e.g., 2.0.21]

## Code Sample

```dart
// Please provide a minimal code sample that reproduces the issue
// If you added/updated code examples, include them here
  final metrics = FastPixMetrics.builder()
    .setWorkSpaceId('your-workspace-id')
    .setBeaconUrl('https://your-beacon-url.com')
    .setViewerId('user-123')
    .build();

  metrics.dispatchEvent(PlayerEvent.play);
```

## Logs/Stack Trace

```
Paste relevant logs or stack traces here
```

## Additional Context

Add any other context about the problem here.

## Screenshots

If applicable, add screenshots to help explain your problem.

