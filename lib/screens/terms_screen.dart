import 'package:flutter/material.dart';

import 'legal_page.dart';

/// Terms of Service screen.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPage(
      title: 'Terms of Service',
      lastUpdated: 'Last updated: June 15, 2026',
      intro:
          'By downloading or using Golden Grain Calculator ("the app") you agree '
          'to these Terms of Service. Please read them carefully.',
      sections: [
        LegalSection(
          'License',
          'We grant you a personal, non-transferable, non-exclusive license to '
              'use the app on devices you own or control, in accordance with '
              'these terms and the rules of the platform app store.',
        ),
        LegalSection(
          'Premium Purchase',
          'The "Pro Precision" package is a one-time, non-recurring in-app '
              'purchase that unlocks 1/32" and 1/64" precision toggles and the '
              'full millimeter conversion engine. Purchases are final except '
              'where a refund is required by the app store\'s policies or '
              'applicable law.',
        ),
        LegalSection(
          'Accuracy & Intended Use',
          'The app is provided as a layout and estimation aid for woodworking, '
              'framing and millwork. While we strive for precision, rounding to '
              'the selected fraction is inherent to the tool. You are '
              'responsible for verifying all measurements before cutting, '
              'building, or making purchasing decisions. Always measure twice '
              'and cut once.',
        ),
        LegalSection(
          'No Warranty',
          'The app is provided "as is" without warranties of any kind, express '
              'or implied. We do not warrant that the app will be error-free or '
              'uninterrupted.',
        ),
        LegalSection(
          'Limitation of Liability',
          'To the fullest extent permitted by law, we are not liable for any '
              'damages, losses, or wasted materials arising from your use of, or '
              'reliance on, the app and its calculations.',
        ),
        LegalSection(
          'Changes to These Terms',
          'We may update these terms from time to time. Continued use of the app '
              'after changes constitutes acceptance of the revised terms.',
        ),
        LegalSection(
          'Contact',
          'Questions about these terms can be sent to '
              'support@goldengraincalculator.app.',
        ),
      ],
    );
  }
}
