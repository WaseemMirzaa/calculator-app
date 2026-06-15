import 'package:flutter/material.dart';

import '../services/premium_service.dart';
import '../theme/app_theme.dart';

/// Premium-themed side navigation drawer. Shows the current plan at the top and
/// the app's menu actions below.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.isPremium,
    required this.onUpgrade,
    required this.onRestore,
    required this.onPrivacy,
    required this.onTerms,
    this.onResetFree,
  });

  final bool isPremium;
  final VoidCallback onUpgrade;
  final VoidCallback onRestore;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  /// Debug-only: drop back to the free tier. Hidden when null.
  final VoidCallback? onResetFree;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand line.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: ShaderMask(
                  shaderCallback: (rect) =>
                      AppGradients.goldMetallic.createShader(rect),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'GOLDEN GRAIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'inch fraction golden ratio tool',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Current plan card ---
              _PlanCard(
                  isPremium: isPremium,
                  onUpgrade: () {
                    Navigator.of(context).pop();
                    onUpgrade();
                  }),

              const SizedBox(height: 8),
              const _DrawerDivider(),

              // --- Menu items ---
              if (!isPremium)
                _DrawerItem(
                  icon: Icons.workspace_premium,
                  label: 'Upgrade to Premium',
                  highlighted: true,
                  onTap: () => _run(context, onUpgrade),
                ),
              _DrawerItem(
                icon: Icons.restore,
                label: 'Restore Purchase',
                onTap: () => _run(context, onRestore),
              ),
              _DrawerItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => _run(context, onPrivacy),
              ),
              _DrawerItem(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => _run(context, onTerms),
              ),
              if (onResetFree != null) ...[
                const _DrawerDivider(),
                _DrawerItem(
                  icon: Icons.bug_report_outlined,
                  label: 'Switch to Free (debug)',
                  onTap: () => _run(context, onResetFree!),
                ),
              ],

              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _run(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop(); // close the drawer first
    action();
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.isPremium, required this.onUpgrade});

  final bool isPremium;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppGradients.goldButton,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.goldGlow,
              blurRadius: 20,
              spreadRadius: -2,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium,
                color: AppColors.actionTextOnGold, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRO PRECISION',
                    style: TextStyle(
                      color: AppColors.actionTextOnGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All features unlocked',
                    style: TextStyle(
                      color: Color(0xCC111111),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Free plan card.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.textMuted, size: 22),
              SizedBox(width: 10),
              Text(
                'FREE PLAN',
                style: TextStyle(
                  color: AppColors.goldBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Limited to 1/16 precision',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onUpgrade,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.goldButton,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.goldGlow,
                    blurRadius: 14,
                    spreadRadius: -3,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Unlock Pro — ${PremiumService.price}',
                style: TextStyle(
                  color: AppColors.actionTextOnGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color tint =
        highlighted ? AppColors.goldBright : AppColors.goldPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: tint, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      highlighted ? AppColors.goldBright : AppColors.textLight,
                  fontSize: 14,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Divider(color: AppColors.white05, height: 1),
    );
  }
}
