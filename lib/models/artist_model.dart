class ArtistModel {
  final String id;
  final String userId;
  final String artistName;
  final String fullName;
  final String phone;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String paymentPhone; // Mobile Money number
  final String paymentMethod; // orange_money | mtn_momo | neero
  final int totalListens;
  final int offlineListens;
  final double totalEarnings;
  final int songCount;
  final int albumCount;
  final int followerCount;
  final bool isVerified;

  const ArtistModel({
    required this.id,
    required this.userId,
    required this.artistName,
    required this.fullName,
    required this.phone,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    required this.paymentPhone,
    required this.paymentMethod,
    this.totalListens = 0,
    this.offlineListens = 0,
    this.totalEarnings = 0,
    this.songCount = 0,
    this.albumCount = 0,
    this.followerCount = 0,
    this.isVerified = false,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> j) => ArtistModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        artistName: j['artistName'] as String,
        fullName: j['fullName'] as String,
        phone: j['phone'] as String,
        bio: j['bio'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        coverUrl: j['coverUrl'] as String?,
        paymentPhone: j['paymentPhone'] as String,
        paymentMethod: j['paymentMethod'] as String,
        totalListens: j['totalListens'] as int? ?? 0,
        offlineListens: j['offlineListens'] as int? ?? 0,
        totalEarnings: (j['totalEarnings'] as num?)?.toDouble() ?? 0,
        songCount: j['songCount'] as int? ?? 0,
        albumCount: j['albumCount'] as int? ?? 0,
        followerCount: j['followerCount'] as int? ?? 0,
        isVerified: j['isVerified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'artistName': artistName,
        'fullName': fullName,
        'phone': phone,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'coverUrl': coverUrl,
        'paymentPhone': paymentPhone,
        'paymentMethod': paymentMethod,
        'totalListens': totalListens,
        'offlineListens': offlineListens,
        'totalEarnings': totalEarnings,
        'songCount': songCount,
        'albumCount': albumCount,
        'followerCount': followerCount,
        'isVerified': isVerified,
      };
}
