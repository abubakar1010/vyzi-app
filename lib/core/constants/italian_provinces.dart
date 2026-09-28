/// The Italian provinces, keyed by their official two-letter *sigla*.
///
/// Every province captured in the app resolves to one of these codes, so a
/// case never reaches the backend with "MI", "Mi" and "Milano" meaning the
/// same place.
class ItalianProvinces {
  const ItalianProvinces._();

  static const Map<String, String> byCode = {
    'AG': 'Agrigento',
    'AL': 'Alessandria',
    'AN': 'Ancona',
    'AO': 'Aosta',
    'AR': 'Arezzo',
    'AP': 'Ascoli Piceno',
    'AT': 'Asti',
    'AV': 'Avellino',
    'BA': 'Bari',
    'BT': 'Barletta-Andria-Trani',
    'BL': 'Belluno',
    'BN': 'Benevento',
    'BG': 'Bergamo',
    'BI': 'Biella',
    'BO': 'Bologna',
    'BZ': 'Bolzano',
    'BS': 'Brescia',
    'BR': 'Brindisi',
    'CA': 'Cagliari',
    'CL': 'Caltanissetta',
    'CB': 'Campobasso',
    'CE': 'Caserta',
    'CT': 'Catania',
    'CZ': 'Catanzaro',
    'CH': 'Chieti',
    'CO': 'Como',
    'CS': 'Cosenza',
    'CR': 'Cremona',
    'KR': 'Crotone',
    'CN': 'Cuneo',
    'EN': 'Enna',
    'FM': 'Fermo',
    'FE': 'Ferrara',
    'FI': 'Firenze',
    'FG': 'Foggia',
    'FC': 'Forlì-Cesena',
    'FR': 'Frosinone',
    'GE': 'Genova',
    'GO': 'Gorizia',
    'GR': 'Grosseto',
    'IM': 'Imperia',
    'IS': 'Isernia',
    'AQ': "L'Aquila",
    'SP': 'La Spezia',
    'LT': 'Latina',
    'LE': 'Lecce',
    'LC': 'Lecco',
    'LI': 'Livorno',
    'LO': 'Lodi',
    'LU': 'Lucca',
    'MC': 'Macerata',
    'MN': 'Mantova',
    'MS': 'Massa-Carrara',
    'MT': 'Matera',
    'ME': 'Messina',
    'MI': 'Milano',
    'MO': 'Modena',
    'MB': 'Monza e della Brianza',
    'NA': 'Napoli',
    'NO': 'Novara',
    'NU': 'Nuoro',
    'OR': 'Oristano',
    'PD': 'Padova',
    'PA': 'Palermo',
    'PR': 'Parma',
    'PV': 'Pavia',
    'PG': 'Perugia',
    'PU': 'Pesaro e Urbino',
    'PE': 'Pescara',
    'PC': 'Piacenza',
    'PI': 'Pisa',
    'PT': 'Pistoia',
    'PN': 'Pordenone',
    'PZ': 'Potenza',
    'PO': 'Prato',
    'RG': 'Ragusa',
    'RA': 'Ravenna',
    'RC': 'Reggio Calabria',
    'RE': 'Reggio Emilia',
    'RI': 'Rieti',
    'RN': 'Rimini',
    'RM': 'Roma',
    'RO': 'Rovigo',
    'SA': 'Salerno',
    'SS': 'Sassari',
    'SV': 'Savona',
    'SI': 'Siena',
    'SR': 'Siracusa',
    'SO': 'Sondrio',
    'SU': 'Sud Sardegna',
    'TA': 'Taranto',
    'TE': 'Teramo',
    'TR': 'Terni',
    'TO': 'Torino',
    'TP': 'Trapani',
    'TN': 'Trento',
    'TV': 'Treviso',
    'TS': 'Trieste',
    'UD': 'Udine',
    'VA': 'Varese',
    'VE': 'Venezia',
    'VB': 'Verbano-Cusio-Ossola',
    'VC': 'Vercelli',
    'VR': 'Verona',
    'VV': 'Vibo Valentia',
    'VI': 'Vicenza',
    'VT': 'Viterbo',
  };

  /// Sigle in alphabetical order of province name — the order the picker shows.
  static final List<String> codes = byCode.keys.toList()
    ..sort((a, b) => byCode[a]!.compareTo(byCode[b]!));

  static String? nameOf(String? code) {
    if (code == null) return null;
    return byCode[code.trim().toUpperCase()];
  }

  static bool isValid(String? code) => nameOf(code) != null;

  /// Resolves free text to a sigla: accepts the code itself (`mi`) or the
  /// province name (`Milano`). Returns null when nothing matches, so OCR noise
  /// is discarded rather than stored.
  static String? resolve(String? input) {
    final value = input?.trim();
    if (value == null || value.isEmpty) return null;

    final upper = value.toUpperCase();
    if (byCode.containsKey(upper)) return upper;

    for (final entry in byCode.entries) {
      if (entry.value.toUpperCase() == upper) return entry.key;
    }
    return null;
  }

  /// `MI — Milano`, the label used in the picker and in read-only summaries.
  static String label(String code) {
    final name = nameOf(code);
    final sigla = code.trim().toUpperCase();
    return name == null ? sigla : '$sigla — $name';
  }

  static List<String> search(String query) {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return codes;
    return codes
        .where((c) => c.contains(q) || byCode[c]!.toUpperCase().contains(q))
        .toList();
  }
}
