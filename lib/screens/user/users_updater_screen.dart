import 'dart:io';
import 'package:couplers/models/couple_model.dart';
import 'package:couplers/models/user_model.dart';
import 'package:couplers/screens/user/users_details_screen.dart';
import 'package:couplers/services/user_service.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class UsersUpdaterScreen extends StatefulWidget {
  final String userId;
  final bool isFirstTime;
  const UsersUpdaterScreen(
      {super.key, required this.userId, this.isFirstTime = false});

  @override
  UsersUpdaterScreenState createState() => UsersUpdaterScreenState();
}

class UsersUpdaterScreenState extends State<UsersUpdaterScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  late TabController tabController;
  final _picker = ImagePicker();
  final TextEditingController userName1Controller = TextEditingController();
  final TextEditingController userName2Controller = TextEditingController();
  String? userEmail1;
  String? userEmail2;
  File? userImage1;
  File? userImage2;
  String? _imageUrl1;
  String? _imageUrl2;
  DateTime? userBirthday1;
  DateTime? userBirthday2;
  String? userGender1;
  String? userGender2;
  DateTime? coupleDate;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: isLoading
            ? Center(child: _buildLoadingIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabBar(context, tabController),
                  _buildTabBarView(context, tabController),
                ],
              ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _requestPermissionAndPickImage(int userIndex) async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkVersion = androidInfo.version.sdkInt;

      // If SDK version is <= 32 (Android 12 or earlier)
      if (sdkVersion <= 32) {
        PermissionStatus filePermission = await Permission.storage.status;

        if (filePermission.isGranted) {
          _pickImage(userIndex);
        } else {
          filePermission = await Permission.storage.request();

          if (filePermission.isGranted) {
            _pickImage(userIndex);
          } else if (filePermission.isDenied) {
            if (mounted) {
              showErrorToast(
                context,
                AppLocalizations.of(context)!
                    .users_updater_screen_permission_error,
              );
            }
          } else if (filePermission.isPermanentlyDenied) {
            openAppSettings();
          }
        }
      }
      // If SDK version is >= 33 (Android 13+)
      else {
        PermissionStatus filePermission = await Permission.photos.status;

        if (filePermission.isGranted) {
          _pickImage(userIndex);
        } else {
          filePermission = await Permission.photos.request();

          if (filePermission.isGranted) {
            _pickImage(userIndex);
          } else if (filePermission.isDenied) {
            if (mounted) {
              showErrorToast(
                context,
                AppLocalizations.of(context)!
                    .users_updater_screen_permission_error,
              );
            }
          } else if (filePermission.isPermanentlyDenied) {
            openAppSettings();
          }
        }
      }
    }
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        isLoading = true;
      });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('couple')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        CoupleModel couple = CoupleModel.fromFirestore(data);

        setState(() {
          userName1Controller.text = couple.user1.name ?? '';
          userName2Controller.text = couple.user2.name ?? '';
          userEmail1 = couple.user1.email;
          userEmail2 = couple.user2.email;
          userBirthday1 = couple.user1.birthday;
          userBirthday2 = couple.user2.birthday;
          userGender1 = couple.user1.gender;
          userGender2 = couple.user2.gender;
          coupleDate = couple.coupleDate;

          _logger.d('Email 1: $userEmail1, Email 2: $userEmail2');
        });

        if (couple.user1.image != null) {
          final imageUrl1 = couple.user1.image!;
          final fileName1 = imageUrl1.split('/').last;
          _imageUrl1 =
              _userService.getUserImageUrlSupabase(widget.userId, fileName1);
          setState(() {
            userImage1 = File(_imageUrl1!);
          });
        }

        if (couple.user2.image != null) {
          final imageUrl2 = couple.user2.image!;
          final fileName2 = imageUrl2.split('/').last;
          _imageUrl2 =
              _userService.getUserImageUrlSupabase(widget.userId, fileName2);
          setState(() {
            userImage2 = File(_imageUrl2!);
          });
        }

        setState(() {
          isLoading = false;
        });
      } else {
        _logger.e("Document not found");
      }
    } catch (e) {
      _logger.e("Error during data loading: $e");
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocalizations.of(context)!
              .users_updater_screen_crop_image_title,
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
          title: AppLocalizations.of(context)!
              .users_updater_screen_crop_image_title,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _pickImage(int userIndex) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedImage = await _cropImage(File(pickedFile.path));

      if (croppedImage != null) {
        setState(() {
          if (widget.isFirstTime) {
            if (userIndex == 1) {
              userImage1 = croppedImage;
            } else {
              userImage2 = croppedImage;
            }
          } else {
            if (userIndex == 1) {
              if (_imageUrl1 != null) {
                final oldFileName1 = _imageUrl1!.split('/').last;
                _userService.deleteUserImageSupabase(
                    currentUser!.uid, oldFileName1);
              }
              userImage1 = croppedImage;
            } else {
              if (_imageUrl2 != null) {
                final oldFileName2 = _imageUrl2!.split('/').last;
                _userService.deleteUserImageSupabase(
                    currentUser!.uid, oldFileName2);
              }
              userImage2 = croppedImage;
            }
          }
        });
      } else {
        _logger.i("Cropping deleted, image not updated");
      }
    } else {
      _logger.i("Cropping deleted, image not updated");
    }
  }

  DateTime? _getUserBirthday(int userIndex) {
    if (userIndex == 1) {
      return userBirthday1;
    } else if (userIndex == 2) {
      return userBirthday2;
    }
    return null;
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      cancelText: AppLocalizations.of(context)!
          .users_updater_screen_date_field_cancel_text,
      confirmText: AppLocalizations.of(context)!
          .users_updater_screen_date_field_confirm_text,
      initialDate: coupleDate ?? DateTime.now(),
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

  Future<void> _saveData() async {
    if (userName1Controller.text.trim().isEmpty) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!
            .users_updater_screen_user1_name_field_error,
      );
      return;
    }

    if (userName2Controller.text.trim().isEmpty) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!
            .users_updater_screen_user2_name_field_error,
      );
      return;
    }

    if (coupleDate == null) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!
            .users_updater_screen_couple_date_field_error,
      );
      return;
    }

    try {
      String? imagePath1 = _imageUrl1;
      String? imagePath2 = _imageUrl2;

      if (userImage1 != null && userImage1!.path != imagePath1) {
        try {
          String newPath = await _userService.addUserImageSupabase(
              widget.userId, userImage1!);
          if (newPath != imagePath1) {
            imagePath1 = newPath;
          }
        } catch (e) {
          _logger.e("Error during update of userImage1: $e");
        }
      }

      if (userImage2 != null && userImage2!.path != imagePath2) {
        try {
          String newPath = await _userService.addUserImageSupabase(
              widget.userId, userImage2!);
          if (newPath != imagePath2) {
            imagePath2 = newPath;
          }
        } catch (e) {
          _logger.e("Error during update of userImage2: $e");
        }
      }

      CoupleModel couple = CoupleModel(
        user1: UserModel(
          email: userEmail1!,
          name: userName1Controller.text.trim(),
          image: imagePath1 ?? "",
          birthday: userBirthday1,
          gender: userGender1,
        ),
        user2: UserModel(
          email: userEmail2!,
          name: userName2Controller.text.trim(),
          image: imagePath2 ?? "",
          birthday: userBirthday2,
          gender: userGender2,
        ),
        coupleDate: coupleDate,
      );

      await FirebaseFirestore.instance
          .collection('couple')
          .doc(widget.userId)
          .update({
        'user1': couple.user1.toFirestore(),
        'user2': couple.user2.toFirestore(),
        'coupleDate':
            coupleDate != null ? Timestamp.fromDate(coupleDate!) : null,
        'isProfileCompleted': true,
      });

      Get.off(
        () => UsersDetailsScreen(userId: currentUser!.uid),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      _logger.e("Error during data saving: $e");
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
        AppLocalizations.of(context)!.users_updater_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      actions: [
        IconButton(
          icon: const Icon(MingCuteIcons.mgc_check_2_fill),
          onPressed: () {
            _saveData();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CustomLoader(
        width: 50.w,
        height: 50.h,
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, TabController tabController) {
    return TabBar(
      controller: tabController,
      indicatorColor: Theme.of(context).colorScheme.tertiary,
      indicatorWeight: 8.w,
      labelColor: Theme.of(context).colorScheme.tertiary,
      labelStyle: GoogleFonts.josefinSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelColor: Theme.of(context).colorScheme.secondary,
      unselectedLabelStyle: GoogleFonts.josefinSans(
        fontSize: 16.sp,
      ),
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                MingCuteIcons.mgc_user_heart_fill,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.users_updater_screen_user1_title,
              ),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                MingCuteIcons.mgc_user_heart_fill,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.users_updater_screen_user2_title,
              ),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                MingCuteIcons.mgc_user_heart_fill,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.users_updater_screen_date_title,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarView(
    BuildContext context,
    TabController tabController,
  ) {
    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          _buildRegistrationForm(context, 1),
          _buildRegistrationForm(context, 2),
          _buildDateForm(context),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context, int userIndex) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userIndex == 1)
              _buildUserForm(context, 1, userName1Controller)
            else
              _buildUserForm(context, 2, userName2Controller),
          ],
        ),
      ),
    );
  }

  Widget _buildDateForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCoupleDateSelector(context),
      ],
    );
  }

  Widget _buildUserForm(BuildContext context, int userIndex,
      TextEditingController userNameController) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryFixed,
      elevation: 0,
      margin: EdgeInsets.all(36.r),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            _buildUserImage(userIndex),
            _buildTextField(
              controller: userNameController,
              labelText: userIndex == 1
                  ? AppLocalizations.of(context)!
                      .users_updater_screen_user1_name_label
                  : AppLocalizations.of(context)!
                      .users_updater_screen_user2_name_label,
              hintText: userIndex == 1
                  ? AppLocalizations.of(context)!
                      .users_updater_screen_user1_name_hint
                  : AppLocalizations.of(context)!
                      .users_updater_screen_user2_name_hint,
            ),
            SizedBox(height: 20.h),
            _buildGenderSelector(context, userIndex),
            SizedBox(height: 20.h),
            _buildBirthdaySelector(context, userIndex),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildUserImage(int userIndex) {
    final userImage = userIndex == 1 ? userImage1 : userImage2;

    if (userImage == null || userImage.path.isEmpty) {
      return Stack(
        children: [
          ClipOval(
            child: Image.asset(
              "assets/images/user_image_default.png",
              width: 160.w,
              height: 160.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipOval(
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                child: IconButton(
                  icon: Icon(
                    MingCuteIcons.mgc_camera_2_fill,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _requestPermissionAndPickImage(userIndex),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (userImage.path.startsWith('http')) {
      return Stack(
        children: [
          ClipOval(
            child: Image.network(
              userImage.path,
              width: 160.w,
              height: 160.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  "assets/images/user_image_default.png",
                  width: 160.w,
                  height: 160.h,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipOval(
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                child: IconButton(
                  icon: Icon(
                    MingCuteIcons.mgc_edit_2_fill,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _requestPermissionAndPickImage(userIndex),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          ClipOval(
            child: Image.file(
              userImage,
              width: 160.w,
              height: 160.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  "assets/images/user_image_default.png",
                  width: 160.w,
                  height: 160.h,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipOval(
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                child: IconButton(
                  icon: Icon(
                    MingCuteIcons.mgc_edit_2_fill,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _requestPermissionAndPickImage(userIndex),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    FormFieldValidator<String>? validator,
  }) {
    final decoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
    );

    return SizedBox(
      width: 180.w,
      child: TextFormField(
        controller: controller,
        decoration: decoration,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        cursorColor: Theme.of(context).colorScheme.secondary,
        style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary),
        validator: validator,
      ),
    );
  }

  Widget _buildGenderSelector(BuildContext context, int userIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: (userIndex == 1 ? userGender1 : userGender2) ==
                  'Male'
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          child: IconButton(
            icon: Icon(
              MingCuteIcons.mgc_male_line,
              color: (userIndex == 1 ? userGender1 : userGender2) == 'Male'
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              setState(
                () {
                  if (userIndex == 1) {
                    userGender1 = 'Male';
                  } else if (userIndex == 2) {
                    userGender2 = 'Male';
                  }
                },
              );
            },
          ),
        ),
        SizedBox(width: 20.w),
        CircleAvatar(
          backgroundColor: (userIndex == 1 ? userGender1 : userGender2) ==
                  'Female'
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          child: IconButton(
            icon: Icon(
              MingCuteIcons.mgc_female_line,
              color: (userIndex == 1 ? userGender1 : userGender2) == 'Male'
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              setState(
                () {
                  if (userIndex == 1) {
                    userGender1 = 'Female';
                  } else if (userIndex == 2) {
                    userGender2 = 'Female';
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdaySelector(BuildContext context, int userIndex) {
    return Column(
      children: [
        SizedBox(
          width: 160.w,
          height: 60.h,
          child: MaterialButton(
            onPressed: () async {
              final DateTime? selectedBirthday = await _selectDate(context);
              if (selectedBirthday != null) {
                setState(() {
                  if (userIndex == 1) {
                    userBirthday1 = selectedBirthday;
                  } else if (userIndex == 2) {
                    userBirthday2 = selectedBirthday;
                  }
                });
              }
            },
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
            color: Theme.of(context).colorScheme.secondary,
            child: _getUserBirthday(userIndex) == null
                ? Icon(
                    MingCuteIcons.mgc_calendar_add_line,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26.sp,
                  )
                : Text(
                    DateFormat('dd/MM/yyyy')
                        .format(_getUserBirthday(userIndex)!),
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          _getUserBirthday(userIndex) == null
              ? AppLocalizations.of(context)!
                  .users_updater_screen_couple_date_select
              : AppLocalizations.of(context)!
                  .users_updater_screen_couple_date_update,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildCoupleDateSelector(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.users_updater_screen_couple_date_field,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 20.sp,
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: 160.w,
          height: 60.h,
          child: MaterialButton(
            onPressed: () async {
              final DateTime? selectedDate = await _selectDate(context);
              if (selectedDate != null) {
                setState(() {
                  coupleDate = selectedDate;
                });
              }
            },
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
            color: Theme.of(context).colorScheme.secondary,
            child: coupleDate == null
                ? Icon(
                    MingCuteIcons.mgc_calendar_add_line,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26.sp,
                  )
                : Text(
                    DateFormat('dd/MM/yyyy').format(coupleDate!),
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          coupleDate == null
              ? AppLocalizations.of(context)!
                  .users_updater_screen_couple_date_select
              : AppLocalizations.of(context)!
                  .users_updater_screen_couple_date_update,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }
}
