import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String answer;
  final IconData iconClosed;
  final IconData iconOpened;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.answer,
    this.iconClosed = MingCuteIcons.mgc_down_fill,
    this.iconOpened = MingCuteIcons.mgc_up_fill,
  });

  @override
  CustomExpansionTileState createState() => CustomExpansionTileState();
}

class CustomExpansionTileState extends State<CustomExpansionTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        widget.title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 16.sp,
        ),
      ),
      trailing: Icon(
        isExpanded ? widget.iconOpened : widget.iconClosed,
        color: isExpanded
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.tertiary,
        size: 24.sp,
      ),
      onExpansionChanged: (bool expanded) {
        setState(() {
          isExpanded = expanded;
        });
      },
      children: [
        Padding(
          padding: EdgeInsets.all(12.r),
          child: Text(
            widget.answer,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
