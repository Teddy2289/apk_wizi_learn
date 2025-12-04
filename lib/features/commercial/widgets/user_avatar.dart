import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/commercial_colors.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final Gradient? gradient;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.gradient,
  });

  String _getInitials() {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: CommercialColors.borderOrange,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildInitialsAvatar(),
            errorWidget: (context, url, error) => _buildInitialsAvatar(),
          ),
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? CommercialColors.orangeGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: CommercialColors.borderOrange,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
