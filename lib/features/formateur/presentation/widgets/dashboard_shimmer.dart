import 'package:flutter/material.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

/// Shimmer effect widget for loading placeholders.
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shapeBorder;

  const ShimmerWidget.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : shapeBorder = null;

  const ShimmerWidget.circular({
    super.key,
    required double size,
    this.shapeBorder = const CircleBorder(),
  })  : width = size,
        height = size,
        borderRadius = null;

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            shape: widget.shapeBorder ?? RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard shimmer placeholder.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Header Shimmer
          _buildHeaderShimmer(),
           const SizedBox(height: 32),

          // Alert card shimmer
          _buildAlertShimmer(),
          const SizedBox(height: 32),

          // Stats grid shimmer
          _buildStatsGridShimmer(),
          const SizedBox(height: 32),

          // Quick actions shimmer
          _buildQuickActionsShimmer(),
          const SizedBox(height: 32),

          // Search bar shimmer
          ShimmerWidget.rectangular(
            width: double.infinity,
            height: 56,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),

          // Trainee cards shimmer
          ..._buildTraineeCardsShimmer(),
        ],
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget.rectangular(
          width: 150,
          height: 24,
           borderRadius: BorderRadius.circular(20),
        ),
         const SizedBox(height: 16),
         ShimmerWidget.rectangular(
          width: 250,
          height: 48,
           borderRadius: BorderRadius.circular(8),
        ),
         const SizedBox(height: 12),
          ShimmerWidget.rectangular(
          width: 300,
          height: 16,
           borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildAlertShimmer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerWidget.circular(size: 32),
              const SizedBox(width: 12),
              ShimmerWidget.rectangular(
                width: 140,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              ShimmerWidget.rectangular(
                width: 80,
                height: 28,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FormateurTheme.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const ShimmerWidget.circular(size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.rectangular(
                        width: 150,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      ShimmerWidget.rectangular(
                        width: 100,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                ShimmerWidget.rectangular(
                  width: 100,
                  height: 40,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGridShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
             border: Border.all(color: FormateurTheme.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    ShimmerWidget.rectangular(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                   const ShimmerWidget.circular(size: 36),
                 ],
               ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   ShimmerWidget.rectangular(
                    width: 60,
                    height: 32,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  ShimmerWidget.rectangular(
                    width: 80,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsShimmer() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == 2 ? 0 : 8,
            ),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                 border: Border.all(color: FormateurTheme.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ShimmerWidget.circular(size: 48),
                  const SizedBox(height: 8),
                  ShimmerWidget.rectangular(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTraineeCardsShimmer() {
    return List.generate(
      3,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
             border: Border.all(color: FormateurTheme.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const ShimmerWidget.circular(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget.rectangular(
                          width: 150,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerWidget.rectangular(
                          width: 120,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const ShimmerWidget.rectangular(width: 24, height: 24)
                ],
              ),
              const SizedBox(height: 20),
              Row(
                 children: [
                    Expanded(
                      child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           ShimmerWidget.rectangular(width: 60, height: 10, borderRadius: BorderRadius.circular(4)),
                           const SizedBox(height: 6),
                           ShimmerWidget.rectangular(width: double.infinity, height: 20, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                     const SizedBox(width: 16),
                     Expanded(
                      child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           ShimmerWidget.rectangular(width: 60, height: 10, borderRadius: BorderRadius.circular(4)),
                           const SizedBox(height: 6),
                           ShimmerWidget.rectangular(width: double.infinity, height: 20, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                 ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
