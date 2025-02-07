import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/screens/events/event_updater_screen.dart';
import 'package:couplers/widgets/full_screen_image.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/utils/event_category_translations.dart';
import 'package:couplers/widgets/custom_delete_dialog.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_note.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_map/free_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  EventDetailsScreenState createState() => EventDetailsScreenState();
}

class EventDetailsScreenState extends State<EventDetailsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final EventService _eventService = EventService();
  List<MapController> mapControllers = [];
  bool isEventDeleted = false;

  @override
  Widget build(BuildContext context) {
    if (isEventDeleted) {
      return _buildLoadingIndicator(context);
    }
    return _buildEventStream(context);
  }

  Widget _buildEventStream(BuildContext context) {
    return StreamBuilder<EventModel>(
      stream: _eventService.getEventStreamById(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context);
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(context);
        }

        final event = snapshot.data!;
        final eventLocations = event.positions
            .map((pos) => LatLng(
                  pos?.latitude ?? 0.0,
                  pos?.longitude ?? 0.0,
                ))
            .toList();

        return Scaffold(
          appBar: _buildAppBar(context, event),
          backgroundColor: Theme.of(context).colorScheme.primary,
          body: _buildEventDetails(context, event, eventLocations),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, EventModel event) {
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
        AppLocalizations.of(context)!.event_details_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      actions: [
        _buildPopupMenu(context, event),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, EventModel event) {
    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.secondary,
      icon: Icon(
        MingCuteIcons.mgc_more_2_fill,
        color: Theme.of(context).colorScheme.secondary,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          Get.to(
            () => EventUpdaterScreen(eventId: event.id!),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 500),
          );
        } else if (value == 'delete') {
          _confirmDeleteEvent(context, event);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          _buildPopupMenuItem(
            context,
            'edit',
            MingCuteIcons.mgc_edit_2_fill,
            AppLocalizations.of(context)!.event_details_screen_menu_edit,
          ),
          _buildPopupMenuItem(
            context,
            'delete',
            MingCuteIcons.mgc_delete_3_fill,
            AppLocalizations.of(context)!.event_details_screen_menu_delete,
          ),
        ];
      },
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    BuildContext context,
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CustomLoader(
        width: 50.w,
        height: 50.h,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.event_details_screen_error_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.event_details_screen_empty_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEventDetails(
      BuildContext context, EventModel event, List<LatLng> eventLocations) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTitle(context, event),
            SizedBox(height: 10.h),
            _buildDate(context, event),
            SizedBox(height: 10.h),
            _buildCategory(context, event),
            SizedBox(height: 20.h),
            _buildImageCard(context, event),
            SizedBox(height: 20.h),
            _buildLocationCard(context, eventLocations, event),
            SizedBox(height: 30.h),
            _buildNoteCard(context, event),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, EventModel event) {
    return SizedBox(
      width: 280.w,
      child: Text(
        event.title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDate(BuildContext context, EventModel event) {
    if (event.endDate != null) {
      final formattedStartDate =
          DateFormat('dd/MM/yyyy').format(event.startDate);
      final formattedEndDate = DateFormat('dd/MM/yyyy').format(event.endDate!);
      return Text(
        '$formattedStartDate - $formattedEndDate',
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
        ),
      );
    } else {
      final formattedDate = DateFormat('dd/MM/yyyy').format(event.startDate);
      return Text(
        formattedDate,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
        ),
      );
    }
  }

  Widget _buildCategory(BuildContext context, EventModel event) {
    String translatedCategory =
        getTranslatedEventCategory(context, event.category);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        event.getIcon(color: Theme.of(context).colorScheme.tertiary),
        SizedBox(width: 10.w),
        Text(
          translatedCategory,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context, String imageUrl) {
    final double imageWidth = ScreenUtil().screenWidth > 600 ? 600.w : 300.w;
    final double imageHeight = ScreenUtil().screenWidth > 600 ? 400.h : 200.h;

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Center(child: _buildLoadingIndicator(context)),
        errorWidget: (context, url, error) => Icon(
          MingCuteIcons.mgc_close_fill,
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildImageCard(BuildContext context, EventModel event) {
    if (event.images == null || event.images!.isEmpty) {
      return _buildImage(context, 'assets/images/img_default.png');
    } else if (event.images!.length == 1) {
      return GestureDetector(
        onTap: () {
          Get.to(
            () => FullScreenImage(imageUrl: event.images!.first),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 500),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20.r)),
          child: _buildImage(context, event.images!.first),
        ),
      );
    } else {
      return _buildImagesSlider(context, event.images!);
    }
  }

  Widget _buildImagesSlider(BuildContext context, List<String> images) {
    final double imageHeight = ScreenUtil().screenWidth > 600 ? 400.h : 200.h;

    return CarouselSlider(
      options: CarouselOptions(
        height: imageHeight,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        autoPlay: false,
      ),
      items: images.map((image) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Get.to(
                  () => FullScreenImage(imageUrl: image),
                  transition: Transition.fadeIn,
                  duration: const Duration(milliseconds: 500),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20.r)),
                child: _buildImage(context, image),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildLocation(
    BuildContext context,
    LatLng location,
    EventModel event,
    MapController mapController,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(20.r)),
      child: SizedBox(
        width: 300.w,
        height: 200.h,
        child: FmMap(
          mapController: mapController,
          mapOptions: MapOptions(
            initialCenter: location,
            initialZoom: 10.r,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          markers: [
            Marker(
              point: location,
              child: Icon(
                MingCuteIcons.mgc_location_fill,
                color: AppColors.toastDarkRed,
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    List<LatLng> locations,
    EventModel event,
  ) {
    if (locations.length > 1) {
      return _buildLocationsSlider(context, locations, event);
    } else {
      return Column(
        children: locations.map((location) {
          final mapController = MapController();
          return _buildLocation(context, location, event, mapController);
        }).toList(),
      );
    }
  }

  Widget _buildLocationsSlider(
      BuildContext context, List<LatLng> locations, EventModel event) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.h,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        autoPlay: false,
      ),
      items: locations.map((location) {
        final mapController = MapController();
        return _buildLocation(context, location, event, mapController);
      }).toList(),
    );
  }

  Widget _buildNoteCard(BuildContext context, EventModel event) {
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomNote(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                event.note?.isNotEmpty == true
                    ? event.note!
                    : AppLocalizations.of(context)!.event_details_screen_note,
                style: GoogleFonts.josefinSans(
                  color: AppColors.charcoal,
                  fontSize: 16.sp,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Positioned(
            top: -12.r,
            right: 78.r,
            child: Icon(
              MingCuteIcons.mgc_attachment_2_fill,
              color: Theme.of(context).colorScheme.secondary,
              size: 20.sp,
            ),
          ),
          if (event.note?.isNotEmpty == true)
            Positioned(
              bottom: 0.r,
              right: 66.r,
              child: IconButton(
                icon: Icon(
                  MingCuteIcons.mgc_information_fill,
                  size: 20.sp,
                ),
                color: AppColors.charcoal,
                onPressed: () => _showFullTextDialog(context, event.note!),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullTextDialog(BuildContext context, String note) {
    final double noteHeight = ScreenUtil().screenWidth > 600 ? 320.h : 260.h;
    final double noteWidth = ScreenUtil().screenWidth > 600 ? 320.w : 260.w;
    final double containerHeight =
        ScreenUtil().screenWidth > 600 ? 300.h : 240.h;
    final double containerWidth =
        ScreenUtil().screenWidth > 600 ? 300.w : 240.w;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          alignment: Alignment.center,
          content: CustomNote(
            width: noteWidth,
            height: noteHeight,
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: containerWidth,
                    height: containerHeight,
                    padding: EdgeInsets.all(16.r),
                    child: Center(
                      child: Text(
                        note,
                        style: GoogleFonts.josefinSans(
                          color: AppColors.charcoal,
                          fontSize: 18.sp,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0.r,
                    left: 0.r,
                    right: 0.r,
                    child: IconButton(
                      icon: Icon(
                        MingCuteIcons.mgc_close_fill,
                        size: 20.sp,
                      ),
                      color: AppColors.charcoal,
                      onPressed: () => Get.back(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteEvent(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDeleteDialog(
          title: AppLocalizations.of(context)!
              .event_details_screen_delete_dialog_title,
          content: AppLocalizations.of(context)!
              .event_details_screen_delete_dialog_text,
          onCancelPressed: () {
            Get.back();
          },
          onConfirmPressed: () {
            _eventService.deleteEvent(event.id!);
            if (event.images != null && event.images!.isNotEmpty) {
              for (String imageUrl in event.images!) {
                final fileName = imageUrl.split('/').last;
                _eventService.deleteEventImageSupabase(
                    currentUser!.uid, event.id!, fileName);
              }
            }
            showSuccessToast(
              context,
              AppLocalizations.of(context)!
                  .event_details_screen_toast_success_delete,
            );
            setState(() {
              isEventDeleted = true;
            });
            Get.back();
            Get.back();
          },
        );
      },
    );
  }
}
