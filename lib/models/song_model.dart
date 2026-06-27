class SongModel {
  final String id;
  final String artistId;
  final String artistName;
  final String? albumId;
  final String title;
  final String genre;
  final String? language;
  final String? coverUrl;
  final String audioUrl;
  final String? videoUrl;
  final String? lyrics;
  final String? producer;
  final String? composer;
  final int price;
  final int downloadPrice;
  final int duration;
  final int listenCount;
  final int downloadCount;
  final int likeCount;
  final bool isPurchased;
  final bool isDownloaded;
  final bool isLiked;
  final bool hasVideo;
  final String currency;
  final DateTime createdAt;
  final DateTime? releaseDate;

  const SongModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    this.albumId,
    required this.title,
    required this.genre,
    this.language,
    this.coverUrl,
    required this.audioUrl,
    this.videoUrl,
    this.lyrics,
    this.producer,
    this.composer,
    required this.price,
    required this.downloadPrice,
    required this.duration,
    this.listenCount = 0,
    this.downloadCount = 0,
    this.likeCount = 0,
    this.isPurchased = false,
    this.isDownloaded = false,
    this.isLiked = false,
    this.hasVideo = false,
    this.currency = 'FCFA',
    required this.createdAt,
    this.releaseDate,
  });

  factory SongModel.fromJson(Map<String, dynamic> j) => SongModel(
        id: j['id'] as String,
        artistId: j['artistId'] as String,
        artistName: j['artistName'] as String,
        albumId: j['albumId'] as String?,
        title: j['title'] as String,
        genre: j['genre'] as String,
        language: j['language'] as String?,
        coverUrl: j['coverUrl'] as String?,
        audioUrl: j['audioUrl'] as String,
        videoUrl: j['videoUrl'] as String?,
        lyrics: j['lyrics'] as String?,
        producer: j['producer'] as String?,
        composer: j['composer'] as String?,
        price: j['price'] as int,
        downloadPrice: j['downloadPrice'] as int? ?? j['price'] as int,
        duration: j['duration'] as int? ?? 0,
        listenCount: j['listenCount'] as int? ?? 0,
        downloadCount: j['downloadCount'] as int? ?? 0,
        likeCount: j['likeCount'] as int? ?? 0,
        isPurchased: j['isPurchased'] as bool? ?? false,
        isDownloaded: j['isDownloaded'] as bool? ?? false,
        isLiked: j['isLiked'] as bool? ?? false,
        hasVideo: j['hasVideo'] as bool? ?? false,
        currency: j['currency'] as String? ?? 'FCFA',
        createdAt: DateTime.parse(j['createdAt'] as String),
        releaseDate: j['releaseDate'] != null
            ? DateTime.parse(j['releaseDate'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'artistId': artistId,
        'artistName': artistName,
        'albumId': albumId,
        'title': title,
        'genre': genre,
        'language': language,
        'coverUrl': coverUrl,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'lyrics': lyrics,
        'producer': producer,
        'composer': composer,
        'price': price,
        'downloadPrice': downloadPrice,
        'duration': duration,
        'listenCount': listenCount,
        'downloadCount': downloadCount,
        'likeCount': likeCount,
        'isPurchased': isPurchased,
        'isDownloaded': isDownloaded,
        'isLiked': isLiked,
        'hasVideo': hasVideo,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
        'releaseDate': releaseDate?.toIso8601String(),
      };

  SongModel copyWith({
    bool? isPurchased,
    bool? isDownloaded,
    bool? isLiked,
    int? likeCount,
    String? lyrics,
  }) =>
      SongModel(
        id: id,
        artistId: artistId,
        artistName: artistName,
        albumId: albumId,
        title: title,
        genre: genre,
        language: language,
        coverUrl: coverUrl,
        audioUrl: audioUrl,
        videoUrl: videoUrl,
        lyrics: lyrics ?? this.lyrics,
        producer: producer,
        composer: composer,
        price: price,
        downloadPrice: downloadPrice,
        duration: duration,
        listenCount: listenCount,
        downloadCount: downloadCount,
        likeCount: likeCount ?? this.likeCount,
        isPurchased: isPurchased ?? this.isPurchased,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        isLiked: isLiked ?? this.isLiked,
        hasVideo: hasVideo,
        currency: currency,
        createdAt: createdAt,
        releaseDate: releaseDate,
      );
}
