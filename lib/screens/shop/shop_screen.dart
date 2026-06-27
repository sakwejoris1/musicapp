import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../models/product_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ShopProvider>().loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shop = context.watch<ShopProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(l.shop),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _showCart(context, shop, l),
              ),
              if (shop.cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.secondary, shape: BoxShape.circle),
                    child: Text('${shop.cartCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          if (auth.isArtist)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () => _showAddProduct(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CatChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    shop.loadProducts();
                  },
                ),
                ...AppConstants.categories.map((c) => _CatChip(
                      label: c[0].toUpperCase() + c.substring(1),
                      selected: _selectedCategory == c,
                      onTap: () {
                        setState(() => _selectedCategory = c);
                        shop.loadProducts(category: c);
                      },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: shop.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : shop.products.isEmpty
                    ? Center(
                        child: Text(l.noResultsFound,
                            style: const TextStyle(color: AppColors.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: shop.products.length,
                        itemBuilder: (_, i) => _ProductCard(
                          product: shop.products[i],
                          onAddToCart: () => shop.addToCart(shop.products[i]),
                          onBuy: () => context.push('/payment', extra: {
                            'type': 'shop',
                            'itemId': shop.products[i].id,
                            'itemTitle': shop.products[i].name,
                            'amount': shop.products[i].price,
                          }),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showCart(BuildContext context, ShopProvider shop, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Consumer<ShopProvider>(
          builder: (ctx, shop, __) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.cart,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    TextButton(
                        onPressed: shop.clearCart,
                        child: const Text('Clear',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ),
              Expanded(
                child: shop.cart.isEmpty
                    ? const Center(
                        child: Text('Cart is empty',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: shop.cart.length,
                        itemBuilder: (_, i) {
                          final item = shop.cart[i];
                          return ListTile(
                            title: Text(item.product.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            subtitle: Text(formatCurrency(item.product.price),
                                style: const TextStyle(
                                    color: AppColors.accent)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.remove,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                    onPressed: () => shop.updateQuantity(
                                        item.product.id, item.quantity - 1)),
                                Text('${item.quantity}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary)),
                                IconButton(
                                    icon: const Icon(Icons.add,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                    onPressed: () => shop.updateQuantity(
                                        item.product.id, item.quantity + 1)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (shop.cart.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/payment', extra: {
                          'type': 'shop',
                          'itemId': 'cart',
                          'itemTitle': 'Cart (${shop.cartCount} items)',
                          'amount': shop.cartTotal,
                        });
                      },
                      child: Text('Checkout • ${formatCurrency(shop.cartTotal)}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProduct(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: const _AddProductForm(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.product, required this.onAddToCart, required this.onBuy});
  final ProductModel product;
  final VoidCallback onAddToCart;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(product.sellerName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatCurrency(product.price),
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_shopping_cart_outlined,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.darkSurface,
        child: const Icon(Icons.image_outlined,
            color: AppColors.textSecondary, size: 40),
      );
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _AddProductForm extends StatefulWidget {
  const _AddProductForm();
  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _price = 1000;
  final bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.addProduct,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(labelText: l.productName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 2,
          decoration: InputDecoration(labelText: l.productDescription),
        ),
        const SizedBox(height: 12),
        Text('$_price FCFA',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Slider(
          value: _price.toDouble(),
          min: 100,
          max: 100000,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _price = v.round()),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Add Product'),
          ),
        ),
      ],
    );
  }
}
