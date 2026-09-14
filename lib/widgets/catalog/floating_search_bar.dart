import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/core/theme/app_colors.dart';

/// A search bar that behaves like a Material "floating" app bar: it scrolls
/// away with the content, but reappears immediately as soon as the user
/// scrolls back up by even a small amount (`floating: true, snap: true`),
/// instead of staying hidden until they scroll all the way to the top.
/// Used by both the Home and Menu tabs so the search field never stays
/// permanently gone while browsing.
class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.hintText = AppStrings.searchHint,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final String hintText;

  /// When true the field only forwards taps via [onTap] instead of being
  /// directly editable — used by the Home tab, where the search bar is a
  /// shortcut into the Menu tab rather than a second, duplicate query field.
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      automaticallyImplyLeading: false,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: Padding(
        padding: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            if (onFilterTap != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.tune_rounded, color: AppColors.textDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
