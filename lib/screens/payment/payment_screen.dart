import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.type,
    required this.itemId,
    required this.itemTitle,
    required this.amount,
    this.artistId,
  });
  final String type;
  final String itemId;
  final String itemTitle;
  final int amount;
  final String? artistId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = AppConstants.paymentOrange;
  final _phoneCtrl = TextEditingController();
  bool _processing = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_phoneCtrl.text.length < 8) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      if (widget.type == 'subscription') {
        await ApiService().initiateSubscription({
          'plan': widget.itemId,
          'paymentMethod': _method,
          'phone': _phoneCtrl.text.trim(),
        });
      } else if (widget.type == 'support') {
        await ApiService().supportArtist(
            widget.artistId!, widget.amount, _method);
      } else {
        await ApiService().initiatePurchase({
          'type': widget.type,
          'itemId': widget.itemId,
          'amount': widget.amount,
          'paymentMethod': _method,
          'phone': _phoneCtrl.text.trim(),
          if (widget.artistId != null) 'artistId': widget.artistId,
        });
        await StorageService().addPurchase(widget.itemId);
      }
      setState(() => _success = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    }
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_success) return _SuccessView(title: widget.itemTitle, onDone: () => context.pop());

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(title: Text(l.payNow)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(widget.itemTitle,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                      ),
                      Text(formatCurrency(widget.amount),
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_typeLabel(widget.type),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(l.paymentMethod,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 12),

            // Payment method cards
            _MethodCard(
              label: l.orangeMoney,
              subtitle: 'Pay via Orange Money',
              color: AppColors.orangeMoney,
              icon: Icons.phone_android_rounded,
              selected: _method == AppConstants.paymentOrange,
              onTap: () => setState(() => _method = AppConstants.paymentOrange),
            ),
            const SizedBox(height: 8),
            _MethodCard(
              label: l.mtnMomo,
              subtitle: 'Pay via MTN Mobile Money',
              color: AppColors.mtnMomo,
              icon: Icons.phone_iphone_rounded,
              selected: _method == AppConstants.paymentMTN,
              onTap: () => setState(() => _method = AppConstants.paymentMTN),
            ),
            const SizedBox(height: 8),
            _MethodCard(
              label: l.neero,
              subtitle: 'Pay via Neero',
              color: AppColors.primary,
              icon: Icons.account_balance_wallet_outlined,
              selected: _method == AppConstants.paymentNeero,
              onTap: () => setState(() => _method = AppConstants.paymentNeero),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l.phoneNumber,
                hintText: '+237 6XX XXX XXX',
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _methodColor(_method),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Pay ${formatCurrency(widget.amount)} via ${_methodLabel(_method)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'listen': return 'Stream access';
      case 'download': return 'Download';
      case 'album': return 'Album purchase';
      case 'subscription': return 'Subscription';
      case 'support': return 'Artist support';
      case 'shop': return 'Shop purchase';
      default: return type;
    }
  }

  Color _methodColor(String method) {
    switch (method) {
      case AppConstants.paymentOrange: return AppColors.orangeMoney;
      case AppConstants.paymentMTN: return const Color(0xFFD4A000);
      default: return AppColors.primary;
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case AppConstants.paymentOrange: return 'Orange Money';
      case AppConstants.paymentMTN: return 'MTN MoMo';
      default: return 'Neero';
    }
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : AppColors.textSecondary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected ? color : AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.title, required this.onDone});
  final String title;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful!',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: onDone, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}
