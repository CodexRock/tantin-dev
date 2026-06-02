import 'package:flutter/widgets.dart';
import 'package:tantin_flutter/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
