import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_config_model.dart';
import '../../../core/providers/app_config_provider.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: configAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => _TermsBody(config: AppConfigModel.fallback),
        data: (config) => _TermsBody(config: config),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  final AppConfigModel config;
  const _TermsBody({required this.config});

  @override
  Widget build(BuildContext context) {
    final store =
        config.storeName.isNotEmpty ? config.storeName : 'DodoMiniMart';
    final phone = config.contactPhone.isNotEmpty ? config.contactPhone : 'N/A';

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
                const Icon(Icons.gavel_outlined,
                    color: Colors.white, size: 32),
                const Gap(10),
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  store,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14),
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
            title: '1. Acceptance of Terms',
            body:
                'By downloading, installing, or using the $store application ("App"), '
                'you agree to be bound by these Terms of Service. If you do not agree, '
                'please do not use the App.',
          ),

          _Section(
            title: '2. Eligibility',
            body:
                'You must be at least 13 years old to use this App. By using the App, '
                'you represent that you meet this requirement. We reserve the right to '
                'terminate accounts of users who misrepresent their age.',
          ),

          _Section(
            title: '3. Account Responsibilities',
            body:
                'You are responsible for:\n\n'
                '• Maintaining the confidentiality of your account\n'
                '• All activities that occur under your account\n'
                '• Ensuring your account information is accurate and up to date\n\n'
                'Notify us immediately if you suspect unauthorized access to your account.',
          ),

          _Section(
            title: '4. Ordering & Payment',
            body:
                '• All prices are listed in Philippine Peso (PHP)\n'
                '• Orders are subject to product availability\n'
                '• We accept GCash and cash-on-delivery where available\n'
                '• We reserve the right to cancel orders due to pricing errors or stock issues\n'
                '• Once an order is confirmed, changes may not be possible',
          ),

          _Section(
            title: '5. Delivery',
            body:
                '• Deliveries are fulfilled by independent Runner partners\n'
                '• Delivery times are estimates and may vary\n'
                '• You are responsible for providing an accurate delivery address\n'
                '• We are not liable for delays caused by factors outside our control '
                '(traffic, weather, etc.)',
          ),

          _Section(
            title: '6. Runner Program',
            body:
                'Users who apply as Runners agree to:\n\n'
                '• Provide accurate personal and identification information\n'
                '• Complete deliveries in a professional and timely manner\n'
                '• Comply with all applicable laws and regulations\n\n'
                'Approval is at our sole discretion. We may suspend or revoke Runner '
                'status at any time.',
          ),

          _Section(
            title: '7. Prohibited Conduct',
            body:
                'You agree not to:\n\n'
                '• Use the App for any unlawful purpose\n'
                '• Submit false or misleading information\n'
                '• Attempt to gain unauthorized access to any part of the App\n'
                '• Interfere with the proper functioning of the App\n'
                '• Use the App to harass or harm other users',
          ),

          _Section(
            title: '8. Intellectual Property',
            body:
                'All content, trademarks, and data on this App, including but not limited '
                'to text, graphics, logos, and images, are the property of $store and are '
                'protected by applicable intellectual property laws. You may not reproduce '
                'or distribute any content without our written permission.',
          ),

          _Section(
            title: '9. Limitation of Liability',
            body:
                'To the maximum extent permitted by law, $store shall not be liable for '
                'any indirect, incidental, or consequential damages arising from your use '
                'of the App. Our total liability shall not exceed the amount paid by you '
                'for the specific order giving rise to the claim.',
          ),

          _Section(
            title: '10. Modifications',
            body:
                'We may update these Terms of Service at any time. Continued use of the '
                'App after changes take effect constitutes your acceptance of the revised terms. '
                'We will notify you of significant changes through the App.',
          ),

          _Section(
            title: '11. Governing Law',
            body:
                'These Terms shall be governed by the laws of the Republic of the Philippines. '
                'Any disputes shall be resolved in the appropriate courts of the Philippines.',
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
                  '12. Contact Us',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const Gap(8),
                Text(
                  'If you have questions about these Terms, please contact $store:',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurface,
                      height: 1.5),
                ),
                const Gap(12),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Phone: ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onBackground)),
                    Text(phone,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.onSurface)),
                  ],
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
