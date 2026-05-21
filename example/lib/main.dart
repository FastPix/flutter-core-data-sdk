import 'package:better_player_plus/better_player_plus.dart';
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';
import 'package:fastpix_flutter_core_data_example/fastpix_data_better_player.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const FastPixExampleApp());
}

class FastPixExampleApp extends StatelessWidget {
  const FastPixExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastPix Core Data SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoListScreen(),
    );
  }
}

/// Test-data row. `id` doubles as the `videoId` we send to FastPix; `url` is
/// the HLS stream BetterPlayer plays.
class DummyVideo {
  final String id;
  final String url;
  const DummyVideo(this.id, this.url);
}

const _dummyData = <DummyVideo>[
  DummyVideo(
    '3e8a1bd0-b0f9-4539-90e7-de53fd46696f',
    'https://stream.fastpix.co/3e8a1bd0-b0f9-4539-90e7-de53fd46696f.m3u8',
  ),
  DummyVideo(
    '86520338-ede2-409e-b44e-da1dd4f73783',
    'https://stream.fastpix.io/86520338-ede2-409e-b44e-da1dd4f73783.m3u8',
  ),
  DummyVideo(
    '7e7167ce-13dc-47e7-bad1-1541907ba3d4',
    'https://stream.fastpix.io/7e7167ce-13dc-47e7-bad1-1541907ba3d4.m3u8',
  ),
  DummyVideo(
    '5272e13b-4454-4622-8268-4b3f17970f2c',
    'https://stream.fastpix.co/5272e13b-4454-4622-8268-4b3f17970f2c.m3u8',
  ),
  DummyVideo(
    '16ac212a-0f4f-49c5-9fd7-a42d9ff61541',
    'https://stream.fastpix.io/16ac212a-0f4f-49c5-9fd7-a42d9ff61541.m3u8',
  ),
  DummyVideo(
    '3ad91e5f-0f45-403f-bda0-2a668a3581ee',
    'https://stream.fastpix.io/3ad91e5f-0f45-403f-bda0-2a668a3581ee.m3u8',
  ),
  DummyVideo(
    '46c09d0c-d97a-44b2-9737-c5e6daf30a41',
    'https://stream.fastpix.io/46c09d0c-d97a-44b2-9737-c5e6daf30a41.m3u8',
  ),
  DummyVideo(
    'd81105da-c78a-482e-b1dc-d89e10d8d682',
    'https://stream.fastpix.io/d81105da-c78a-482e-b1dc-d89e10d8d682.m3u8',
  ),
  DummyVideo(
    'f19268f5-9719-403f-87c9-b604fb3bdce3',
    'https://stream.fastpix.io/f19268f5-9719-403f-87c9-b604fb3bdce3.m3u8',
  ),
  DummyVideo(
    '112a2222-0f31-44a0-bcf6-30cfa6e1d17d',
    'https://stream.fastpix.io/112a2222-0f31-44a0-bcf6-30cfa6e1d17d.m3u8',
  ),
  DummyVideo(
    'ca854fd4-a3d0-4525-bd43-80de50887e1a',
    'https://stream.fastpix.io/ca854fd4-a3d0-4525-bd43-80de50887e1a.m3u8',
  ),
];

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FastPix Sample Videos')),
      body: ListView.separated(
        itemCount: _dummyData.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final video = _dummyData[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(
              'Video ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              video.id,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(video: video),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.video});

  final DummyVideo video;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late BetterPlayerController _betterPlayerController;
  late FastPixBaseBetterPlayer _fastPixPlayer;

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
        useAsmsAudioTracks: true,
        useAsmsSubtitles: true,
      ),
    );

    _fastPixPlayer = FastPixBaseVideoPlayerBuilder(
      playerController: _betterPlayerController,
      workspaceId: '1109888358169935873',
      viewerId: Uuid().v4(),
    )
        .setVideoData(
          VideoData(
            'Video ${widget.video.id}',
            widget.video.id,
            widget.video.url,
            'thumbnail_url',
          ),
        )
        .setEnabledLogging(true)
        .build();

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
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fastPixPlayer.disposeMetrix();
    super.dispose();
  }
}
