import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ShopProvider extends ChangeNotifier {
  final _api = ApiService();

  List<ProductModel> _products = [];
  final List<CartItem> _cart = [];
  bool _loading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<CartItem> get cart => _cart;
  bool get loading => _loading;
  String? get error => _error;

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  int get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  Future<void> loadProducts({String? category}) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.getProducts(category: category);
      _products = data
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    final existing = _cart.where((i) => i.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }
    final item = _cart.where((i) => i.product.id == productId).firstOrNull;
    if (item != null) {
      item.quantity = qty;
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<bool> checkout(String paymentMethod, String phone) async {
    _loading = true;
    notifyListeners();
    try {
      for (final item in _cart) {
        await _api.purchaseProduct(item.product.id, item.quantity);
      }
      _cart.clear();
      _error = null;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
