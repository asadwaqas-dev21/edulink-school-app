import "package:flutter/material.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";

class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double radius;
  final Color? color;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.radius = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg.withValues(alpha: 0.12),
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg.withValues(alpha: 0.14),
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
