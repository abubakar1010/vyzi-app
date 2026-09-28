
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // Search
  static const String searchHint = 'Cerca qui...';

  // Section headers
  static const String categories = 'Categorie';
  static const String popularFoodNearby = 'Popolari nelle vicinanze';
  static const String foodCampaign = 'Campagna';
  static const String restaurants = 'Ristoranti';
  static const String viewAll = 'Vedi tutto';

  // Error messages
  static const String noInternetConnection = 'Nessuna connessione Internet';
  static const String noInternetMessage =
      'Nessuna connessione Internet. Riprova.';
  static const String oops = 'Ops!';
  static const String retry = 'Riprova';
  static const String loadMoreFailed = 'Caricamento fallito';
  static const String requestTimeout = 'Richiesta scaduta. Riprova';
  static const String serverError = 'Errore del server';
  static const String unexpectedError = 'Si è verificato un errore imprevisto';
  static const String failedToLoadData = 'Impossibile caricare i dati';

  // Placeholders
  static const String unknownProduct = 'Prodotto sconosciuto';
  static const String unknownRestaurant = 'Ristorante sconosciuto';
  static const String unknownCategory = 'Categoria sconosciuta';

  // Address
  static const String defaultAddress = 'Via Roma, 1, Roma, IT';

  // Cache messages
  static const String cacheNotInitialized =
      'Servizio di cache non inizializzato. Chiama prima init().';
}

