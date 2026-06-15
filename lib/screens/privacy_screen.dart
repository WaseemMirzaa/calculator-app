import 'package:flutter/material.dart';

import 'legal_page.dart';

/// Privacy Policy screen. The Golden Grain Calculator runs entirely on-device
/// and collects nothing, which the copy below makes explicit.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPage(
      title: 'Privacy Policy',
      lastUpdated: 'Last updated: June 15, 2026',
      intro:
          'Golden Grain Calculator is designed to respect your privacy. The app '
          'performs all calculations locally on your device and does not require '
          'an account, an internet connection, or any personal information to '
          'function.',
      sections: [
        LegalSection(
          'Information We Collect',
          'We do not collect, store, or transmit any personal data. Dimensions '
              'you enter into the calculator are processed in memory on your '
              'device and are never sent to us or any third party.',
        ),
        LegalSection(
          'On-Device Storage',
          'The only value the app saves is a single flag indicating whether you '
              'have unlocked the premium "Pro Precision" package. This flag is '
              'stored locally using your device\'s standard preferences storage '
              'and is used solely to keep premium features unlocked between '
              'sessions.',
        ),
        LegalSection(
          'Purchases',
          'If you choose to upgrade, the transaction is handled by the platform '
              'app store (Google Play or the App Store). We never see or store '
              'your payment details; please refer to the relevant store\'s '
              'privacy policy for how that data is handled.',
        ),
        LegalSection(
          'Analytics & Tracking',
          'This app contains no advertising SDKs, no analytics SDKs, and no '
              'tracking of any kind.',
        ),
        LegalSection(
          'Children\'s Privacy',
          'Because the app collects no personal information, it is safe for use '
              'by audiences of all ages.',
        ),
        LegalSection(
          'Contact',
          'Questions about this policy can be sent to '
              'support@goldengraincalculator.app.',
        ),
      ],
    );
  }
}
