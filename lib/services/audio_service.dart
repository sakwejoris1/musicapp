import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:ui' show Color;
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

/// Call once in main() before runApp:
///   _audioHandler = await AudioService.init(
///     builder: () => ChuyassiAudioHandler(),
///     config: const AudioServiceConfig(...),
///   );
Future<ChuyassiAudioHandler> initAudioService() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  return AudioService.init(
    builder: () => ChuyassiAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musicapp.audio',
      androidNotificationChannelName: 'Chuyassi Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF7C4DFF),
      androidNotificationIcon: 'mipmap/ic_launcher',
      preloadArtwork: true,
    ),
  );
}

/// [ChuyassiAudioHandler] bridges just_audio ↔ audio_service.
/// It runs in the background isolate (Android foreground service on Android,
/// background task on iOS) so playback continues when the app is minimised.
class ChuyassiAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  ChuyassiAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Forward just_audio state → audio_service state
    _player.playbackEventStream.listen(_broadcastState);

    // When a track ends naturally, play next
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) skipToNext();
    });
  }

  // ─── Public API used by PlayerProvider ─────────────────────────────────────

  Future<void> playSong(SongModel song, String url) async {
    final item = _toMediaItem(song, url);
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await play();
  }

  Future<void> playFromFile(SongModel song, String filePath) async {
    final item = _toMediaItem(song, filePath);
    mediaItem.add(item);
    await _player.setFilePath(filePath);
    await play();
  }

  Future<void> setQueueAndPlay(List<SongModel> songs, int index, List<String> urls) async {
    final items = List.generate(songs.length, (i) => _toMediaItem(songs[i], urls[i]));
    await updateQueue(items);
    await skipToQueueItem(index);
  }

  // ─── BaseAudioHandler overrides ────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final q = queue.value;
    final current = playbackState.value.queueIndex ?? 0;
    if (current + 1 < q.length) {
      await skipToQueueItem(current + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // If > 3 seconds in, restart. Otherwise go to previous.
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      final current = playbackState.value.queueIndex ?? 0;
      if (current > 0) await skipToQueueItem(current - 1);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final q = queue.value;
    if (index < 0 || index >= q.length) return;
    final item = q[index];
    mediaItem.add(item);
    final url = item.extras?['url'] as String?;
    if (url == null) return;
    if (url.startsWith('/')) {
      await _player.setFilePath(url);
    } else {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    }
    await _player.play();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> fastForward() => _player.seek(_player.position + const Duration(seconds: 10));

  @override
  Future<void> rewind() => _player.seek(_player.position - const Duration(seconds: 10));

  // ─── Passthrough accessors ─────────────────────────────────────────────────

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  // ─── Private helpers ───────────────────────────────────────────────────────

  void _broadcastState(PlaybackEvent event) {
    final isPlaying = _player.playing;
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;

    final queueIndex = mediaItem.value == null
        ? null
        : queue.value.indexOf(mediaItem.value!);

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: processingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queueIndex == -1 ? null : queueIndex,
    ));
  }

  static MediaItem _toMediaItem(SongModel song, String url) => MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artistName,
        album: song.albumId,
        duration: Duration(seconds: song.duration),
        artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
        extras: {'url': url, 'songId': song.id},
      );
}
