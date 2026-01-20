import 'package:flutter/material.dart';

/// Shimmer effect widget for loading placeholders.
/// Creates an animated gradient effect that simulates content loading.
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
                Color(0xFF2A2A2A),
                Color(0xFF3A3A3A),
                Color(0xFF2A2A2A),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard shimmer placeholder that mimics the full dashboard layout.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert card shimmer
          _buildAlertShimmer(),
          const SizedBox(height: 24),

          // Stats grid shimmer
          _buildStatsGridShimmer(),
          const SizedBox(height: 24),

          // Quick actions shimmer
          _buildQuickActionsShimmer(),
          const SizedBox(height: 24),

          // Search bar shimmer
          ShimmerWidget.rectangular(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 16),

          // Trainee cards shimmer
          ..._buildTraineeCardsShimmer(),
        ],
      ),
    );
  }

  Widget _buildAlertShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerWidget.circular(size: 24),
              const SizedBox(width: 8),
              ShimmerWidget.rectangular(
                width: 120,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              ShimmerWidget.rectangular(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const ShimmerWidget.circular(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.rectangular(
                        width: 150,
                        height: 14,
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
                  height: 32,
                  borderRadius: BorderRadius.circular(4),
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
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ShimmerWidget.circular(size: 28),
              const SizedBox(height: 8),
              ShimmerWidget.rectangular(
                width: 50,
                height: 22,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              ShimmerWidget.rectangular(
                width: 80,
                height: 11,
                borderRadius: BorderRadius.circular(4),
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
              left: index == 0 ? 0 : 6,
              right: index == 2 ? 0 : 6,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const ShimmerWidget.circular(size: 24),
                  const SizedBox(height: 4),
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
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const ShimmerWidget.circular(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget.rectangular(
                          width: 150,
                          height: 14,
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget.rectangular(
                          width: double.infinity,
                          height: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerWidget.rectangular(
                          width: 80,
                          height: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ShimmerWidget.circular(size: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
