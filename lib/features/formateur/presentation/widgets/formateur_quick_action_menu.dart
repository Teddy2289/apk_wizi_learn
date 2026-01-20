import 'package:flutter/material.dart';

class FormateurQuickActionMenu extends StatefulWidget {
  final List<QuickAction> actions;

  const FormateurQuickActionMenu({
    Key? key,
    required this.actions,
  }) : super(key: key);

  @override
  State<FormateurQuickActionMenu> createState() =>
      _FormateurQuickActionMenuState();
}

class _FormateurQuickActionMenuState extends State<FormateurQuickActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isOpen)
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              constraints: BoxConstraints.expand(),
            ),
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < widget.actions.length; i++)
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0),
                            end: Offset(0, -(i + 1) * 70),
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: _buildActionButton(widget.actions[i]),
                        ),
                    ],
                  ),
                ),
              ),
            FloatingActionButton(
              onPressed: _toggleMenu,
              backgroundColor: const Color(0xFFF7931E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _animationController,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(QuickAction action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            action.onTap?.call();
            _toggleMenu();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF7931E).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  color: const Color(0xFFF7931E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });
}
