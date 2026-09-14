import 'package:flutter/material.dart';

import 'package:eureka/core/theme/app_colors.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.currentIndex, required this.onTap, this.cartCount = 0});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.grid_view_rounded, label: 'Menu'),
    (icon: Icons.receipt_long_rounded, label: 'Orders'),
    (icon: Icons.local_offer_rounded, label: 'Offers'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final selected = index == currentIndex;
            final item = _items[index];
            final showBadge = index == 2 && cartCount > 0;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? AppColors.primary : AppColors.textGrey,
                      ),
                      if (showBadge)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: AppColors.badge, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$cartCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
