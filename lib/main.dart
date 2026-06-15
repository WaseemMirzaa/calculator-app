import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/splash_screen.dart';
import 'services/premium_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the persisted premium entitlement before the first frame so the
  // calculator opens directly in the correct (free/premium) state.
  final premium = PremiumService();
  await premium.init();

  runApp(GoldenGrainApp(premium: premium));
}

class GoldenGrainApp extends StatelessWidget {
  const GoldenGrainApp({super.key, required this.premium});

  final PremiumService premium;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      premium: premium,
      child: MaterialApp(
        title: 'Golden Grain',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
