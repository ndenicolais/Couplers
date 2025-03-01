import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/utils/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:free_map/free_map.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class EventModel {
  String? id;
  String title;
  DateTime startDate;
  DateTime? endDate;
  String category;
  List<String>? images;
  List<String> locations;
  List<LatLng?> positions;
  String? note;
  bool isFavorite;
  DateTime addedDate;

  EventModel({
    this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    required this.category,
    this.images,
    this.locations = const [],
    this.positions = const [],
    this.note,
    this.isFavorite = false,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'category': category,
      'images': images,
      'locations': locations,
      'positions': positions
          .map((pos) => {
                'lat': pos?.latitude,
                'lng': pos?.longitude,
              })
          .toList(),
      'note': note,
      'isFavorite': isFavorite,
      'addedDate': Timestamp.fromDate(addedDate),
    };
  }

  factory EventModel.fromFirestore(String id, Map<String, dynamic> data) {
    return EventModel(
      id: id,
      title: data['title'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      category: data['category'],
      images: List<String>.from(data['images'] ?? []),
      locations: List<String>.from(data['locations'] ?? []),
      positions: (data['positions'] as List)
          .map((pos) => pos != null ? LatLng(pos['lat'], pos['lng']) : null)
          .toList(),
      note: data['note'],
      isFavorite: data['isFavorite'] ?? false,
      addedDate: (data['addedDate'] as Timestamp).toDate(),
    );
  }

  static const Map<String, IconData> categoryIconMap = {
    'Anniversary': CouplersIcons.iconCategoryAnniversary,
    'Valentines': CouplersIcons.iconCategoryValentine,
    'Location': CouplersIcons.iconCategoryLocation,
    'Weekend': CouplersIcons.iconCategoryWeekend,
    'Breakfast': CouplersIcons.iconCategoryBreakfast,
    'Lunch': CouplersIcons.iconCategoryLunch,
    'Dinner': CouplersIcons.iconCategoryDinner,
    'Night': CouplersIcons.iconCategoryNight,
    'Vacation': CouplersIcons.iconCategoryVacation,
    'Shopping': CouplersIcons.iconCategoryShopping,
    'Birthday': CouplersIcons.iconCategoryBirthday,
    'Cinema': CouplersIcons.iconCategoryCinema,
    'Concert': CouplersIcons.iconCategoryConcert,
    'Experience': CouplersIcons.iconCategoryExperience,
    'Other': CouplersIcons.iconCategoryOther,
  };

  static Map<String, Color> categoryColorMap = {
    'Anniversary': Colors.red[300]!,
    'Valentines': Colors.red[600]!,
    'Location': Colors.teal[600]!,
    'Weekend': Colors.teal[900]!,
    'Breakfast': Colors.brown[300]!,
    'Lunch': Colors.brown[600]!,
    'Dinner': Colors.brown[900]!,
    'Night': Colors.blue[300]!,
    'Vacation': Colors.blue[600]!,
    'Shopping': Colors.orange[600]!,
    'Birthday': Colors.orange[900]!,
    'Cinema': Colors.indigo[300]!,
    'Concert': Colors.indigo[600]!,
    'Experience': Colors.indigo[900]!,
    'Other': Colors.purple[300]!,
  };

  Icon getIcon({Color color = AppColors.charcoal}) {
    return Icon(
      categoryIconMap[category] ?? MingCuteIcons.mgc_question_line,
      color: color,
    );
  }

  Color getColor() {
    return categoryColorMap[category] ?? Colors.black;
  }

  static const List<String> categoryFilter = [
    'All',
    'Anniversary',
    'Valentines',
    'Location',
    'Weekend',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Night',
    'Vacation',
    'Shopping',
    'Birthday',
    'Cinema',
    'Concert',
    'Experience',
    'Other'
  ];
}
