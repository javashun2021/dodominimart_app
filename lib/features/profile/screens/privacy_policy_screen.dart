import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_config_model.dart';
import '../../../core/providers/app_config_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: configAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => _PrivacyBody(config: AppConfigModel.fallback),
        data: (config) => _PrivacyBody(config: config),
      ),
    );
  }
}

class _PrivacyBody extends StatelessWidget {
  final AppConfigModel config;
  const _PrivacyBody({required this.config});

  @override
  Widget build(BuildContext context) {
    final store = config.storeName.isNotEmpty ? config.storeName : 'DodoMiniMart';
    final phone = config.contactPhone.isNotEmpty ? config.contactPhone : 'N/A';
    final messenger = config.messengerLink.isNotEmpty
        ? config.messengerLink
        : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8540), Color(0xFFC2410C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined,
                    color: Colors.white, size: 32),
                const Gap(10),
                Text(
                  'Privacy Policy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  store,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Gap(8),
                const Text(
                  'Last updated: May 2025',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          const Gap(20),

          _Section(
            title: '1. Introduction',
            body:
                '$store ("we", "our", or "us") is committed to protecting your personal information. '
                'This Privacy Policy explains how we collect, use, and share your data when you use our '
                'mobile application.',
          ),

          _Section(
            title: '2. Information We Collect',
            body: 'We collect the following personal information:\n\n'
                '• Name and email address (via Google Sign-In)\n'
                '• Phone number\n'
                '• Delivery address\n'
                '• Profile photo (optional)\n'
                '• Government-issued ID photo (for Runner applicants only)\n'
                '• Order history and transaction records',
          ),

          _Section(
            title: '3. How We Use Your Information',
            body: 'Your information is used to:\n\n'
                '• Process and deliver your orders\n'
                '• Coordinate deliveries with Runner partners\n'
                '• Review Runner delivery partner applications\n'
                '• Send order status notifications\n'
                '• Improve our services and user experience',
          ),

          _Section(
            title: '4. Third-Party Services',
            body: 'We use the following third-party services:\n\n'
                '• Google Sign-In — for account authentication\n'
                '• GCash — for payment processing\n\n'
                'These services have their own privacy policies. We recommend reviewing them.',
          ),

          _Section(
            title: '5. Data Sharing',
            body: 'We do not sell your personal data. We may share limited information with:\n\n'
                '• Runner delivery partners (delivery address and order amount only)\n'
                '• Internal staff for order management and support purposes',
          ),

          _Section(
            title: '6. Data Retention',
            body: 'We retain your personal data for as long as your account is active. '
                'Upon account deletion, your data will be permanently removed within 30 days, '
                'except where retention is required by law.',
          ),

          _Section(
            title: '7. Your Rights',
            body: 'You have the right to:\n\n'
                '• Access and review your personal information\n'
                '• Correct inaccurate data\n'
                '• Request deletion of your account and data\n\n'
                'To exercise these rights, please contact us using the information below.',
          ),

          _Section(
            title: '8. Children\'s Privacy',
            body: 'Our application is not directed to children under the age of 13. '
                'We do not knowingly collect personal information from children. '
                'If you believe a child has provided us with their information, '
                'please contact us immediately.',
          ),

          _Section(
            title: '9. Security',
            body: 'We implement reasonable technical and organizational measures to protect '
                'your personal information from unauthorized access, disclosure, alteration, '
                'or destruction.',
          ),

          _Section(
            title: '10. Changes to This Policy',
            body: 'We may update this Privacy Policy from time to time. '
                'We will notify you of significant changes through the app. '
                'Continued use of the app after changes constitutes acceptance of the updated policy.',
          ),

          // 联系方式
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '11. Contact Us',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const Gap(8),
                const Text(
                  'If you have any questions about this Privacy Policy or your personal data, '
                  'please contact us:',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.5),
                ),
                const Gap(12),
                _ContactRow(
                  icon: Icons.storefront_outlined,
                  label: 'Developer',
                  value: store,
                ),
                const Gap(8),
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: phone,
                ),
                const Gap(8),
                _ContactRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messenger',
                  value: messenger,
                ),
              ],
            ),
          ),

          const Gap(32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const Gap(6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackground),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}
