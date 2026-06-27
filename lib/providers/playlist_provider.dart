import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final _api = ApiService();

  List<PlaylistModel> _playlists = [];
  bool _loading = false;
  String? _error;

  List<PlaylistModel> get playlists => _playlists;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.getPlaylists();
      _playlists = data
          .map((p) => PlaylistModel.fromJson(p as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<PlaylistModel?> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final data = await _api.createPlaylist(
          name, description: description, isPublic: isPublic);
      final playlist =
          PlaylistModel.fromJson(data['playlist'] as Map<String, dynamic>);
      _playlists.insert(0, playlist);
      notifyListeners();
      return playlist;
    } catch (_) {
      return null;
    }
  }

  Future<bool> addSong(String playlistId, SongModel song) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return false;
    if (_playlists[idx].songs.any((s) => s.id == song.id)) return true;

    // optimistic
    _playlists[idx] =
        _playlists[idx].copyWith(songs: [..._playlists[idx].songs, song]);
    notifyListeners();
    try {
      await _api.addSongToPlaylist(playlistId, song.id);
      return true;
    } catch (_) {
      // rollback
      final without = _playlists[idx].songs.where((s) => s.id != song.id).toList();
      _playlists[idx] = _playlists[idx].copyWith(songs: without);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeSong(String playlistId, String songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return false;
    final removed = _playlists[idx].songs.where((s) => s.id == songId).toList();
    if (removed.isEmpty) return true;

    // optimistic
    final without =
        _playlists[idx].songs.where((s) => s.id != songId).toList();
    _playlists[idx] = _playlists[idx].copyWith(songs: without);
    notifyListeners();
    try {
      await _api.removeSongFromPlaylist(playlistId, songId);
      return true;
    } catch (_) {
      // rollback
      _playlists[idx] =
          _playlists[idx].copyWith(songs: [...without, ...removed]);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return false;
    final backup = _playlists[idx];

    _playlists.removeAt(idx);
    notifyListeners();
    try {
      await _api.deletePlaylist(playlistId);
      return true;
    } catch (_) {
      _playlists.insert(idx, backup);
      notifyListeners();
      return false;
    }
  }

  PlaylistModel? getById(String id) =>
      _playlists.where((p) => p.id == id).firstOrNull;
}
