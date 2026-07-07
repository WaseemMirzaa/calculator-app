import 'package:flutter/material.dart';

import 'subscription_screen.dart';

/// Legacy route name — opens the full subscription paywall / management UI.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) => const SubscriptionScreen();
}
