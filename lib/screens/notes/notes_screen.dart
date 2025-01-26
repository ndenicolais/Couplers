import 'package:couplers/models/note_model.dart';
import 'package:couplers/screens/notes/notes_adder_screen.dart';
import 'package:couplers/services/note_service.dart';
import 'package:couplers/widgets/custom_delete_dialog.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_note.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final NoteService _noteService = NoteService();
  bool _isSelectionMode = false;
  Set<String> selectedNotes = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Future<void> _updateNotes(BuildContext context) async {
    final updatedNote = await Get.to(
      () => NoteAddUpdateScreen(userId: currentUser!.uid),
      transition: Transition.fade,
      duration: const Duration(milliseconds: 500),
    );

    if (updatedNote != null) {
      setState(() {});
    }
  }

  Future<void> _editNote(
    BuildContext context,
    User currentUser,
    NoteModel note,
  ) async {
    final result = await Get.to(
      NoteAddUpdateScreen(
        userId: currentUser.uid,
        note: note,
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        selectedNotes.clear();
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    bool confirmDelete = await _showDeleteDialog(context);

    if (confirmDelete) {
      for (var noteId in selectedNotes) {
        await _noteService.deleteNote(noteId);
      }
      setState(() {
        selectedNotes.clear();
        _isSelectionMode = false;
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
        AppLocalizations.of(context)!.notes_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      actions: [
        IconButton(
          icon: Icon(
            _isSelectionMode
                ? MingCuteIcons.mgc_close_fill
                : MingCuteIcons.mgc_multiselect_fill,
            color: _isSelectionMode
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
          ),
          onPressed: _toggleSelectionMode,
        ),
        if (_isSelectionMode)
          IconButton(
            icon: Icon(
              MingCuteIcons.mgc_delete_3_fill,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _deleteSelectedNotes,
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<NoteModel>>(
      stream: _noteService.getNotes(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error);
        }

        var notes = snapshot.data ?? [];
        notes.sort((a, b) => b.date.compareTo(a.date));

        if (notes.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildNotesGrid(context, notes);
      },
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

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Center(
      child: SizedBox(
        width: 320.w,
        child: Text(
          '${AppLocalizations.of(context)!.notes_screen_error_state} $error',
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.notes_screen_empty_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 24.sp,
        ),
      ),
    );
  }

  Widget _buildNotesGrid(BuildContext context, List<NoteModel> notes) {
    return Padding(
      padding: EdgeInsets.all(8.r),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(context, note);
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    bool isSelected = selectedNotes.contains(note.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              selectedNotes.remove(note.id);
            } else {
              selectedNotes.add(note.id!);
            }
          });
        } else {
          _editNote(context, currentUser!, note);
        }
      },
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomNote(
              color: note.backgroundColor,
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: Column(
                  children: [
                    Text(
                      note.title,
                      style: GoogleFonts.josefinSans(
                        color: note.textColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          note.description,
                          style: GoogleFonts.josefinSans(
                            color: note.textColor,
                            fontSize: 18.sp,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (isSelected)
                      SizedBox(
                        child: Icon(
                          MingCuteIcons.mgc_check_circle_fill,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      elevation: 0,
      onPressed: () => _updateNotes(context),
      child: const Icon(MingCuteIcons.mgc_add_fill),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return DeleteDialog(
              title: AppLocalizations.of(context)!
                  .notes_screen_delete_dialog_title,
              content:
                  AppLocalizations.of(context)!.notes_screen_delete_dialog_text,
              onCancelPressed: () {
                Get.back(result: false);
              },
              onConfirmPressed: () {
                Get.back(result: true);
                showSuccessToast(
                  context,
                  AppLocalizations.of(context)!
                      .notes_screen_toast_success_delete,
                );
              },
            );
          },
        ) ??
        false;
  }
}
