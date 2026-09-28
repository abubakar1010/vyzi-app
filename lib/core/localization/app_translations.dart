import 'package:get/get.dart';
import 'it_it.dart';
import 'en_us.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'it_IT': itIT,
        'it': itIT,
        'en_US': enUS,
        'en': enUS,
      };
}
