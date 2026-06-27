import 'song_model.dart';

class AlbumModel {
  final String id;
  final String artistId;
  final String artistName;
  final String title;
  final String? coverUrl;
  final int price; // 500–3000 FCFA
  final String genre;
  final List<SongModel> songs;
  final int listenCount;
  final bool isPurchased;
  final String currency;
  final DateTime createdAt;

  const AlbumModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.title,
    this.coverUrl,
    required this.price,
    required this.genre,
    this.songs = const [],
    this.listenCount = 0,
    this.isPurchased = false,
    this.currency = 'FCFA',
    required this.createdAt,
  });

  int get songCount => songs.length;

  factory AlbumModel.fromJson(Map<String, dynamic> j) => AlbumModel(
        id: j['id'] as String,
        artistId: j['artistId'] as String,
        artistName: j['artistName'] as String,
        title: j['title'] as String,
        coverUrl: j['coverUrl'] as String?,
        price: j['price'] as int,
        genre: j['genre'] as String,
        songs: (j['songs'] as List<dynamic>?)
                ?.map((s) => SongModel.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        listenCount: j['listenCount'] as int? ?? 0,
        isPurchased: j['isPurchased'] as bool? ?? false,
        currency: j['currency'] as String? ?? 'FCFA',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'artistId': artistId,
        'artistName': artistName,
        'title': title,
        'coverUrl': coverUrl,
        'price': price,
        'genre': genre,
        'songs': songs.map((s) => s.toJson()).toList(),
        'listenCount': listenCount,
        'isPurchased': isPurchased,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
      };
}
