import 'package:couplers/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:photo_view/photo_view.dart';

class CustomFullImage extends StatelessWidget {
  final String imageUrl;

  const CustomFullImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              MingCuteIcons.mgc_close_line,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          loadingBuilder: (context, event) =>
              Center(child: _buildLoadingIndicator(context)),
        ),
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
}
