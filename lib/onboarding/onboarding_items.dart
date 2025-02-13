import 'package:couplers/onboarding/onboarding_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingItems {
  final BuildContext context;
  late final List<OnboardingInfo> items;

  OnboardingItems(this.context) {
    items = [
      OnboardingInfo(
        title: AppLocalizations.of(context)!.onboarding_first_title,
        description: AppLocalizations.of(context)!.onboarding_first_description,
        image: Image.asset('assets/images/onboarding_add.png'),
      ),
      OnboardingInfo(
        title: AppLocalizations.of(context)!.onboarding_second_title,
        description:
            AppLocalizations.of(context)!.onboarding_second_description,
        image: Image.asset('assets/images/onboarding_view.png'),
      ),
      OnboardingInfo(
        title: AppLocalizations.of(context)!.onboarding_third_title,
        description: AppLocalizations.of(context)!.onboarding_third_description,
        image: Image.asset('assets/images/onboarding_milestones.png'),
      ),
      OnboardingInfo(
        title: AppLocalizations.of(context)!.onboarding_fourth_title,
        description:
            AppLocalizations.of(context)!.onboarding_fourth_description,
        image: Image.asset('assets/images/onboarding_map.png'),
      ),
    ];
  }
}
