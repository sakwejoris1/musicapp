import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyToken);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        debugPrint('[API] ${options.method} ${options.uri}');
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('[API ERROR] ${error.requestOptions.method} ${error.requestOptions.uri} → ${error.response?.statusCode} ${error.message}');
        handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> changePassword(String current, String newPass) async {
    await _dio.post('/auth/change-password',
        data: {'currentPassword': current, 'newPassword': newPass});
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  // Songs
  Future<List<dynamic>> getSongs({String? genre, String? search, int page = 1}) async {
    final res = await _dio.get('/songs', queryParameters: {
      if (genre != null) 'genre': genre,
      if (search != null) 'search': search,
      'page': page,
    });
    return res.data['songs'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSong(String id) async {
    final res = await _dio.get('/songs/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadSong(FormData formData,
      {void Function(int, int)? onProgress}) async {
    final res = await _dio.post('/songs',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: onProgress);
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateSong(String id, Map<String, dynamic> data) async {
    await _dio.patch('/songs/$id', data: data);
  }

  Future<void> updateSongPrice(String id, int price) async {
    await _dio.patch('/songs/$id/price', data: {'price': price});
  }

  Future<void> deleteSong(String id) async {
    await _dio.delete('/songs/$id');
  }

  Future<void> likeSong(String id) async {
    await _dio.post('/songs/$id/like');
  }

  Future<void> unlikeSong(String id) async {
    await _dio.delete('/songs/$id/like');
  }

  Future<List<dynamic>> getComments(String songId) async {
    final res = await _dio.get('/songs/$songId/comments');
    return res.data['comments'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> addComment(String songId, String text) async {
    final res = await _dio.post('/songs/$songId/comments', data: {'text': text});
    return res.data as Map<String, dynamic>;
  }

  // Albums
  Future<List<dynamic>> getAlbums({String? artistId, int page = 1}) async {
    final res = await _dio.get('/albums', queryParameters: {
      if (artistId != null) 'artistId': artistId,
      'page': page,
    });
    return res.data['albums'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAlbum(String id) async {
    final res = await _dio.get('/albums/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAlbum(FormData formData,
      {void Function(int, int)? onProgress}) async {
    final res = await _dio.post('/albums',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: onProgress);
    return res.data as Map<String, dynamic>;
  }

  // Artists
  Future<List<dynamic>> getArtists({int page = 1, String? search}) async {
    final res = await _dio.get('/artists', queryParameters: {
      'page': page,
      if (search != null) 'search': search,
    });
    return res.data['artists'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getArtist(String id) async {
    final res = await _dio.get('/artists/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getArtistDashboard() async {
    final res = await _dio.get('/artists/dashboard');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateArtistProfile(Map<String, dynamic> data) async {
    await _dio.patch('/artists/profile', data: data);
  }

  Future<void> followArtist(String id) async {
    await _dio.post('/artists/$id/follow');
  }

  Future<void> unfollowArtist(String id) async {
    await _dio.delete('/artists/$id/follow');
  }

  Future<Map<String, dynamic>> withdrawEarnings(
      int amount, String method, String phone) async {
    final res = await _dio.post('/artists/withdraw',
        data: {'amount': amount, 'paymentMethod': method, 'phone': phone});
    return res.data as Map<String, dynamic>;
  }

  // Playlists
  Future<List<dynamic>> getPlaylists() async {
    final res = await _dio.get('/playlists');
    return res.data['playlists'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createPlaylist(String name,
      {String? description, bool isPublic = true}) async {
    final res = await _dio.post('/playlists',
        data: {'name': name, 'description': description, 'isPublic': isPublic});
    return res.data as Map<String, dynamic>;
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _dio.post('/playlists/$playlistId/songs', data: {'songId': songId});
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _dio.delete('/playlists/$playlistId/songs/$songId');
  }

  Future<void> deletePlaylist(String id) async {
    await _dio.delete('/playlists/$id');
  }

  // Listening history
  Future<List<dynamic>> getHistory() async {
    final res = await _dio.get('/users/history');
    return res.data['history'] as List<dynamic>;
  }

  // Downloads
  Future<List<dynamic>> getDownloads() async {
    final res = await _dio.get('/users/downloads');
    return res.data['downloads'] as List<dynamic>;
  }

  // Payments
  Future<Map<String, dynamic>> initiatePurchase(Map<String, dynamic> data) async {
    final res = await _dio.post('/payments/purchase', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> initiateSubscription(Map<String, dynamic> data) async {
    final res = await _dio.post('/payments/subscribe', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> supportArtist(
      String artistId, int amount, String method) async {
    final res = await _dio.post('/payments/support', data: {
      'artistId': artistId,
      'amount': amount,
      'paymentMethod': method,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> payForOfflineListening(String artistId) async {
    final res =
        await _dio.post('/payments/offline', data: {'artistId': artistId});
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTransactions() async {
    final res = await _dio.get('/payments/transactions');
    return res.data['transactions'] as List<dynamic>;
  }

  // Stream token
  Future<String> getStreamToken(String songId) async {
    final res = await _dio.post('/songs/$songId/stream');
    return res.data['streamToken'] as String;
  }

  Future<void> recordListen(String songId, {bool offline = false}) async {
    await _dio.post('/songs/$songId/listen', data: {'offline': offline});
  }

  // Subscriptions
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final res = await _dio.get('/subscriptions/status');
    return res.data as Map<String, dynamic>;
  }

  // Shop
  Future<List<dynamic>> getProducts({String? category, int page = 1}) async {
    final res = await _dio.get('/shop', queryParameters: {
      if (category != null) 'category': category,
      'page': page,
    });
    return res.data['products'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(FormData formData) async {
    final res = await _dio.post('/shop/products',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> purchaseProduct(String productId, int qty) async {
    final res = await _dio.post('/shop/purchase',
        data: {'productId': productId, 'quantity': qty});
    return res.data as Map<String, dynamic>;
  }

  // Messages
  Future<List<dynamic>> getConversations() async {
    final res = await _dio.get('/messages/conversations');
    return res.data['conversations'] as List<dynamic>;
  }

  Future<List<dynamic>> getMessages(String userId, {int page = 1}) async {
    final res =
        await _dio.get('/messages/$userId', queryParameters: {'page': page});
    return res.data['messages'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(
      String receiverId, String content, String type) async {
    final res = await _dio.post('/messages',
        data: {'receiverId': receiverId, 'content': content, 'type': type});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendDedication(
      String artistId, String message) async {
    final res = await _dio.post('/messages/dedication',
        data: {'artistId': artistId, 'message': message});
    return res.data as Map<String, dynamic>;
  }

  // Search
  Future<Map<String, dynamic>> search(String query) async {
    final res = await _dio.get('/search', queryParameters: {'q': query});
    return res.data as Map<String, dynamic>;
  }

  // Profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.patch('/users/profile', data: data);
  }

  Future<void> updateAvatar(FormData formData) async {
    await _dio.post('/users/avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
  }

  // Notifications
  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return res.data['notifications'] as List<dynamic>;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  // Reports
  Future<void> reportContent(
      String contentId, String contentType, String reason) async {
    await _dio.post('/reports', data: {
      'contentId': contentId,
      'contentType': contentType,
      'reason': reason,
    });
  }
}
