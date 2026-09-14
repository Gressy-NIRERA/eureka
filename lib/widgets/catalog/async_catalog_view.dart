import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/core/theme/app_colors.dart';
import 'package:eureka/widgets/common/empty_state.dart';

/// Renders the four states every catalog-backed screen goes through
/// (loading / network error / empty results / content), so `MenuTab`,
/// `OffersTab` and the home preview all share one implementation instead of
/// each repeating the same spinner-or-error-or-empty boilerplate.
class AsyncCatalogView extends StatelessWidget {
  const AsyncCatalogView({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyMessage = AppStrings.noResults,
    this.emptyIcon = Icons.search_off_rounded,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (errorMessage != null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        message: errorMessage!,
        actionLabel: AppStrings.retry,
        onAction: onRetry,
      );
    }

    if (isEmpty) {
      return EmptyState(icon: emptyIcon, message: emptyMessage);
    }

    return child;
  }
}
