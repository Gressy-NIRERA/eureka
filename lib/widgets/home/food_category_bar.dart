import 'package:flutter/material.dart';

import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/data/models/food_models.dart';

/// Sentinel id used for the synthetic "All Items" entry prepended to the
/// categories returned by `GET /categorysystem/{iso}`.
const int kAllCategoriesId = -1;

IconData iconForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('bucket') || n.contains('poulet') || n.contains('chicken')) {
    return Icons.set_meal_rounded;
  }
  if (n.contains('burger')) return Icons.lunch_dining_rounded;
  if (n.contains('tender') || n.contains('wing')) return Icons.kebab_dining_rounded;
  if (n.contains('side') || n.contains('fries') || n.contains('accomp')) {
    return Icons.fastfood_rounded;
  }
  if (n.contains('drink') || n.contains('boisson') || n.contains('juice')) {
    return Icons.local_drink_rounded;
  }
  if (n.contains('dessert') || n.contains('sweet')) return Icons.icecream_rounded;
  return Icons.restaurant_menu_rounded;
}

/// Horizontal row of round category icons (All Items, Buckets, Burgers, ...)
/// driven by the real `FoodCategory` list fetched from the Duma food API.
class FoodCategoryBar extends StatelessWidget {
  const FoodCategoryBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<FoodCategory> categories;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <({int id, String label, String? image})>[
      (id: kAllCategoriesId, label: 'All Items', image: null),
      for (final c in categories) (id: c.id, label: c.name, image: c.image),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(item.id),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.chipBackground,
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: item.image != null && item.image!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              item.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                iconForCategory(item.label),
                                color: selected ? Colors.white : AppColors.primary,
                              ),
                            ),
                          )
                        : Icon(
                            item.id == kAllCategoriesId
                                ? Icons.grid_view_rounded
                                : iconForCategory(item.label),
                            color: selected ? Colors.white : AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.textDark : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
