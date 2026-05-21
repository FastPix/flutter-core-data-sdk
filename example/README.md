# fastpix_flutter_core_data_example

Example Flutter app that demonstrates how to integrate the
[`fastpix_flutter_core_data`](../) SDK with a real video player. The same
codebase runs on **Android** and **iOS**.

## What this example shows

- Building a `MetricsConfiguration` with workspace, beacon, viewer, player and
  video data.
- Implementing the `PlayerObserver` mixin against `package:video_player`.
- Dispatching `PlayerEvent`s (`play`, `pause`, `seeking`, `seeked`,
  `buffering`, `buffered`, `ended`, `error`) at the right points in the player
  lifecycle.
- Cleanly disposing the SDK alongside the video controller.

## Running

From the repo root:

```bash
cd example
flutter pub get
flutter run            # picks any connected device / simulator
```

To target a specific platform:

```bash
flutter run -d ios
flutter run -d android
```

## Configure your workspace

Open [lib/main.dart](lib/main.dart) and replace the placeholders inside
`_setupPlayer()`:

```dart
.setWorkSpaceId('your-workspace-id')
.setBeaconUrl('https://metrix.ws.fastpix.io/v1/metrix')
.setViewerId('viewer-...')
```

The default video URL points at a public FastPix HLS sample. Swap it for your
own stream if you want to validate end-to-end with your beacon.

## Platform notes

- **iOS** — `ios/Runner/Info.plist` enables `NSAllowsArbitraryLoads` so the
  example works with both HTTP and HTTPS sources. Tighten this for production.
- **Android** — `android/app/src/main/AndroidManifest.xml` declares the
  `INTERNET` permission and `usesCleartextTraffic="true"` for the same reason.
