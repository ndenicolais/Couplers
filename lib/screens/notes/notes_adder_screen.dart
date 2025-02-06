import 'package:couplers/models/note_model.dart';
import 'package:couplers/services/note_service.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class NoteAddUpdateScreen extends StatefulWidget {
  final String userId;
  final NoteModel? note;

  const NoteAddUpdateScreen({super.key, required this.userId, this.note});

  @override
  NoteAddUpdateScreenState createState() => NoteAddUpdateScreenState();
}

class NoteAddUpdateScreenState extends State<NoteAddUpdateScreen> {
  final NoteService _noteService = NoteService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Color _backgroundColor;
  late Color _textColor;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: _buildBody(context),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
    _backgroundColor = widget.note?.backgroundColor ?? const Color(0xFFFBF8CC);
    _textColor = widget.note?.textColor ?? const Color(0xFF000000);
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      if (widget.note == null) {
        final newNote = NoteModel(
          id: '',
          date: DateTime.now(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          backgroundColor: _backgroundColor,
          textColor: _textColor,
        );

        _noteService.addNote(newNote);
        Get.back(result: newNote);
        showSuccessToast(
            context,
            AppLocalizations.of(context)!
                .notes_adder_screen_toast_success_added);
      } else {
        final updatedNote = NoteModel(
          id: widget.note!.id,
          date: DateTime.now(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          backgroundColor: _backgroundColor,
          textColor: _textColor,
        );

        _noteService.updateNote(updatedNote);
        Get.back(result: updatedNote);
        showSuccessToast(
            context,
            AppLocalizations.of(context)!
                .notes_adder_screen_toast_success_updated);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void pickBackgroundColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.notes_adder_screen_picker_color_title,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 24.sp,
            ),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: notesBackgroundColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _backgroundColor = color;
                    });
                    Get.back();
                  },
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.w,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void pickTextColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.notes_adder_screen_picker_color_title,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 24.sp,
            ),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.r,
              runSpacing: 8.r,
              alignment: WrapAlignment.center,
              children: notesTextColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _textColor = color;
                    });
                    Get.back();
                  },
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.w,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
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
        widget.note == null
            ? AppLocalizations.of(context)!.notes_adder_screen_title_added
            : AppLocalizations.of(context)!.notes_adder_screen_title_updated,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          _buildTitleFieldSection(context),
          SizedBox(height: 16.h),
          _buildDescriptionFieldSection(context),
          SizedBox(height: 16.h),
          _buildColorPickerSection(context),
          SizedBox(height: 32.h),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildTitleFieldSection(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          context,
          _titleController,
          AppLocalizations.of(context)!.notes_adder_screen_form_title,
          AppLocalizations.of(context)!.notes_adder_screen_form_title_field,
          MingCuteIcons.mgc_text_2_fill,
          TextInputType.text,
          TextCapitalization.sentences,
          TextInputAction.next,
          (val) => val!.isEmpty
              ? AppLocalizations.of(context)!
                  .notes_adder_screen_toast_error_title
              : null,
        ),
      ],
    );
  }

  Widget _buildDescriptionFieldSection(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          context,
          _descriptionController,
          AppLocalizations.of(context)!.notes_adder_screen_form_description,
          AppLocalizations.of(context)!
              .notes_adder_screen_form_description_field,
          MingCuteIcons.mgc_text_2_fill,
          TextInputType.text,
          TextCapitalization.sentences,
          TextInputAction.done,
          (val) => val!.isEmpty
              ? AppLocalizations.of(context)!
                  .notes_adder_screen_toast_error_description
              : null,
          minLines: 6,
        ),
      ],
    );
  }

  Widget _buildColorPickerSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildColorPickerColumn(
            context,
            AppLocalizations.of(context)!.notes_adder_screen_color_bg,
            _backgroundColor,
            () => pickBackgroundColor(context)),
        SizedBox(width: 20.w),
        _buildColorPickerColumn(
            context,
            AppLocalizations.of(context)!.notes_adder_screen_color_text,
            _textColor,
            () => pickTextColor(context)),
      ],
    );
  }

  Widget _buildColorPickerColumn(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String labelText,
    String hintText,
    IconData prefixIcon,
    TextInputType keyboardType,
    TextCapitalization textCapitalization,
    TextInputAction textInputAction,
    String? Function(String?) validator, {
    int? minLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      cursorColor: Theme.of(context).colorScheme.secondary,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.secondary,
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      validator: validator,
      minLines: minLines,
      maxLines: null,
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: Theme.of(context).colorScheme.tertiaryFixed,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      elevation: 0,
      onPressed: _saveNote,
      child: const Icon(
        MingCuteIcons.mgc_check_fill,
      ),
    );
  }
}
