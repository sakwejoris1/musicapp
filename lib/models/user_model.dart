class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role; // 'artist' | 'listener' | 'promoter'
  final String? avatarUrl;
  final bool isSubscribed;
  final DateTime? subscriptionExpiry;
  final String currency;
  final String? token;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.isSubscribed = false,
    this.subscriptionExpiry,
    this.currency = 'FCFA',
    this.token,
  });

  bool get isArtist => role == 'artist';
  bool get isPromoter => role == 'promoter';
  bool get hasActiveSubscription =>
      isSubscribed && (subscriptionExpiry?.isAfter(DateTime.now()) ?? false);

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        fullName: j['fullName'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        isSubscribed: j['isSubscribed'] as bool? ?? false,
        subscriptionExpiry: j['subscriptionExpiry'] != null
            ? DateTime.parse(j['subscriptionExpiry'] as String)
            : null,
        currency: j['currency'] as String? ?? 'FCFA',
        token: j['token'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'avatarUrl': avatarUrl,
        'isSubscribed': isSubscribed,
        'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
        'currency': currency,
      };

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isSubscribed,
    DateTime? subscriptionExpiry,
    String? currency,
    String? token,
  }) =>
      UserModel(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isSubscribed: isSubscribed ?? this.isSubscribed,
        subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
        currency: currency ?? this.currency,
        token: token ?? this.token,
      );
}
