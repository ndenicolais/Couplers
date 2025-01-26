import 'dart:io';
import 'package:couplers/models/couple_model.dart';
import 'package:couplers/models/user_model.dart';
import 'package:couplers/screens/home_screen.dart';
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

class UserScreen extends StatefulWidget {
  final String userId;
  final bool isFirstTime;
  const UserScreen({super.key, required this.userId, this.isFirstTime = false});

  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  final Logger _logger = Logger();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final TextEditingController userName1Controller = TextEditingController();
  final TextEditingController userName2Controller = TextEditingController();
  String? userEmail1;
  String? userEmail2;
  File? userImage1;
  File? userImage2;
  String? _imageUrl1;
  String? _imageUrl2;
  DateTime? coupleDate;
  bool isProfileCompleted = false;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: isLoading
            ? Center(child: _buildLoadingIndicator(context))
            : Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.r),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isProfileCompleted)
                            _buildProfileView(context)
                          else
                            _buildRegistrationForm(context),
                        ],
                      ),
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
    _loadProfileData();
  }

  Future<void> _requestPermissionAndPickImage(int userNumber) async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkVersion = androidInfo.version.sdkInt;

      // If SDK version is <= 32 (Android 12 or earlier)
      if (sdkVersion <= 32) {
        PermissionStatus filePermission = await Permission.storage.status;

        if (filePermission.isGranted) {
          _pickImage(userNumber);
        } else {
          filePermission = await Permission.storage.request();

          if (filePermission.isGranted) {
            _pickImage(userNumber);
          } else if (filePermission.isDenied) {
            if (mounted) {
              showErrorToast(
                context,
                AppLocalizations.of(context)!.user_screen_permission_error,
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
          _pickImage(userNumber);
        } else {
          filePermission = await Permission.photos.request();

          if (filePermission.isGranted) {
            _pickImage(userNumber);
          } else if (filePermission.isDenied) {
            if (mounted) {
              showErrorToast(
                context,
                AppLocalizations.of(context)!.user_screen_permission_error,
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
          coupleDate = couple.coupleDate;
          userEmail1 = couple.user1.email;
          userEmail2 = couple.user2.email;

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
          isProfileCompleted = userName1Controller.text.isNotEmpty &&
              userName2Controller.text.isNotEmpty &&
              coupleDate != null;

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
          toolbarTitle:
              AppLocalizations.of(context)!.user_screen_crop_image_title,
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
          title: AppLocalizations.of(context)!.user_screen_crop_image_title,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _pickImage(int userNumber) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedImage = await _cropImage(File(pickedFile.path));

      if (croppedImage != null) {
        setState(() {
          if (widget.isFirstTime) {
            if (userNumber == 1) {
              userImage1 = croppedImage;
            } else {
              userImage2 = croppedImage;
            }
          } else {
            if (userNumber == 1) {
              final oldFileName1 = _imageUrl1!.split('/').last;
              _userService.deleteUserImageSupabase(
                  currentUser!.uid, oldFileName1);
              userImage1 = croppedImage;
            } else {
              final oldFileName2 = _imageUrl2!.split('/').last;
              _userService.deleteUserImageSupabase(
                  currentUser!.uid, oldFileName2);
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

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (userName1Controller.text.trim().isEmpty ||
        userName2Controller.text.trim().isEmpty ||
        coupleDate == null) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!.user_screen_save_error_date,
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
        ),
        user2: UserModel(
          email: userEmail2!,
          name: userName2Controller.text.trim(),
          image: imagePath2 ?? "",
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

      Get.offAll(
        () => const HomepageScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );

      setState(() {
        isProfileCompleted = true;
      });
    } catch (e) {
      _logger.e("Error during data saving: $e");
    }
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CustomLoader(
        width: 50.w,
        height: 50.h,
      ),
    );
  }

  Widget _buildProfileView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading)
          _buildLoadingIndicator(context)
        else ...[
          Text(
            userName1Controller.text,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userEmail1!,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 10.h),
          if (userImage1 != null)
            ClipOval(
              child: _buildImage(userImage1!.path),
            )
          else
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              radius: 50.r,
              child: Icon(
                MingCuteIcons.mgc_pic_fill,
                size: 30.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          SizedBox(height: 20.h),
          Text(
            userName2Controller.text,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userEmail2!,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 10.h),
          if (userImage2 != null)
            ClipOval(
              child: _buildImage(userImage2!.path),
            )
          else
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              radius: 50.r,
              child: Icon(
                MingCuteIcons.mgc_pic_fill,
                size: 30.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          SizedBox(height: 40.h),
          Text(
            AppLocalizations.of(context)!.user_screen_profile_date_text,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            coupleDate != null
                ? DateFormat('dd/MM/yyyy').format(coupleDate!)
                : AppLocalizations.of(context)!.user_screen_profile_date_empty,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 20.h),
          _buildEditButton(context),
        ],
      ],
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.user_screen_profile_couple_info,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 20.sp,
          ),
        ),
        SizedBox(height: 10.h),
        Stack(
          alignment: Alignment.center,
          children: [
            if (userImage1 == null)
              Stack(
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
                          onPressed: () => _requestPermissionAndPickImage(1),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (userImage1!.path.startsWith('http'))
              Stack(
                children: [
                  ClipOval(
                    child: Image.network(
                      userImage1!.path,
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
                          onPressed: () => _requestPermissionAndPickImage(1),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Stack(
                children: [
                  ClipOval(
                    child: Image.file(
                      userImage1!,
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
                          onPressed: () => _requestPermissionAndPickImage(1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 10.h),
        _buildTextField(
          controller: userName1Controller,
          labelText:
              AppLocalizations.of(context)!.user_screen_profile_user1_name,
          hintText: AppLocalizations.of(context)!
              .user_screen_profile_user1_name_field,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!
                  .user_screen_profile_user1_name_error;
            }
            return null;
          },
        ),
        SizedBox(height: 20.h),
        Stack(
          alignment: Alignment.center,
          children: [
            if (userImage2 == null)
              Stack(
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
                          onPressed: () => _requestPermissionAndPickImage(2),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (userImage2!.path.startsWith('http'))
              Stack(
                children: [
                  ClipOval(
                    child: Image.network(
                      userImage2!.path,
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
                          onPressed: () => _requestPermissionAndPickImage(2),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Stack(
                children: [
                  ClipOval(
                    child: Image.file(
                      userImage2!,
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
                          onPressed: () => _requestPermissionAndPickImage(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 10.h),
        _buildTextField(
          controller: userName2Controller,
          labelText:
              AppLocalizations.of(context)!.user_screen_profile_user2_name,
          hintText: AppLocalizations.of(context)!
              .user_screen_profile_user2_name_field,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!
                  .user_screen_profile_user2_name_error;
            }
            return null;
          },
        ),
        SizedBox(height: 40.h),
        _buildDateSelector(context),
        SizedBox(height: 40.h),
        _buildSaveButton(context),
        SizedBox(height: 20.h),
      ],
    );
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
        AppLocalizations.of(context)!.user_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildImage(String imagePath) {
    if (Uri.parse(imagePath).isAbsolute) {
      return Image.network(
        imagePath,
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
      );
    } else {
      return Image.file(
        File(imagePath),
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

    return TextFormField(
      controller: controller,
      decoration: decoration,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      cursorColor: Theme.of(context).colorScheme.secondary,
      style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary),
      validator: validator,
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Column(
      children: [
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
              ? AppLocalizations.of(context)!.user_screen_profile_date_select
              : AppLocalizations.of(context)!.user_screen_profile_date_update,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      elevation: 0,
      onPressed: _saveData,
      child: const Icon(MingCuteIcons.mgc_save_2_fill),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      elevation: 0,
      onPressed: () {
        setState(() {
          isProfileCompleted = false;
        });
      },
      child: const Icon(MingCuteIcons.mgc_edit_2_fill),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      cancelText: AppLocalizations.of(context)!.user_screen_date_cancel_text,
      confirmText: AppLocalizations.of(context)!.user_screen_date_confirm_text,
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
}
