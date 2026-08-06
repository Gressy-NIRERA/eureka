import 'package:flutter/material.dart';
import 'package:eureka/home.dart';
import 'package:eureka/profile.dart';
import 'package:eureka/wishlist.dart';
import 'package:eureka/shop.dart';

class Control extends StatefulWidget {
  const Control({super.key});

  @override
  State<Control> createState() => _ControlState();
}

class _ControlState extends State<Control> {
  static const Color kPrimary = Color(0xFFFF5A1F);
  static const Color kPrimaryDark = Color(0xFFE34B18);
  static const Color kTextGrey = Color(0xFFB9B9C0);

  int selectedIndex = 0;

  final List<Widget> pages = const [
    Home(),
    Wishlist(),
    Shop(),
    Profile(),
  ];

  final List<_NavItem> items = const [
    _NavItem(icon: Icons.home_rounded, label: "Accueil"),
    _NavItem(icon: Icons.favorite_rounded, label: "Favoris"),
    _NavItem(icon: Icons.shopping_bag_rounded, label: "Panier"),
    _NavItem(icon: Icons.person_rounded, label: "Profil"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final bool selected = index == selectedIndex;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                    padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 0),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [kPrimary, kPrimaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 21,
                          color: selected ? Colors.white : kTextGrey,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: selected
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 7),
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                )
                              : const SizedBox(width: 0),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}