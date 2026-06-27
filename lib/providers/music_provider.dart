import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../services/api_service.dart';

class MusicProvider extends ChangeNotifier {
  final _api = ApiService();

  List<SongModel> _songs = [];
  List<SongModel> _trendingSongs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  List<SongModel> _searchResults = [];
  final Set<String> _likedSongIds = {};
  final Set<String> _followedArtistIds = {};
  bool _loading = false;
  String? _error;

  List<SongModel> get songs => _songs;
  List<SongModel> get trendingSongs => _trendingSongs;
  List<AlbumModel> get albums => _albums;
  List<ArtistModel> get artists => _artists;
  List<SongModel> get searchResults => _searchResults;
  Set<String> get likedSongIds => _likedSongIds;
  Set<String> get followedArtistIds => _followedArtistIds;
  bool get loading => _loading;
  String? get error => _error;

  bool isLiked(String songId) => _likedSongIds.contains(songId);
  bool isFollowing(String artistId) => _followedArtistIds.contains(artistId);

  Future<void> loadHome() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getSongs(page: 1),
        _api.getAlbums(page: 1),
        _api.getArtists(page: 1),
      ]);
      _songs = results[0]
          .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
          .toList();
      _trendingSongs = _songs.take(10).toList();
      _albums = results[1]
          .map((a) => AlbumModel.fromJson(a as Map<String, dynamic>))
          .toList();
      _artists = results[2]
          .map((a) => ArtistModel.fromJson(a as Map<String, dynamic>))
          .toList();
      for (final s in _songs) {
        if (s.isLiked) _likedSongIds.add(s.id);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadSongs({String? genre}) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.getSongs(genre: genre);
      _songs =
          data.map((s) => SongModel.fromJson(s as Map<String, dynamic>)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final data = await _api.search(query);
      _searchResults = (data['songs'] as List? ?? [])
          .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _searchResults = [];
    }
    notifyListeners();
  }

  Future<void> toggleLike(SongModel song) async {
    final wasLiked = _likedSongIds.contains(song.id);
    if (wasLiked) {
      _likedSongIds.remove(song.id);
    } else {
      _likedSongIds.add(song.id);
    }
    notifyListeners();
    try {
      if (wasLiked) {
        await _api.unlikeSong(song.id);
      } else {
        await _api.likeSong(song.id);
      }
    } catch (_) {
      if (wasLiked) {
        _likedSongIds.add(song.id);
      } else {
        _likedSongIds.remove(song.id);
      }
      notifyListeners();
    }
  }

  Future<void> toggleFollowArtist(String artistId) async {
    final wasFollowing = _followedArtistIds.contains(artistId);
    if (wasFollowing) {
      _followedArtistIds.remove(artistId);
    } else {
      _followedArtistIds.add(artistId);
    }
    notifyListeners();
    try {
      if (wasFollowing) {
        await _api.unfollowArtist(artistId);
      } else {
        await _api.followArtist(artistId);
      }
    } catch (_) {
      if (wasFollowing) {
        _followedArtistIds.add(artistId);
      } else {
        _followedArtistIds.remove(artistId);
      }
      notifyListeners();
    }
  }

  Future<ArtistModel?> getArtist(String id) async {
    try {
      final data = await _api.getArtist(id);
      return ArtistModel.fromJson(data['artist'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<AlbumModel?> getAlbum(String id) async {
    try {
      final data = await _api.getAlbum(id);
      return AlbumModel.fromJson(data['album'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void markSongPurchased(String songId) {
    _songs =
        _songs.map((s) => s.id == songId ? s.copyWith(isPurchased: true) : s).toList();
    notifyListeners();
  }
}
