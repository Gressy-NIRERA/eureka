import 'package:flutter/material.dart';

import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/widgets/common/top_icon_button.dart';

/// Simple, non-scrolling title bar used by the Menu, Orders, Offers and
/// Profile tabs so each secondary screen doesn't reinvent its own header.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.trailingIcon, this.onTrailingTap, this.trailingBadge = 0});

  final String title;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final int trailingBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          if (trailingIcon != null && onTrailingTap != null)
            TopIconButton(icon: trailingIcon!, onTap: onTrailingTap!, badgeCount: trailingBadge),
        ],
      ),
    );
  }
}
