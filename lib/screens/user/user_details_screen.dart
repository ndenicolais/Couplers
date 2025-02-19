import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:couplers/models/couple_model.dart';
import 'package:couplers/screens/user/user_updater_screen.dart';
import 'package:couplers/services/user_service.dart';
import 'package:couplers/widgets/custom_loader.dart';
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

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  const UserDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  UserDetailsScreenState createState() => UserDetailsScreenState();
}

class UserDetailsScreenState extends State<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  late TabController tabController;
  String? userName1;
  String? userName2;
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
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: isLoading
            ? Center(child: _buildLoadingIndicator(context))
            : Column(
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
    tabController = TabController(length: 2, vsync: this);
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
          userName1 = couple.user1.name;
          userName2 = couple.user2.name;
          userEmail1 = couple.user1.email;
          userEmail2 = couple.user2.email;
          userBirthday1 = couple.user1.birthday;
          userBirthday2 = couple.user2.birthday;
          userGender1 = couple.user1.gender;
          userGender2 = couple.user2.gender;

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
        AppLocalizations.of(context)!.users_details_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      actions: [
        IconButton(
          icon: const Icon(MingCuteIcons.mgc_edit_2_fill),
          onPressed: () async {
            bool? result = await Get.to(
              () => UserUpdaterScreen(userId: currentUser!.uid),
              transition: Transition.fade,
              duration: const Duration(milliseconds: 500),
            );
            if (result == true) {
              _loadProfileData();
            } else {
              _logger.d('User data not updated');
            }
          },
        ),
      ],
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
                AppLocalizations.of(context)!.users_details_screen_user1_title,
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
                AppLocalizations.of(context)!.users_details_screen_user2_title,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarView(BuildContext context, TabController tabController) {
    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          _buildUserCard(context, 1),
          _buildUserCard(context, 2),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, int userIndex) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (userIndex == 1)
            _buildUserDetails(context, 1)
          else
            _buildUserDetails(context, 2),
        ],
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context, int userIndex) {
    final isUser1 = userIndex == 1;
    final userImage = isUser1 ? userImage1 : userImage2;
    final userName = isUser1 ? userName1 : userName2;
    final userEmail = isUser1 ? userEmail1 : userEmail2;
    final userBirthday = isUser1 ? userBirthday1 : userBirthday2;
    final userGender = isUser1 ? userGender1 : userGender2;

    return Card(
      color: Theme.of(context).colorScheme.tertiaryFixed,
      elevation: 0,
      margin: EdgeInsets.all(36.r),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(66.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 15.h,
          children: [
            _buildUserImage(context, userImage),
            _buildUserName(context, userName),
            _buildUserGender(context, userGender),
            _buildUserBirthday(context, userBirthday),
            _buildUserEmail(context, userEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 160.w,
        height: 160.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingIndicator(context),
        errorWidget: (context, url, error) => Image.asset(
          "assets/images/default_user_image.png",
          width: 160.w,
          height: 160.h,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Image.file(
        File(imageUrl),
        width: 160.w,
        height: 160.h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            "assets/images/default_user_image.png",
            width: 160.w,
            height: 160.h,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }

  Widget _buildUserImage(BuildContext context, dynamic userImage) {
    if (userImage != null) {
      return ClipOval(child: _buildImage(userImage.path));
    } else {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        radius: 50.r,
        child: Icon(
          MingCuteIcons.mgc_pic_fill,
          size: 30.sp,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildUserName(BuildContext context, String? userName) {
    return Text(
      userName!,
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 36.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUserGender(BuildContext context, String? userGender) {
    if (userGender == 'Male') {
      return Icon(
        MingCuteIcons.mgc_male_line,
        size: 30.sp,
        color: Theme.of(context).colorScheme.tertiary,
      );
    } else if (userGender == 'Female') {
      return Icon(
        MingCuteIcons.mgc_female_line,
        size: 30.sp,
        color: Theme.of(context).colorScheme.tertiary,
      );
    } else {
      return Text(
        AppLocalizations.of(context)!.users_details_screen_gender_empty,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 20.sp,
        ),
      );
    }
  }

  Widget _buildUserBirthday(BuildContext context, DateTime? userBirthday) {
    return Text(
      userBirthday != null
          ? DateFormat('dd/MM/yyyy').format(userBirthday)
          : AppLocalizations.of(context)!.users_details_screen_birthday_empty,
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.tertiary,
        fontSize: 20.sp,
      ),
    );
  }

  Widget _buildUserEmail(BuildContext context, String? userEmail) {
    return Text(
      userEmail!,
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.tertiary,
        fontSize: 20.sp,
      ),
    );
  }
}
