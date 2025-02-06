import 'package:couplers/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_map/free_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class FullScreenMap extends StatefulWidget {
  final void Function(LatLng, String) onPositionConfirmed;

  const FullScreenMap({
    super.key,
    required this.onPositionConfirmed,
  });

  @override
  FullScreenMapState createState() => FullScreenMapState();
}

class FullScreenMapState extends State<FullScreenMap> {
  FmData? _address;
  late final MapController _mapController;
  final _src = const LatLng(41.9099533, 12.371192);
  LatLng? _selectedPosition;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          bottom: false,
          child: Stack(children: [_map, _searchField(locale), _confirmButton]),
        ),
      ),
    );
  }

  Widget get _map {
    return FmMap(
      mapController: _mapController,
      mapOptions: MapOptions(
        initialZoom: 6.r,
        initialCenter: _src,
        onTap: (pos, point) => setState(() {
          _selectedPosition = point;
          _getAddress(point);
        }),
      ),
      markers: [
        if (_selectedPosition != null)
          Marker(
            point: _selectedPosition!,
            child: Icon(
              MingCuteIcons.mgc_location_fill,
              color: AppColors.toastDarkRed,
              size: 20.sp,
            ),
          ),
      ],
    );
  }

  Widget _searchField(Locale locale) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: FmSearchField(
        selectedValue: _address,
        searchParams: FmSearchParams(langs: [locale.languageCode]),
        onSelected: (data) {
          setState(
            () {
              _address = data;
              if (data != null) {
                _selectedPosition = LatLng(
                  data.lat,
                  data.lng,
                );
                _selectedAddress = data.address;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(_selectedPosition!, 10.r);
                });
              }
            },
          );
        },
        textFieldBuilder: (focus, controller, onChanged) {
          return TextFormField(
            focusNode: focus,
            onChanged: onChanged,
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.tertiaryFixed,
              hintText:
                  AppLocalizations.of(context)!.full_map_screen_search_text,
              suffixIcon: controller.text.trim().isEmpty || !focus.hasFocus
                  ? null
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        MingCuteIcons.mgc_close_fill,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      onPressed: controller.clear,
                      visualDensity: VisualDensity.compact,
                    ),
            ),
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        },
      ),
    );
  }

  Widget get _confirmButton {
    return Positioned(
      bottom: 20,
      left: 80,
      right: 80,
      child: SizedBox(
        width: 20.w,
        height: 46.h,
        child: ElevatedButton(
          onPressed: _selectedPosition == null
              ? null
              : () {
                  if (_selectedAddress != null) {
                    widget.onPositionConfirmed(
                        _selectedPosition!, _selectedAddress!);
                  }
                  Get.back();
                },
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiaryFixed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r))),
          child: Text(
            AppLocalizations.of(context)!.full_map_screen_confirm_button,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getAddress(LatLng pos) async {
    final data = await FmService().getAddress(
      lat: pos.latitude,
      lng: pos.longitude,
    );
    if (kDebugMode) print(data?.address);
    setState(() {
      _selectedAddress = data?.address;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedPosition != null) {
        _mapController.move(_selectedPosition!, 6.r);
      }
    });
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          MingCuteIcons.mgc_large_arrow_left_fill,
          color: Theme.of(context).colorScheme.secondary,
        ),
        onPressed: () {
          Get.back();
        },
      ),
      title: Text(
        AppLocalizations.of(context)!.full_map_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }
}
