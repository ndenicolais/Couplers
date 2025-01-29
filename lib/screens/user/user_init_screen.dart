import 'package:couplers/models/couple_model.dart';
import 'package:couplers/models/user_model.dart';
import 'package:couplers/screens/home_screen.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

class UserInitScreen extends StatefulWidget {
  final String userId;
  final bool isFirstTime;
  const UserInitScreen(
      {super.key, required this.userId, this.isFirstTime = false});

  @override
  UserInitScreenState createState() => UserInitScreenState();
}

class UserInitScreenState extends State<UserInitScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController userName1Controller = TextEditingController();
  final TextEditingController userName2Controller = TextEditingController();
  String? userEmail1;
  String? userEmail2;
  DateTime? coupleDate;
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
                        children: [_buildRegistrationForm(context)],
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
          coupleDate = couple.coupleDate;

          _logger.d('Email 1: $userEmail1, Email 2: $userEmail2');
        });

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

  Future<DateTime?> _selectDate(BuildContext context) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      cancelText: AppLocalizations.of(context)!
          .user_init_screen_couple_date_field_cancel_text,
      confirmText: AppLocalizations.of(context)!
          .user_init_screen_couple_date_field_confirm_text,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (userName1Controller.text.trim().isEmpty) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!.user_init_screen_user1_name_field_error,
      );
      return;
    }

    if (userName2Controller.text.trim().isEmpty) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!.user_init_screen_user2_name_field_error,
      );
      return;
    }

    if (coupleDate == null) {
      showErrorToast(
        context,
        AppLocalizations.of(context)!.user_init_screen_couple_date_field,
      );
      return;
    }

    CoupleModel couple = CoupleModel(
      user1: UserModel(
        email: userEmail1!,
        name: userName1Controller.text.trim(),
      ),
      user2: UserModel(
        email: userEmail2!,
        name: userName2Controller.text.trim(),
      ),
      coupleDate: coupleDate,
    );

    await FirebaseFirestore.instance
        .collection('couple')
        .doc(widget.userId)
        .update({
      'user1': couple.user1.toFirestore(),
      'user2': couple.user2.toFirestore(),
      'coupleDate': coupleDate != null ? Timestamp.fromDate(coupleDate!) : null,
      'isProfileCompleted': true,
    });

    if (mounted) {
      showSuccessToast(
        context,
        AppLocalizations.of(context)!.user_init_screen_toast_success,
      );
    }

    Get.off(
      () => const HomepageScreen(),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 500),
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
        AppLocalizations.of(context)!.user_init_screen_title,
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

  Widget _buildRegistrationForm(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.user_init_screen_user1_name,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 20.sp,
          ),
        ),
        _buildTextField(
          controller: userName1Controller,
          labelText:
              AppLocalizations.of(context)!.user_init_screen_user1_name_label,
          hintText:
              AppLocalizations.of(context)!.user_init_screen_user1_name_hint,
        ),
        SizedBox(height: 40.h),
        Text(
          AppLocalizations.of(context)!.user_init_screen_user2_name,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 20.sp,
          ),
        ),
        _buildTextField(
          controller: userName2Controller,
          labelText:
              AppLocalizations.of(context)!.user_init_screen_user2_name_label,
          hintText:
              AppLocalizations.of(context)!.user_init_screen_user2_name_hint,
        ),
        SizedBox(height: 40.h),
        _buildCoupleDateSelector(context),
        SizedBox(height: 40.h),
        _buildSaveButton(context),
        SizedBox(height: 20.h),
      ],
    );
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

  Widget _buildCoupleDateSelector(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.user_init_screen_couple_date_field,
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
                  .user_init_screen_couple_date_select
              : AppLocalizations.of(context)!
                  .user_init_screen_couple_date_update,
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
}
