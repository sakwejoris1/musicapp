import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  SongModel? _currentSong;
  SongModel? get currentSong => _currentSong;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get volumeStream => _player.volumeStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> playSong(SongModel song, String streamUrl) async {
    _currentSong = song;
    await _player.setUrl(streamUrl);
    await _player.play();
  }

  Future<void> playFromFile(SongModel song, String filePath) async {
    _currentSong = song;
    await _player.setFilePath(filePath);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() async {
    await _player.stop();
    _currentSong = null;
  }

  Future<void> seekTo(Duration position) => _player.seek(position);
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  Future<void> skipForward() =>
      _player.seek(_player.position + const Duration(seconds: 10));

  Future<void> skipBackward() =>
      _player.seek(_player.position - const Duration(seconds: 10));

  void dispose() => _player.dispose();
}
