import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String getTranslatedEventCategory(BuildContext context, String category) {
  switch (category) {
    case 'Anniversary':
      return AppLocalizations.of(context)!.event_category_anniversary;
    case 'Valentines Day':
      return AppLocalizations.of(context)!.event_category_valentine;
    case 'Birthday':
      return AppLocalizations.of(context)!.event_category_birthday;
    case 'Breakfast':
      return AppLocalizations.of(context)!.event_category_breakfast;
    case 'Lunch':
      return AppLocalizations.of(context)!.event_category_lunch;
    case 'Dinner':
      return AppLocalizations.of(context)!.event_category_dinner;
    case 'Night':
      return AppLocalizations.of(context)!.event_category_night;
    case 'Weekend':
      return AppLocalizations.of(context)!.event_category_weekend;
    case 'Vacation':
      return AppLocalizations.of(context)!.event_category_vacation;
    case 'Shopping':
      return AppLocalizations.of(context)!.event_category_shopping;
    case 'Cinema':
      return AppLocalizations.of(context)!.event_category_cinema;
    case 'Concert':
      return AppLocalizations.of(context)!.event_category_concert;
    case 'Experience':
      return AppLocalizations.of(context)!.event_category_experience;
    case 'Other':
      return AppLocalizations.of(context)!.event_category_other;
    default:
      return category;
  }
}
