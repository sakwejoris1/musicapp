import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: Text(l.login),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(l.profile),
        actions: [
          if (user.isArtist)
            IconButton(
              icon: const Icon(Icons.dashboard_outlined, color: AppColors.primary),
              onPressed: () => context.push('/dashboard'),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, l),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_outlined,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1),
                    ),
                  ),
                  if (user.hasActiveSubscription) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: AppColors.success, size: 14),
                          SizedBox(width: 4),
                          Text('Premium',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: AppColors.darkCard, height: 1),

            // Menu items
            _MenuItem(
              icon: Icons.history_rounded,
              label: l.myPurchases,
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.workspace_premium_outlined,
              label: l.mySubscription,
              onTap: () => context.push('/subscription'),
            ),
            if (!user.hasActiveSubscription)
              _MenuItem(
                icon: Icons.star_outline_rounded,
                label: 'Upgrade to Premium',
                labelColor: AppColors.primary,
                onTap: () => context.push('/subscription'),
              ),
            _MenuItem(
              icon: Icons.language_outlined,
              label: l.language,
              trailing: _LanguageToggle(),
              onTap: null,
            ),
            _MenuItem(
              icon: Icons.notifications_none_rounded,
              label: l.notifications,
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.phone_android_outlined,
              label: l.artistPhone,
              subtitle: user.phone,
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.attach_money_rounded,
              label: 'Currency',
              subtitle: user.currency,
              onTap: () => _showCurrencyPicker(context, auth),
            ),
            const Divider(color: AppColors.darkCard),
            _MenuItem(
              icon: Icons.flag_outlined,
              label: l.reportContent,
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.logout_rounded,
              label: l.logout,
              labelColor: AppColors.error,
              onTap: () => _confirmLogout(context, auth, l),
            ),
            const SizedBox(height: 32),
            const Text('Chuyassi v1.0.0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.settings,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              title: const Text('Edit Profile',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
              title: const Text('Change Password',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Select Currency',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.currencies
              .map((c) => ListTile(
                    title: Text(c,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    trailing: auth.user?.currency == c
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _confirmLogout(
      BuildContext context, AuthProvider auth, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: Text(l.logout,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel,
                  style: const TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.logout),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.labelColor,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? subtitle;
  final Color? labelColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: labelColor ?? AppColors.textSecondary, size: 22),
      title: Text(label,
          style: TextStyle(
              color: labelColor ?? AppColors.textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20)
              : null),
      onTap: onTap,
    );
  }
}

class _LanguageToggle extends StatefulWidget {
  @override
  State<_LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<_LanguageToggle> {
  String _lang = StorageService().getLanguage();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final next = _lang == 'en' ? 'fr' : 'en';
        StorageService().saveLanguage(next);
        setState(() => _lang = next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _lang.toUpperCase(),
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
      ),
    );
  }
}
