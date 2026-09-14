import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/login.dart';
import 'package:eureka/widgets/common/empty_state.dart';
import 'package:eureka/widgets/common/page_header.dart';

/// Order history requires an authenticated session (`GET /order/user` on
/// the Duma food API needs a bearer token) and Eureka has no persisted
/// login session yet, so this honestly asks the user to sign in instead of
/// showing fabricated orders. It reuses the existing [LoginWidget] screen
/// rather than duplicating a login form here.
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: PageHeader(title: AppStrings.ordersTitle)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              message: AppStrings.noOrdersSignedOut,
              actionLabel: AppStrings.noOrdersSignedOutAction,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginWidget()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
