import 'dart:io';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/utils/event_category_translations.dart';
import 'package:couplers/widgets/full_screen_map.dart';
import 'package:couplers/widgets/custom_textfield.dart';
import 'package:couplers/widgets/custom_toast.dart';
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

class EventAdderScreen extends StatefulWidget {
  const EventAdderScreen({super.key});

  @override
  EventAdderScreenState createState() => EventAdderScreenState();
}

class EventAdderScreenState extends State<EventAdderScreen> {
  final Logger _logger = Logger();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final EventService _eventService;
  final _formKey = GlobalKey<FormState>();
  bool isMultiDate = false;
  final _titleController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedDate;
  String category = '';
  final _categoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _imageFiles = [];
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.r),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(
                    _titleController,
                    AppLocalizations.of(context)!.event_adder_screen_form_title,
                    AppLocalizations.of(context)!
                        .event_adder_screen_form_title_field,
                    MingCuteIcons.mgc_text_2_fill,
                    TextInputType.text,
                    TextCapitalization.sentences,
                    TextInputAction.done,
                    null,
                    (val) => val!.isEmpty
                        ? AppLocalizations.of(context)!
                            .event_adder_screen_toast_error_title
                        : null,
                  ),
                  SizedBox(height: 20.h),
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
                    AppLocalizations.of(context)!.event_adder_screen_form_notes,
                    AppLocalizations.of(context)!
                        .event_adder_screen_form_notes_field,
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
  }

  Color getEventColorWithAlpha(String category) {
    return EventModel.categoryColorMap[category]!;
  }

  Future<DateTime?> _selectDate(BuildContext context,
      {DateTime? initialDate}) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      cancelText:
          AppLocalizations.of(context)!.event_adder_screen_date_cancel_text,
      confirmText:
          AppLocalizations.of(context)!.event_adder_screen_date_confirm_text,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1990),
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
              AppLocalizations.of(context)!.event_adder_screen_image_crop,
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
          title: AppLocalizations.of(context)!.event_adder_screen_image_crop,
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedImage = await _cropImage(File(pickedFile.path));
      if (croppedImage != null) {
        setState(() {
          _imageFiles.add(croppedImage);
        });
      }
    } else {
      _logger.e("Error: no image selected");
    }
  }

  void _removeImage(File file) {
    setState(() {
      _imageFiles.remove(file);
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
    setState(() {
      if (index >= 0 && index < maxSelectors) {
        eventPositions[index] = position;
        _locationControllers[index].text = address;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mapControllers[index].move(position, 6.r);
        });
      }
    });
  }

  void _removeLocation(int index) {
    setState(() {
      eventPositions[index] = null;
    });
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (!isMultiDate) {
        if (_selectedDate == null) {
          showErrorToast(
            context,
            AppLocalizations.of(context)!.event_adder_screen_toast_error_date,
          );
          return;
        }
      } else {
        if (_selectedStartDate == null) {
          showErrorToast(
            context,
            AppLocalizations.of(context)!
                .event_adder_screen_toast_error_date_started,
          );
          return;
        }
        if (_selectedEndDate == null) {
          showErrorToast(
            context,
            AppLocalizations.of(context)!
                .event_adder_screen_toast_error_date_ended,
          );
          return;
        }
        if (_selectedStartDate!.isAfter(_selectedEndDate!)) {
          showErrorToast(
            context,
            AppLocalizations.of(context)!
                .event_adder_screen_toast_error_date_error,
          );
          return;
        }
      }

      if (category.isEmpty) {
        showErrorToast(
          context,
          AppLocalizations.of(context)!.event_adder_screen_toast_error_category,
        );
        return;
      }

      final newEvent = EventModel(
        id: '',
        title: _titleController.text.trim(),
        startDate: isMultiDate ? _selectedStartDate! : _selectedDate!,
        endDate: isMultiDate ? _selectedEndDate : null,
        category: category,
        images: finalImages,
        locations: [],
        positions: [],
        note: _noteController.text.trim(),
      );

      String eventId;
      try {
        eventId = await _eventService.addEvent(newEvent);
      } catch (e) {
        if (mounted) {
          showErrorToast(
            context,
            '${AppLocalizations.of(context)!.event_adder_screen_toast_error} $e',
          );
        }
        return;
      }

      if (_imageFiles.isNotEmpty) {
        for (File image in _imageFiles) {
          final path = await _eventService.addEventImageSupabase(
              currentUser!.uid, eventId, image);
          final fileName = path.split('/').last;
          final imageUrl = _eventService.getEventImageUrlSupabase(
              currentUser!.uid, eventId, fileName);

          setState(() {
            finalImages.add(imageUrl);
          });
        }
      }

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

      final updatedEvent = EventModel(
        id: eventId,
        title: _titleController.text.trim(),
        startDate: isMultiDate ? _selectedStartDate! : _selectedDate!,
        endDate: isMultiDate ? _selectedEndDate : null,
        category: category,
        images: finalImages,
        locations: finalLocations,
        positions: finalPositions,
        note: _noteController.text.trim(),
      );

      await _eventService.updateEvent(updatedEvent);

      if (mounted) {
        showSuccessToast(
          context,
          AppLocalizations.of(context)!.event_adder_screen_toast_success,
        );
        Get.back();
      }
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
        AppLocalizations.of(context)!.event_adder_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
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
          AppLocalizations.of(context)!.event_adder_screen_multiple_text,
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
            AppLocalizations.of(context)!.event_adder_screen_date_title,
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
                      MingCuteIcons.mgc_calendar_add_fill,
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
                        .event_adder_screen_date_started,
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
                              MingCuteIcons.mgc_calendar_add_fill,
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
                    AppLocalizations.of(context)!.event_adder_screen_date_ended,
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
                              MingCuteIcons.mgc_calendar_add_fill,
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
          AppLocalizations.of(context)!.event_adder_screen_category_title,
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
                      this.category = category;
                      _categoryController.text = category;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.r),
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: this.category == category
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
          AppLocalizations.of(context)!.event_adder_screen_image_select,
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
            ..._imageFiles.map(
              (file) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Image.file(
                      file,
                      width: 100.h,
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
                      onPressed: () => _removeImage(file),
                    ),
                  ),
                ],
              ),
            ),
            for (int i = _imageFiles.length; i < maxSelectors; i++)
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
          AppLocalizations.of(context)!.event_adder_screen_location_text,
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
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: SizedBox(
                      width: 100.h,
                      height: 100.h,
                      child: FmMap(
                        mapController: mapControllers[index],
                        mapOptions: MapOptions(
                          initialZoom: 6.r,
                          interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none),
                          initialCenter: eventPositions[index]!,
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
      onPressed: _saveEvent,
      child: const Icon(
        MingCuteIcons.mgc_check_fill,
      ),
    );
  }
}
