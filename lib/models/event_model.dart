import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/utils/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class EventModel {
  String? id;
  String title;
  DateTime startDate;
  DateTime? endDate;
  String type;
  List<String>? images;
  List<String> locations;
  List<LatLng?> positions;
  String? note;
  bool isFavorite;

  EventModel({
    this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    required this.type,
    this.images,
    required this.locations,
    required this.positions,
    this.note,
    this.isFavorite = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
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
      type: data['type'],
      images: List<String>.from(data['images'] ?? []),
      locations: List<String>.from(data['locations'] ?? []),
      positions: (data['positions'] as List)
          .map((pos) => pos != null ? LatLng(pos['lat'], pos['lng']) : null)
          .toList(),
      note: data['note'],
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  static const Map<String, IconData> typeIconMap = {
    'Anniversary': CouplersIcons.icontypeanniversary,
    'Valentines Day': CouplersIcons.icontypevalentine,
    'Birthday': CouplersIcons.icontypebirthday,
    'Dinner': CouplersIcons.icontypedinner,
    'Night': CouplersIcons.icontypenight,
    'Weekend': CouplersIcons.icontypeweekend,
    'Vacation': CouplersIcons.icontypevacation,
    'Shopping': CouplersIcons.icontypeshopping,
    'Cinema': CouplersIcons.icontypecinema,
    'Concert': CouplersIcons.icontypeconcert,
    'Experience': CouplersIcons.icontypeexperience,
    'Other': CouplersIcons.icontypeother,
  };

  static Map<String, Color> typeColorMap = {
    'Anniversary': Colors.red[300]!,
    'Valentines Day': Colors.pink[300]!,
    'Birthday': Colors.yellow[300]!,
    'Dinner': Colors.brown[300]!,
    'Night': Colors.indigo[300]!,
    'Weekend': Colors.amber[300]!,
    'Vacation': Colors.cyan[300]!,
    'Shopping': Colors.orange[300]!,
    'Cinema': Colors.lime[300]!,
    'Concert': Colors.teal[300]!,
    'Experience': Colors.green[300]!,
    'Other': Colors.purple[300]!,
  };

  static Map<String, String> typeImageMap = {
    'Anniversary': 'assets/images/img_default.png',
    'Valentines Day': 'assets/images/img_default.png',
    'Birthday': 'assets/images/img_default.png',
    'Dinner': 'assets/images/img_default.png',
    'Night': 'assets/images/img_default.png',
    'Weekend': 'assets/images/img_default.png',
    'Vacation': 'assets/images/img_default.png',
    'Shopping': 'assets/images/img_default.png',
    'Cinema': 'assets/images/img_default.png',
    'Concert': 'assets/images/img_default.png',
    'Experience': 'assets/images/img_default.png',
    'Other': 'assets/images/img_default.png',
  };

  Icon getIcon({Color color = AppColors.charcoal}) {
    return Icon(
      typeIconMap[type] ?? MingCuteIcons.mgc_question_line,
      color: color,
    );
  }

  Color getColor() {
    return typeColorMap[type] ?? Colors.black;
  }

  static const List<String> filterTypes = [
    'All',
    'Anniversary',
    'Valentines Day',
    'Birthday',
    'Dinner',
    'Night',
    'Weekend',
    'Vacation',
    'Shopping',
    'Cinema',
    'Concert',
    'Experience',
    'Other'
  ];
}
