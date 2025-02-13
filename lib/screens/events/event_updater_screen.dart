import 'dart:io';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/utils/event_category_translations.dart';
import 'package:couplers/utils/permission_helper.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_textfield.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:couplers/widgets/full_screen_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_map/free_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

class EventUpdaterScreen extends StatefulWidget {
  final String eventId;

  const EventUpdaterScreen({super.key, required this.eventId});

  @override
  EventUpdaterScreenState createState() => EventUpdaterScreenState();
}

class EventUpdaterScreenState extends State<EventUpdaterScreen> {
  final Logger _logger = Logger();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final EventService _eventService = EventService();
  final _formKey = GlobalKey<FormState>();
  late EventModel event;
  bool isInitialLoading = true;
  bool isMultiDate = false;
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedDate;
  final TextEditingController _categoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _existingImages = [];
  final List<String> _removedExistingImages = [];
  final List<File> _newImages = [];
  List<String> finalImages = [];
  final List<TextEditingController> _locationControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  static const int maxSelectors = 3;
  List<LatLng?> eventPositions = List.generate(maxSelectors, (_) => null);
  List<MapController> mapControllers =
      List.generate(maxSelectors, (_) => MapController());
  int currentLocationIndex = 0;
  final _noteController = TextEditingController();
  bool isSaveLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return Center(
        child: _buildLoadingIndicator(context),
      );
    }
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.r),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(
                        _titleController,
                        AppLocalizations.of(context)!
                            .event_updater_screen_form_title,
                        AppLocalizations.of(context)!
                            .event_updater_screen_form_title_field,
                        MingCuteIcons.mgc_text_2_fill,
                        TextInputType.text,
                        TextCapitalization.sentences,
                        TextInputAction.done,
                        null,
                        (val) => val!.isEmpty
                            ? AppLocalizations.of(context)!
                                .event_updater_screen_toast_error_title
                            : null,
                      ),
                      _buildDateSwitch(context),
                      SizedBox(height: 20.h),
                      _buildDateSelector(context),
                      SizedBox(height: 20.h),
                      _buildCategorySelector(context),
                      SizedBox(height: 20.h),
                      _buildImageSelector(context),
                      SizedBox(height: 20.h),
                      _buildLocationSelector(context),
                      SizedBox(height: 20.h),
                      _buildTextField(
                        _noteController,
                        AppLocalizations.of(context)!
                            .event_updater_screen_form_notes,
                        AppLocalizations.of(context)!
                            .event_updater_screen_form_notees_field,
                        MingCuteIcons.mgc_edit_4_fill,
                        TextInputType.text,
                        TextCapitalization.none,
                        TextInputAction.done,
                        180,
                        (val) => null,
                      ),
                      SizedBox(height: 20.h),
                      _buildSaveButton(context),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
            if (isSaveLoading)
              Container(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.7),
                child: Center(
                  child: _buildLoadingIndicator(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Color getEventColorWithAlpha(String category) {
    return EventModel.categoryColorMap[category]!;
  }

  void _loadEvent() async {
    event = await _eventService.getEventById(widget.eventId);
    _titleController.text = event.title;
    _selectedDate = event.startDate;
    _selectedStartDate = event.startDate;
    _selectedEndDate = event.endDate;
    _categoryController.text = event.category;
    _existingImages.addAll(event.images ?? []);
    _noteController.text = event.note ?? '';

    for (int i = 0; i < event.locations.length; i++) {
      _locationControllers[i].text = event.locations[i];
    }

    eventPositions = List<LatLng?>.filled(maxSelectors, null, growable: false);
    for (int i = 0; i < event.positions.length; i++) {
      eventPositions[i] = event.positions[i];
    }

    isMultiDate = event.endDate != null;
    setState(() {
      isInitialLoading = false;
    });
  }

  Future<DateTime?> _selectDate(BuildContext context,
      {DateTime? initialDate}) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      cancelText:
          AppLocalizations.of(context)!.event_updater_screen_date_cancel_text,
      confirmText:
          AppLocalizations.of(context)!.event_updater_screen_date_confirm_text,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: themeNotifier.currentTheme,
          child: child!,
        );
      },
    );
    return picked;
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle:
              AppLocalizations.of(context)!.event_updater_screen_image_crop,
          toolbarColor: Theme.of(context).colorScheme.secondary,
          statusBarColor: Theme.of(context).colorScheme.secondary,
          toolbarWidgetColor: Theme.of(context).colorScheme.primary,
          activeControlsWidgetColor: Theme.of(context).colorScheme.secondary,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: AppLocalizations.of(context)!.event_updater_screen_image_crop,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _pickImage() async {
    await requestStoragePermission(context, () async {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File? croppedImage = await _cropImage(File(pickedFile.path));
        if (croppedImage != null) {
          setState(() {
            _newImages.add(croppedImage);
          });
        }
      } else {
        _logger.e("Error: no image selected");
      }
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedExistingImages.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _openFullScreenMap(int index) {
    Get.to(
      () => FullScreenMap(
        onPositionConfirmed: (position, address) =>
            _updateConfirmedPosition(index, position, address),
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _updateConfirmedPosition(int index, LatLng position, String address) {
    if (mounted) {
      setState(() {
        if (index >= 0 && index < maxSelectors) {
          eventPositions[index] = position;
          _locationControllers[index].text = address;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              mapControllers[index].move(position, 6.r);
            }
          });
        }
      });
    }
  }

  void _removeLocation(int index) {
    if (mounted) {
      setState(() {
        eventPositions[index] = null;
        _locationControllers[index].clear();
      });
    }
  }

  void _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      Map<int, String?> finalImagesMap = {};

      for (int i = 0; i < _newImages.length; i++) {
        final path = await _eventService.addEventImageSupabase(
            currentUser!.uid, event.id!, _newImages[i]);
        final fileName = path.split('/').last;
        final imageUrl = _eventService.getEventImageUrlSupabase(
            currentUser!.uid, event.id!, fileName);
        finalImagesMap[_existingImages.length + i] = imageUrl;
      }

      for (int i = 0; i < _existingImages.length; i++) {
        if (!_removedExistingImages.contains(_existingImages[i])) {
          finalImagesMap[i] = _existingImages[i];
        }
      }

      finalImages = List<String>.filled(finalImagesMap.length, '');
      finalImagesMap.forEach((index, imageUrl) {
        finalImages[index] = imageUrl!;
      });

      const defaultImage = 'assets/images/img_default.png';
      if (finalImages.isEmpty) {
        finalImages.add(defaultImage);
      }

      List<String> finalLocations = [];
      List<LatLng?> finalPositions = [];
      for (int i = 0; i < _locationControllers.length; i++) {
        if (_locationControllers[i].text.trim().isNotEmpty &&
            eventPositions[i] != null) {
          finalLocations.add(_locationControllers[i].text.trim());
          finalPositions.add(eventPositions[i]);
        }
      }

      setState(() {
        isSaveLoading = true;
      });

      final updatedEvent = EventModel(
        id: event.id,
        title: _titleController.text.trim(),
        startDate: isMultiDate ? _selectedStartDate! : _selectedDate!,
        endDate: isMultiDate ? _selectedEndDate : null,
        category: _categoryController.text,
        images: finalImages,
        locations: finalLocations,
        positions: finalPositions,
        note: _noteController.text.trim(),
        isFavorite: event.isFavorite,
      );

      await _eventService.updateEvent(updatedEvent);

      if (_removedExistingImages.isNotEmpty) {
        _logger.i(
            "_removedExistingImages is not empty, proceeding to delete images");
        for (String existingImage in _removedExistingImages) {
          final existingFileName = existingImage.split('/').last;
          try {
            await _eventService.deleteEventImageSupabase(
                currentUser!.uid, event.id!, existingFileName);
            _logger.i("Deleted existing image: $existingFileName");
          } catch (e) {
            _logger.e(
                "Failed to delete existing image: $existingFileName, error: $e");
          }
        }
      } else {
        _logger.i("_removedExistingImages is empty, nothing to delete");
      }

      if (mounted) {
        showSuccessToast(
          context,
          AppLocalizations.of(context)!.event_updater_screen_toast_success,
        );
        Get.back();
      }

      setState(() {
        isSaveLoading = false;
      });
    }
  }

  AppBar _buildAppBar(BuildContext context) {
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
        AppLocalizations.of(context)!.event_updater_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData prefixIcon,
    TextInputType keyboardType,
    TextCapitalization textCapitalization,
    TextInputAction textInputAction,
    int? maxLength,
    String? Function(String?) validator,
  ) {
    return CustomTextField(
      controller: controller,
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      validator: validator,
    );
  }

  Widget _buildDateSwitch(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.event_updater_screen_multiple_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Switch(
          value: isMultiDate,
          onChanged: (value) {
            setState(() {
              isMultiDate = value;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: Theme.of(context).colorScheme.tertiary,
          inactiveThumbColor: Theme.of(context).colorScheme.secondary,
          inactiveTrackColor: Theme.of(context).colorScheme.tertiaryFixed,
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Column(
      children: [
        if (!isMultiDate) ...[
          Text(
            AppLocalizations.of(context)!.event_updater_screen_date_title,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: 160.w,
            height: 60.h,
            child: MaterialButton(
              onPressed: () async {
                final DateTime? selectedDate =
                    await _selectDate(context, initialDate: _selectedDate);
                if (selectedDate != null) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              color: Theme.of(context).colorScheme.secondary,
              child: _selectedDate == null
                  ? Icon(
                      MingCuteIcons.mgc_calendar_add_line,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .event_updater_screen_date_started,
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: 160.w,
                    height: 60.h,
                    child: MaterialButton(
                      onPressed: () async {
                        final DateTime? selectedStartDate = await _selectDate(
                            context,
                            initialDate: _selectedStartDate);
                        if (selectedStartDate != null) {
                          setState(() {
                            _selectedStartDate = selectedStartDate;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      color: Theme.of(context).colorScheme.secondary,
                      child: _selectedStartDate == null
                          ? Icon(
                              MingCuteIcons.mgc_calendar_add_line,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(_selectedStartDate!),
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .event_updater_screen_date_ended,
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: 160.w,
                    height: 60.h,
                    child: MaterialButton(
                      onPressed: () async {
                        final DateTime? selectedEndDate = await _selectDate(
                            context,
                            initialDate:
                                _selectedEndDate ?? _selectedStartDate);
                        if (selectedEndDate != null) {
                          setState(() {
                            _selectedEndDate = selectedEndDate;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      color: Theme.of(context).colorScheme.secondary,
                      child: _selectedEndDate == null
                          ? Icon(
                              MingCuteIcons.mgc_calendar_add_line,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(_selectedEndDate!),
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.event_updater_screen_category_title,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
          maxLines: 2,
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 60.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: EventModel.categoryIconMap.keys.map((category) {
                IconData icon = EventModel.categoryIconMap[category] ??
                    MingCuteIcons.mgc_question_fill;
                String translatedCategory =
                    getTranslatedEventCategory(context, category);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      event.category = category;
                      _categoryController.text = category;
                    });
                  },
                  child: Container(
                    width: 120.w,
                    padding: EdgeInsets.symmetric(horizontal: 14.r),
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: event.category == category
                          ? Theme.of(context).colorScheme.tertiary
                          : getEventColorWithAlpha(category),
                      borderRadius: BorderRadius.all(Radius.circular(10.r)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 20.sp,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          translatedCategory,
                          style: GoogleFonts.josefinSans(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.event_updater_screen_image_select,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
          maxLines: 2,
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ..._existingImages.map((imageUrl) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl.startsWith('assets/')
                          ? Image.asset(
                              imageUrl,
                              width: 100.w,
                              height: 100.h,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageUrl,
                              width: 100.w,
                              height: 100.h,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: Icon(
                          MingCuteIcons.mgc_close_fill,
                          size: 30.sp,
                          color: AppColors.toastDarkRed,
                        ),
                        onPressed: () {
                          int index = _existingImages.indexOf(imageUrl);
                          _removeExistingImage(index);
                        },
                      ),
                    ),
                  ],
                )),
            ..._newImages.map(
              (file) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Image.file(
                      file,
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: Icon(
                        MingCuteIcons.mgc_close_fill,
                        size: 30.sp,
                        color: AppColors.toastDarkRed,
                      ),
                      onPressed: () {
                        int index = _newImages.indexOf(file);
                        _removeNewImage(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
            for (int i = _existingImages.length + _newImages.length; i < 3; i++)
              Container(
                width: 100.h,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.all(Radius.circular(10.r)),
                ),
                child: IconButton(
                  icon: Icon(
                    MingCuteIcons.mgc_add_fill,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40.sp,
                  ),
                  onPressed: () => _pickImage(),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSelector(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.event_updater_screen_location_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
          maxLines: 2,
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            maxSelectors,
            (index) => Stack(
              children: [
                if (eventPositions[index] != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: SizedBox(
                      width: 100.h,
                      height: 100.h,
                      child: FmMap(
                        mapController: mapControllers[index],
                        mapOptions: MapOptions(
                          initialCenter: eventPositions[index]!,
                          initialZoom: 6.r,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        markers: [
                          Marker(
                            point: eventPositions[index]!,
                            child: Icon(
                              MingCuteIcons.mgc_location_fill,
                              color: AppColors.toastDarkRed,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    icon: Icon(
                      MingCuteIcons.mgc_close_fill,
                      size: 30.sp,
                      color: AppColors.toastDarkRed,
                    ),
                    onPressed: () {
                      _removeLocation(index);
                    },
                  ),
                ),
                if (eventPositions[index] == null)
                  Container(
                    width: 100.h,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.all(Radius.circular(10.r)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        MingCuteIcons.mgc_add_fill,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40.sp,
                      ),
                      onPressed: () => _openFullScreenMap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: Theme.of(context).colorScheme.tertiaryFixed,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      elevation: 0,
      onPressed: _updateEvent,
      child: const Icon(
        MingCuteIcons.mgc_check_fill,
      ),
    );
  }
}
