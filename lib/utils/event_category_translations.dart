import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String getTranslatedEventCategory(BuildContext context, String category) {
  switch (category) {
    case 'Anniversary':
      return AppLocalizations.of(context)!.event_type_anniversary;
    case 'Valentines Day':
      return AppLocalizations.of(context)!.event_type_valentine;
    case 'Birthday':
      return AppLocalizations.of(context)!.event_type_birthday;
    case 'Dinner':
      return AppLocalizations.of(context)!.event_type_dinner;
    case 'Night':
      return AppLocalizations.of(context)!.event_type_night;
    case 'Weekend':
      return AppLocalizations.of(context)!.event_type_weekend;
    case 'Vacation':
      return AppLocalizations.of(context)!.event_type_vacation;
    case 'Shopping':
      return AppLocalizations.of(context)!.event_type_shopping;
    case 'Cinema':
      return AppLocalizations.of(context)!.event_type_cinema;
    case 'Concert':
      return AppLocalizations.of(context)!.event_type_concert;
    case 'Experience':
      return AppLocalizations.of(context)!.event_type_experience;
    case 'Other':
      return AppLocalizations.of(context)!.event_type_other;
    default:
      return category;
  }
}
