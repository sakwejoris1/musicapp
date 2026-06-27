class TransactionModel {
  final String id;
  final String userId;
  final String? artistId;
  final String type; // 'listen'|'download'|'subscription'|'support'|'shop'
  final int amount;
  final String currency;
  final String paymentMethod;
  final String status; // 'pending'|'success'|'failed'
  final String? itemId;
  final String? itemTitle;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    this.artistId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.itemId,
    this.itemTitle,
    required this.createdAt,
  });

  bool get isSuccess => status == 'success';

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        artistId: j['artistId'] as String?,
        type: j['type'] as String,
        amount: j['amount'] as int,
        currency: j['currency'] as String,
        paymentMethod: j['paymentMethod'] as String,
        status: j['status'] as String,
        itemId: j['itemId'] as String?,
        itemTitle: j['itemTitle'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'artistId': artistId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'status': status,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'createdAt': createdAt.toIso8601String(),
      };
}
