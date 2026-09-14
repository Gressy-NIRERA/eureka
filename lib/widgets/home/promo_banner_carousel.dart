import 'package:flutter/material.dart';

import 'package:eureka/core/strings/app_strings.dart';
import 'package:eureka/core/theme/app_colors.dart';

class PromoSlide {
  final String tag;
  final String title;
  final String subtitle;
  final String imageUrl;

  const PromoSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

/// The Duma food catalog spans drinks, breakfast, starters, meat & fish,
/// vegetarian, bakery and dairy — not a single cuisine — so these slides
/// promote the marketplace itself rather than one dish, in French to match
/// the rest of the app.
const List<PromoSlide> kPromoSlides = [
  PromoSlide(
    tag: 'LIVRAISON RAPIDE',
    title: 'Votre repas,\nlivré rapidement',
    subtitle: 'Des dizaines de restaurants réunis pour vous.',
    imageUrl:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=80',
  ),
  PromoSlide(
    tag: 'NOUVEAU',
    title: 'De nouvelles\nsaveurs chaque jour',
    subtitle: 'Des plats fraîchement préparés par nos partenaires.',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
  ),
  PromoSlide(
    tag: 'OFFRE DU MOMENT',
    title: 'Jusqu\'à -30%\nsur une sélection',
    subtitle: 'Profitez des promotions disponibles maintenant.',
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
  ),
];

/// Hero carousel that reproduces the deep-red promotional banner from the
/// reference design, with a page indicator underneath.
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key, required this.onOrderNow});

  final VoidCallback onOrderNow;

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: _controller,
            itemCount: kPromoSlides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) =>
                _PromoCard(slide: kPromoSlides[index], onOrderNow: widget.onOrderNow),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(kPromoSlides.length, (index) {
            final active = index == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.chipBackground,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.slide, required this.onOrderNow});

  final PromoSlide slide;
  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bannerStart, AppColors.bannerEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bannerEnd.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            top: -10,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(26)),
              child: Image.network(
                slide.imageUrl,
                width: 165,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 165),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox(width: 165),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.bannerStart.withValues(alpha: 0.96),
                    AppColors.bannerStart.withValues(alpha: 0.0),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 130, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    slide.tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onOrderNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.orderNow,
                          style: TextStyle(
                            color: AppColors.bannerEnd,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 15, color: AppColors.bannerEnd),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
