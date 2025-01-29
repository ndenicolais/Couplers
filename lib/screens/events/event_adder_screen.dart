import 'dart:io';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/screens/events/event_list_screen.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/utils/event_type_translations.dart';
import 'package:couplers/widgets/custom_textfield.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
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
  bool isMultiDate = false;
  final _titleController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedDate;
  String typeName = '';
  final _typeController = TextEditingController();
  File? _imageFile;
  final List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  final List<TextEditingController> _locationControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  final List<LatLng?> eventPositions = [null, null, null];
  final List<MapController> mapControllers = [
    MapController(),
    MapController(),
    MapController()
  ];
  int currentLocationIndex = 0;
  LatLng? eventPosition;
  MapController mapController = MapController();
  int numSelectors = 1;
  final int maxSelectors = 3;
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
                  (val) => null,
                ),
                SizedBox(height: 20.h),
                _buildDateSwitch(),
                SizedBox(height: 20.h),
                _buildDateSelector(),
                SizedBox(height: 20.h),
                _buildTypeSelector(),
                SizedBox(height: 20.h),
                _buildImageSelector(),
                SizedBox(height: 20.h),
                _buildLocationSelector(),
                SizedBox(height: 20.h),
                _buildTextField(
                  _noteController,
                  AppLocalizations.of(context)!.event_adder_screen_form_notes,
                  AppLocalizations.of(context)!
                      .event_adder_screen_form_notees_field,
                  MingCuteIcons.mgc_edit_4_fill,
                  TextInputType.text,
                  TextCapitalization.none,
                  TextInputAction.done,
                  (val) => null,
                ),
                SizedBox(height: 20.h),
                _buildSaveButton(),
                SizedBox(height: 20.h),
              ],
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
    _imageFile = null;

    for (int i = 0; i < _locationControllers.length; i++) {
      _locationControllers[i].addListener(() {
        if (_locationControllers[i].text.isNotEmpty) {
          _searchPlace(_locationControllers[i].text, i);
        }
      });
    }
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

    if (pickedFile != null && currentUser != null) {
      File? croppedImage = await _cropImage(File(pickedFile.path));
      if (croppedImage != null) {
        setState(() {
          if (isMultiDate) {
            if (_imageFiles.length < 3) {
              _imageFiles.add(croppedImage);
            } else {
              showErrorToast(
                context,
                AppLocalizations.of(context)!.event_adder_screen_image_limit,
              );
            }
          } else {
            _imageFile = croppedImage;
          }
        });
      }
    } else {
      _logger.e("Error: user not logged in or no image selected");
    }
  }

  void _removeImage(File file) {
    setState(() {
      _imageFiles.remove(file);
    });
  }

  Future<void> _searchPlace(String location, int index) async {
    List<Location> locations = await locationFromAddress(location);

    if (locations.isNotEmpty) {
      setState(() {
        eventPositions[index] =
            LatLng(locations[0].latitude, locations[0].longitude);
      });

      mapControllers[index].move(eventPositions[index]!, 12.r);
    } else {
      if (mounted) {
        showErrorToast(context,
            AppLocalizations.of(context)!.event_adder_screen_toast_location);
      }
    }
  }

  void _removeLocation(int index) {
    _locationControllers.removeAt(index);
    mapControllers.removeAt(index);
    eventPositions.removeAt(index);
    numSelectors--;

    for (int i = 0; i < _locationControllers.length; i++) {
      _locationControllers[i].removeListener(() {});
      _locationControllers[i].addListener(() {
        if (_locationControllers[i].text.isNotEmpty) {
          _searchPlace(_locationControllers[i].text, i);
        }
      });
    }
  }

  void _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      showErrorToast(context,
          AppLocalizations.of(context)!.event_adder_screen_toast_error_title);
      return;
    }

    if (!isMultiDate) {
      if (_selectedDate == null) {
        showErrorToast(context,
            AppLocalizations.of(context)!.event_adder_screen_toast_error_date);
        return;
      }
    } else {
      if (_selectedStartDate == null) {
        showErrorToast(
            context,
            AppLocalizations.of(context)!
                .event_adder_screen_toast_error_date_started);
        return;
      }
      if (_selectedEndDate == null) {
        showErrorToast(
            context,
            AppLocalizations.of(context)!
                .event_adder_screen_toast_error_date_ended);
        return;
      }
      if (_selectedStartDate!.isAfter(_selectedEndDate!)) {
        showErrorToast(
            context,
            AppLocalizations.of(context)!
                .event_adder_screen_toast_error_date_error);
        return;
      }
    }

    if (typeName.isEmpty) {
      showErrorToast(context,
          AppLocalizations.of(context)!.event_adder_screen_toast_error_type);
      return;
    }

    if (eventPositions.every((position) => position == null)) {
      showErrorToast(
          context,
          AppLocalizations.of(context)!
              .event_adder_screen_toast_error_location);
      return;
    }

    List<String> finalImages = [];
    const defaultImage = 'assets/images/img_default.png';

    final newEvent = EventModel(
      id: '',
      title: _titleController.text.trim(),
      startDate: isMultiDate ? _selectedStartDate! : _selectedDate!,
      endDate: isMultiDate ? _selectedEndDate : null,
      type: typeName,
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
        showErrorToast(context,
            '${AppLocalizations.of(context)!.event_adder_screen_toast_error} $e');
      }
      return;
    }

    if (!isMultiDate && _imageFile != null) {
      final path = await _eventService.addEventImageSupabase(
          currentUser!.uid, eventId, _imageFile!);
      final fileName = path.split('/').last;
      final imageUrl = _eventService.getEventImageUrlSupabase(
          currentUser!.uid, eventId, fileName);

      setState(() {
        finalImages.add(imageUrl);
      });
    } else if (isMultiDate) {
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
      type: typeName,
      images: finalImages,
      locations: finalLocations,
      positions: finalPositions,
      note: _noteController.text.trim(),
    );

    await _eventService.updateEvent(updatedEvent);

    if (mounted) {
      showSuccessToast(context,
          AppLocalizations.of(context)!.event_adder_screen_toast_success);
      Get.off(
        () => const EventListScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );
    }
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
      validator: validator,
    );
  }

  Widget _buildDateSwitch() {
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

  Widget _buildDateSelector() {
    return Column(
      children: [
        if (!isMultiDate) ...[
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
          SizedBox(height: 10.h),
          Text(
            AppLocalizations.of(context)!.event_adder_screen_date_title,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16.sp,
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
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
                  SizedBox(height: 10.h),
                  Text(
                    AppLocalizations.of(context)!
                        .event_adder_screen_date_started,
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
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
                  SizedBox(height: 10.h),
                  Text(
                    AppLocalizations.of(context)!.event_adder_screen_date_ended,
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16.sp,
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

  Widget _buildTypeSelector() {
    return SizedBox(
      width: 200.w,
      child: DropdownButtonFormField<String>(
        value: typeName.isNotEmpty ? typeName : null,
        dropdownColor: Theme.of(context).colorScheme.secondary,
        hint: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 6.r),
            child: Text(
              AppLocalizations.of(context)!.event_adder_screen_type_title,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            typeName = value!;
            _typeController.text = typeName;
          });
        },
        icon: Icon(
          MingCuteIcons.mgc_down_line,
          color: Theme.of(context).colorScheme.secondary,
          size: 30.sp,
        ),
        items: EventModel.typeIconMap.keys.map((typeName) {
          IconData icon = EventModel.typeIconMap[typeName] ??
              MingCuteIcons.mgc_question_fill;
          String translatedType = getTranslatedEventType(context, typeName);

          return DropdownMenuItem<String>(
            value: typeName,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 10.w),
                Text(
                  translatedType,
                  style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16.sp),
                ),
              ],
            ),
          );
        }).toList(),
        decoration: InputDecoration(
          prefixIcon: typeName.isEmpty
              ? Icon(
                  MingCuteIcons.mgc_list_expansion_fill,
                  color: Theme.of(context).colorScheme.secondary,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        selectedItemBuilder: (BuildContext context) {
          return EventModel.typeIconMap.keys.map((typeName) {
            String translatedType = getTranslatedEventType(context, typeName);
            return Row(
              children: [
                Icon(
                  EventModel.typeIconMap[typeName] ??
                      MingCuteIcons.mgc_question_fill,
                  size: 20.sp,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 10.w),
                Text(
                  translatedType,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      children: [
        if (!isMultiDate && _imageFile == null)
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                MingCuteIcons.mgc_pic_fill,
                color: Theme.of(context).colorScheme.primary,
                size: 50.sp,
              ),
              onPressed: () => _pickImage(),
            ),
          ),
        if (!isMultiDate && _imageFile != null)
          GestureDetector(
            onTap: () => _pickImage(),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Image.file(
                _imageFile!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (isMultiDate)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._imageFiles.map((file) => Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: Image.file(
                            file,
                            width: 100.h,
                            height: 100.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Icon(
                            MingCuteIcons.mgc_fault_fill,
                            size: 30.sp,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          onPressed: () => _removeImage(file),
                        ),
                      ),
                    ],
                  )),
              if (_imageFiles.length < 3)
                Container(
                  width: 100.h,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
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
        SizedBox(height: 10.h),
        Text(
          (_imageFile != null || _imageFiles.isNotEmpty)
              ? AppLocalizations.of(context)!.event_adder_screen_image_update
              : AppLocalizations.of(context)!.event_adder_screen_image_select,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      children: [
        if (!isMultiDate)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _locationControllers[0],
                      AppLocalizations.of(context)!
                          .event_adder_screen_location_title,
                      AppLocalizations.of(context)!
                          .event_adder_screen_location_text,
                      MingCuteIcons.mgc_search_2_fill,
                      TextInputType.text,
                      TextCapitalization.sentences,
                      TextInputAction.done,
                      (val) => null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20.r)),
                child: SizedBox(
                  height: 150.h,
                  child: FlutterMap(
                    mapController: mapControllers[0],
                    options: MapOptions(
                      initialCenter: eventPositions[0] ??
                          const LatLng(41.9099533, 12.371192),
                      initialZoom: 6.r,
                      interactionOptions:
                          const InteractionOptions(flags: InteractiveFlag.none),
                      onTap: (tapPosition, LatLng position) {
                        setState(() {
                          eventPositions[0] = position;
                        });
                        mapControllers[0].move(position, 10.r);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: eventPositions[0] != null
                            ? [
                                Marker(
                                  width: 40.w,
                                  height: 40.h,
                                  point: eventPositions[0]!,
                                  child: Icon(
                                    MingCuteIcons.mgc_location_fill,
                                    color: AppColors.darkBrick,
                                    size: 30.sp,
                                  ),
                                ),
                              ]
                            : [],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: List.generate(
              numSelectors,
              (index) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _locationControllers[index],
                          AppLocalizations.of(context)!
                              .event_adder_screen_location_title,
                          AppLocalizations.of(context)!
                              .event_adder_screen_location_text,
                          MingCuteIcons.mgc_search_2_fill,
                          TextInputType.text,
                          TextCapitalization.sentences,
                          TextInputAction.done,
                          (val) => null,
                        ),
                      ),
                      if (numSelectors > 1)
                        IconButton(
                          icon: Icon(
                            MingCuteIcons.mgc_fault_fill,
                            size: 40.sp,
                            color: AppColors.darkBrick,
                          ),
                          onPressed: () {
                            if (numSelectors > 1) {
                              setState(() {
                                _removeLocation(index);
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Card(
                    margin: EdgeInsets.all(6.r),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: SizedBox(
                      height: 100.h,
                      child: FlutterMap(
                        mapController: mapControllers[index],
                        options: MapOptions(
                          initialCenter: eventPositions[index] ??
                              const LatLng(41.9099533, 12.371192),
                          initialZoom: 6.r,
                          interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none),
                          onTap: (tapPosition, LatLng position) {
                            setState(() {
                              eventPositions[index] = position;
                            });
                            mapControllers[index].move(position, 10.r);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: eventPositions[index] != null
                                ? [
                                    Marker(
                                      width: 40.w,
                                      height: 40.h,
                                      point: eventPositions[index]!,
                                      child: Icon(
                                        MingCuteIcons.mgc_location_fill,
                                        color: AppColors.darkBrick,
                                        size: 30.sp,
                                      ),
                                    ),
                                  ]
                                : [],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isMultiDate && numSelectors < maxSelectors)
          GestureDetector(
            onTap: () {
              setState(() {
                if (numSelectors < maxSelectors) {
                  var newController = TextEditingController();
                  var newIndex = _locationControllers.length;
                  newController.addListener(() {
                    if (newController.text.isNotEmpty) {
                      _searchPlace(newController.text, newIndex);
                    }
                  });
                  _locationControllers.add(newController);
                  mapControllers.add(MapController());
                  eventPositions.add(null);
                  numSelectors++;
                }
              });
            },
            child: Container(
              width: 130,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                MingCuteIcons.mgc_add_fill,
                color: Theme.of(context).colorScheme.primary,
                size: 25,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: 70.w,
      height: 70.h,
      child: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: _saveEvent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(
          MingCuteIcons.mgc_save_2_fill,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
