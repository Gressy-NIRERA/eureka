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
  static const Color kTextBlack = Color(0xFF1E2022);

  int selectedIndex = 0;

  final List<Widget> pages = const [
    Home(),
    Wishlist(),
    Shop(),
    Profile(),
  ];

  final List<_NavItem> items = const [
    _NavItem(icon: Icons.home_rounded,label: "Accueil",),
    _NavItem(icon: Icons.favorite_rounded,label: "Favoris",),
    _NavItem(icon: Icons.shopping_bag_rounded,label: "Panier",),
    _NavItem( icon: Icons.person_rounded, label: "Profil",),
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
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            height: 58,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E1CD),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(
                    items.length,
                    (index) {
                      final item = items[index];
                      final selected = selectedIndex == index;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 250,
                            ),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.symmetric(
                              horizontal: selected ? 8 : 0,
                            ),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [
                                        kPrimary,
                                        kPrimaryDark,
                                      ],
                                    )
                                  : null,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: selected
                                        ? Colors.white
                                        : kTextBlack,
                                  ),

                                  if (selected) ...[
                                    const SizedBox(width: 5),

                                    Flexible(
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}