import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final isActive = auth.user?.hasActiveSubscription ?? false;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(title: Text(l.subscription)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isActive)
              _ActiveBanner(expiry: auth.user!.subscriptionExpiry!)
            else
              const _HeroBanner(),
            const SizedBox(height: 32),
            Text(l.subscribe,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Unlock unlimited streaming and exclusive content',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Daily plan
            _PlanCard(
              title: l.daily,
              price: l.dailyPrice,
              amount: 150,
              features: const [
                'Unlimited streaming',
                'All genres',
                'High quality audio',
              ],
              color: AppColors.secondary,
              onSubscribe: () => context.push('/payment', extra: {
                'type': 'subscription',
                'itemId': 'daily',
                'itemTitle': 'Daily Subscription',
                'amount': 150,
              }),
            ),
            const SizedBox(height: 16),

            // Monthly plan
            _PlanCard(
              title: l.monthly,
              price: l.monthlyPrice,
              amount: 3000,
              badge: 'BEST VALUE',
              features: const [
                'Unlimited streaming',
                'Offline listening',
                'Priority support',
                'All genres & new releases',
                'Download songs',
              ],
              color: AppColors.primary,
              onSubscribe: () => context.push('/payment', extra: {
                'type': 'subscription',
                'itemId': 'monthly',
                'itemTitle': 'Monthly Subscription',
                'amount': 3000,
              }),
            ),
            const SizedBox(height: 24),

            // Offline listening card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: AppColors.secondary, size: 24),
                      const SizedBox(width: 10),
                      Text(l.offlineListening,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pay once to listen to an artist\'s catalog offline. ${l.offlineListeningPrice}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Min. 20 listens at 50 FCFA — payment required before streaming',
                    style: TextStyle(
                        color: AppColors.warning.withValues(alpha: 0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 52),
          SizedBox(height: 12),
          Text('Go Premium',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Stream unlimited African music',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.expiry});
  final DateTime expiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Subscription',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text('Expires ${timeAgo(expiry)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.amount,
    required this.features,
    required this.color,
    required this.onSubscribe,
    this.badge,
  });
  final String title;
  final String price;
  final int amount;
  final List<String> features;
  final Color color;
  final VoidCallback onSubscribe;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(f,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Text('Subscribe for ${formatCurrency(amount)}'),
            ),
          ),
        ],
      ),
    );
  }
}
