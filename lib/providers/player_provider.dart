import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_service.dart' as svc;
import '../services/api_service.dart';

enum PlayerStatus { idle, loading, playing, paused, error }

enum PlayerRepeatMode { off, repeatAll, repeatOne }

class PlayerProvider extends ChangeNotifier {
  final _audio = svc.AudioPlayerService();
  final _api = ApiService();

  PlayerStatus _status = PlayerStatus.idle;
  SongModel? _currentSong;
  List<SongModel> _queue = [];
  int _queueIndex = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _shuffle = false;
  PlayerRepeatMode _repeat = PlayerRepeatMode.off;
  List<int> _shuffledIndices = [];
  String? _error;

  PlayerStatus get status => _status;
  SongModel? get currentSong => _currentSong;
  List<SongModel> get queue => _queue;
  int get queueIndex => _queueIndex;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get shuffle => _shuffle;
  PlayerRepeatMode get repeatMode => _repeat;
  String? get error => _error;
  bool get isPlaying => _status == PlayerStatus.playing;
  bool get hasQueue => _queue.isNotEmpty;

  double get progress =>
      _duration.inMilliseconds > 0
          ? _position.inMilliseconds / _duration.inMilliseconds
          : 0;

  bool get hasPrevious => _queueIndex > 0;
  bool get hasNext => _queueIndex < _queue.length - 1;

  void _listenStreams() {
    _audio.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audio.durationStream.listen((dur) {
      if (dur != null) _duration = dur;
      notifyListeners();
    });
    _audio.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });
  }

  Future<void> playSong(SongModel song) async {
    _status = PlayerStatus.loading;
    _currentSong = song;
    _error = null;
    notifyListeners();
    try {
      final token = await _api.getStreamToken(song.id);
      await _audio.playSong(song, token);
      await _api.recordListen(song.id);
      _status = PlayerStatus.playing;
      _listenStreams();
    } catch (e) {
      _error = e.toString();
      _status = PlayerStatus.error;
    }
    notifyListeners();
  }

  Future<void> playOffline(SongModel song, String localPath) async {
    _status = PlayerStatus.loading;
    _currentSong = song;
    notifyListeners();
    try {
      await _audio.playFromFile(song, localPath);
      await _api.recordListen(song.id, offline: true);
      _status = PlayerStatus.playing;
      _listenStreams();
    } catch (e) {
      _error = e.toString();
      _status = PlayerStatus.error;
    }
    notifyListeners();
  }

  void setQueue(List<SongModel> songs, {int startIndex = 0}) {
    _queue = List.from(songs);
    _queueIndex = startIndex;
    if (_shuffle) {
      _buildShuffleIndices(startIndex);
    }
    notifyListeners();
    playSong(songs[startIndex]);
  }

  void addToQueue(SongModel song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _queueIndex) _queueIndex--;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audio.pause();
    _status = PlayerStatus.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    await _audio.resume();
    _status = PlayerStatus.playing;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seekTo(double value) async {
    final target = Duration(milliseconds: (_duration.inMilliseconds * value).round());
    await _audio.seekTo(target);
  }

  Future<void> seekToDuration(Duration target) async {
    await _audio.seekTo(target);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    final nextIndex = _getNextIndex();
    if (nextIndex != null) {
      _queueIndex = nextIndex;
      await playSong(_queue[_queueIndex]);
    }
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 3) {
      await seekTo(0);
    } else if (_queueIndex > 0) {
      _queueIndex--;
      await playSong(_queue[_queueIndex]);
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_shuffle) {
      _buildShuffleIndices(_queueIndex);
    }
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = PlayerRepeatMode.values[(_repeat.index + 1) % PlayerRepeatMode.values.length];
    notifyListeners();
  }

  void _buildShuffleIndices(int currentIndex) {
    _shuffledIndices = List.generate(_queue.length, (i) => i)
      ..remove(currentIndex)
      ..shuffle();
    _shuffledIndices.insert(0, currentIndex);
  }

  int? _getNextIndex() {
    if (_repeat == PlayerRepeatMode.repeatOne) return _queueIndex;
    if (_shuffle && _shuffledIndices.isNotEmpty) {
      final currentPos = _shuffledIndices.indexOf(_queueIndex);
      if (currentPos < _shuffledIndices.length - 1) {
        return _shuffledIndices[currentPos + 1];
      } else if (_repeat == PlayerRepeatMode.repeatAll) {
        return _shuffledIndices[0];
      }
      return null;
    }
    if (_queueIndex < _queue.length - 1) return _queueIndex + 1;
    if (_repeat == PlayerRepeatMode.repeatAll) return 0;
    return null;
  }

  void _onSongCompleted() {
    final nextIndex = _getNextIndex();
    if (nextIndex != null) {
      _queueIndex = nextIndex;
      playSong(_queue[_queueIndex]);
    } else {
      _status = PlayerStatus.idle;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _audio.stop();
    _status = PlayerStatus.idle;
    _currentSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }
}
