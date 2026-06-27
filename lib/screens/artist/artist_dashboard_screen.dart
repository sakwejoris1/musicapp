import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});
  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getArtistDashboard();
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final totalEarnings =
        (_data?['totalEarnings'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(l.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.push('/upload'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${auth.user?.fullName.split(' ').first ?? 'Artist'}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),

                    // Earnings card
                    _EarningsCard(
                      total: totalEarnings,
                      today: (_data?['todayEarnings'] as num?)?.toDouble() ?? 0,
                      month: (_data?['monthEarnings'] as num?)?.toDouble() ?? 0,
                      onWithdraw: () =>
                          _showWithdrawSheet(context, totalEarnings),
                    ),
                    const SizedBox(height: 20),

                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                          icon: Icons.headphones_rounded,
                          label: l.totalListens,
                          value: '${_data?['totalListens'] ?? 0}',
                          color: AppColors.primary,
                        ),
                        _StatCard(
                          icon: Icons.wifi_off_rounded,
                          label: l.offlineListens,
                          value: '${_data?['offlineListens'] ?? 0}',
                          color: AppColors.secondary,
                        ),
                        _StatCard(
                          icon: Icons.download_rounded,
                          label: 'Downloads',
                          value: '${_data?['totalDownloads'] ?? 0}',
                          color: AppColors.success,
                        ),
                        _StatCard(
                          icon: Icons.people_outline_rounded,
                          label: 'Followers',
                          value: '${_data?['followerCount'] ?? 0}',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top songs
                    const Text(
                      'Your Songs',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    if (_data?['songs'] != null)
                      ...(_data!['songs'] as List).take(10).map((s) {
                        final song = s as Map<String, dynamic>;
                        return _SongRow(
                          title: song['title'] as String? ?? '',
                          listens: song['listenCount'] as int? ?? 0,
                          earnings:
                              (song['earnings'] as num?)?.toDouble() ?? 0,
                          price: song['price'] as int? ?? 0,
                          songId: song['id'] as String? ?? '',
                          onPriceEdit: (newPrice) =>
                              ApiService().updateSongPrice(
                                  song['id'] as String, newPrice),
                          onDelete: () => _confirmDelete(
                              context, song['id'] as String,
                              song['title'] as String? ?? ''),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Offline listening section
                    const Text('Offline Listening',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: AppColors.secondary, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.offlineListeningPrice,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  'Offline subscribers: ${_data?['offlineSubscribers'] ?? 0}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(
                                ((_data?['offlineSubscribers'] as int?) ?? 0) *
                                    100),
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _showWithdrawSheet(BuildContext context, double totalEarnings) {
    final phoneCtrl = TextEditingController();
    String method = AppConstants.paymentOrange;
    int amount = totalEarnings.toInt().clamp(100, totalEarnings.toInt());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Withdraw Earnings',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const SizedBox(height: 4),
              Text('Available: ${formatCurrency(totalEarnings)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Text('Amount: ${formatCurrency(amount)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              Slider(
                value: amount.toDouble(),
                min: 100,
                max: totalEarnings.clamp(100, double.infinity),
                activeColor: AppColors.primary,
                inactiveColor: AppColors.darkSurface,
                onChanged: (v) => setState(() => amount = v.round()),
              ),
              const SizedBox(height: 12),
              const Text('Payment Method',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _MethodChip(
                  label: 'Orange Money',
                  color: AppColors.orangeMoney,
                  selected: method == AppConstants.paymentOrange,
                  onTap: () =>
                      setState(() => method = AppConstants.paymentOrange),
                ),
                const SizedBox(width: 8),
                _MethodChip(
                  label: 'MTN MoMo',
                  color: AppColors.mtnMomo,
                  selected: method == AppConstants.paymentMTN,
                  onTap: () =>
                      setState(() => method = AppConstants.paymentMTN),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Mobile Money Number',
                  hintText: '+237 6XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (phoneCtrl.text.length < 8) return;
                    Navigator.pop(ctx);
                    try {
                      await ApiService()
                          .withdrawEarnings(amount, method, phoneCtrl.text.trim());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Withdrawal request submitted!'),
                          backgroundColor: AppColors.success,
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                  child: Text('Withdraw ${formatCurrency(amount)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String songId, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Song',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "$title"? This cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService().deleteSong(songId);
              _load();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12)),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.total,
    required this.today,
    required this.month,
    required this.onWithdraw,
  });
  final double total;
  final double today;
  final double month;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Revenue',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(formatCurrency(total),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: 'Today', value: formatCurrency(today))),
              Expanded(
                  child: _MiniStat(
                      label: 'This Month', value: formatCurrency(month))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 18),
              label: const Text('Withdraw Earnings',
                  style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.title,
    required this.listens,
    required this.earnings,
    required this.price,
    required this.songId,
    required this.onPriceEdit,
    required this.onDelete,
  });
  final String title;
  final int listens;
  final double earnings;
  final int price;
  final String songId;
  final Future<void> Function(int) onPriceEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.music_note_rounded,
            color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14)),
      subtitle: Text('$listens listens',
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatCurrency(earnings),
              style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _editPrice(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$price F',
                  style: const TextStyle(
                      color: AppColors.accent, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  void _editPrice(BuildContext context) {
    int newPrice = price;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: const Text('Edit Price',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$newPrice FCFA',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              Slider(
                value: newPrice.toDouble(),
                min: 50,
                max: 100,
                divisions: 5,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => newPrice = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () {
                onPriceEdit(newPrice);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
