class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String name;
  final String description;
  final int price;
  final String currency;
  final String category;
  final String? imageUrl;
  final int stock;
  final bool isAvailable;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'FCFA',
    required this.category,
    this.imageUrl,
    this.stock = 0,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'] as String,
        sellerId: j['sellerId'] as String,
        sellerName: j['sellerName'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        price: j['price'] as int,
        currency: j['currency'] as String? ?? 'FCFA',
        category: j['category'] as String,
        imageUrl: j['imageUrl'] as String?,
        stock: j['stock'] as int? ?? 0,
        isAvailable: j['isAvailable'] as bool? ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'category': category,
        'imageUrl': imageUrl,
        'stock': stock,
        'isAvailable': isAvailable,
        'createdAt': createdAt.toIso8601String(),
      };
}

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get total => product.price * quantity;
}
