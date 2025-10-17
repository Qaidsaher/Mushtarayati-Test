import 'package:flutter/material.dart';
import '../../../core/utils/app_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عن التطبيق'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App header card
                  _InfoCard(
                    title: AppInfo.title,
                    subtitle: 'الإصدار ${AppInfo.version}',
                    icon: Icons.shopping_cart_rounded,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppInfo.description}\n${AppInfo.longDescription}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppInfo.longDescription,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Developer card
                  _InfoCard(
                    title: 'المطور',
                    subtitle: AppInfo.developerName,
                    icon: Icons.person_rounded,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.tertiaryContainer,
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // One-line professional bio
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'شغوف ببناء حلول عملية لمشاكل حقيقية تُحدث أثراً ملموساً، مع تركيز على البساطة والجودة وسهولة الاستخدام.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.phone_in_talk_rounded,
                          label: 'الهاتف',
                          value: AppInfo.developerPhone,
                          color: Colors.green[700],
                          onTap:
                              () => _launchUri(
                                Uri.parse('tel:${AppInfo.developerPhone}'),
                              ),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.email_rounded,
                          label: 'البريد الإلكتروني',
                          value: AppInfo.developerEmail,
                          color: Colors.blue[700],
                          onTap:
                              () => _launchUri(
                                Uri.parse('mailto:${AppInfo.developerEmail}'),
                              ),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.language_rounded,
                          label: 'الموقع',
                          value: AppInfo.developerWebsite,
                          color: Colors.purple[700],
                          onTap:
                              () => _launchUri(
                                Uri.parse(
                                  'https://${AppInfo.developerWebsite}',
                                ),
                              ),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.link_rounded,
                          label: 'LinkedIn',
                          value: AppInfo.linkedinUrl,
                          color: Colors.blue[800],
                          onTap:
                              () => _launchUri(Uri.parse(AppInfo.linkedinUrl)),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.chat_bubble_rounded,
                          label: 'WhatsApp',
                          value: AppInfo.whatsappUrl,
                          color: Colors.green[700],
                          onTap:
                              () => _launchUri(Uri.parse(AppInfo.whatsappUrl)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Thanks / footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'شكرًا لاستخدامك ${AppInfo.appName}! نعمل على تحسين التجربة دائمًا.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DefaultTextStyle(
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    final row = Row(
      children: [
        Icon(icon, color: c),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
    );
  }
}

Future<void> _launchUri(Uri uri) async {
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('cannot launch');
    }
  } catch (_) {
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }
}
