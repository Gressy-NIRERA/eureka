/// Centralised French copy for the Eureka UI.
///
/// The Duma food catalog is a general marketplace (drinks, breakfast,
/// starters, meat & fish, vegetarian, bakery, dairy, ...), not a
/// single-cuisine app, and the rest of Eureka (login, register) is already
/// in French — so every screen-level label lives here in French instead of
/// being hard-coded in English per-widget, one place to keep them
/// consistent and translated.
abstract final class AppStrings {
  // Bottom navigation
  static const String navHome = 'Accueil';
  static const String navMenu = 'Menu';
  static const String navOrders = 'Commandes';
  static const String navOffers = 'Offres';
  static const String navProfile = 'Profil';

  // Home tab
  static const String greeting = 'Bonjour';
  static const String homeHeadline = 'Votre nourriture,\nlivrée rapidement.';
  static const String searchHint = 'Rechercher un plat, une boisson...';
  static const String popularSectionTitle = 'Populaires près de vous';
  static const String seeAll = 'Voir tout';
  static const String orderNow = 'Commander';

  // Shared catalog states
  static const String loadingError = 'Impossible de charger le menu. Vérifiez votre connexion.';
  static const String retry = 'Réessayer';
  static const String noResults = 'Aucun article trouvé';
  static const String addedToCart = 'ajouté au panier';

  // Menu tab
  static const String menuTitle = 'Le Menu';
  static const String allCategories = 'Tout';

  // Offers tab
  static const String offersTitle = 'Offres du moment';
  static const String noOffers = 'Aucune offre pour le moment';

  // Orders tab
  static const String ordersTitle = 'Mes commandes';
  static const String noOrdersSignedOut = 'Connectez-vous pour voir vos commandes.';
  static const String noOrdersSignedOutAction = 'Se connecter';

  // Profile tab
  static const String profileTitle = 'Profil';
  static const String profileGuestTitle = 'Vous n\'êtes pas connecté';
  static const String profileGuestSubtitle = 'Connectez-vous pour suivre vos commandes et vos favoris.';
  static const String login = 'Se connecter';
  static const String register = 'Créer un compte';

  // Product badges
  static const String badgeBestseller = 'MEILLEURE VENTE';
  static const String badgePopular = 'POPULAIRE';
  static String badgeDiscount(int percent) => '-$percent%';
}
