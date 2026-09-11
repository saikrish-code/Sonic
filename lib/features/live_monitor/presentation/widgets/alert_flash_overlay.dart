import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/alert/alert_service.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';

/// Full-screen accessible strobe/banner overlay for Deaf and hard-of-hearing users.
class AlertFlashOverlay extends ConsumerWidget {
  final Widget child;

  const AlertFlashOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAsync = ref.watch(activeAlertBannerProvider);
    final banner = bannerAsync.asData?.value;

    return Stack(
      children: [
        child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HeadsUpAlertCard(banner: banner),
          ),
      ],
    );
  }
}

class _HeadsUpAlertCard extends StatefulWidget {
  final ActiveAlertBanner banner;

  const _HeadsUpAlertCard({required this.banner});

  @override
  State<_HeadsUpAlertCard> createState() => _HeadsUpAlertCardState();
}

class _HeadsUpAlertCardState extends State<_HeadsUpAlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    final topPadding = MediaQuery.of(context).padding.top;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding > 0 ? 8 : 16,
          left: 16,
          right: 16,
        ),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  color: SonicColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: banner.color,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: banner.color.withAlpha(120),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: banner.color.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(color: banner.color, width: 1.5),
                      ),
                      child: Icon(banner.icon, color: banner.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: banner.color.withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  banner.category.toUpperCase(),
                                  style: TextStyle(
                                    color: banner.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(banner.confidence * 100).toInt()}% Match',
                                style: const TextStyle(
                                  color: SonicColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.soundName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: SonicColors.textMuted),
                      onPressed: () {
                        // Dismiss banner
                        final container = ProviderScope.containerOf(context, listen: false);
                        container.read(alertServiceProvider).dismissBanner();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
