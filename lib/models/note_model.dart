import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteModel {
  String? id;
  DateTime date;
  String title;
  String description;
  Color backgroundColor;
  Color textColor;

  NoteModel({
    this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.textColor,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'title': title,
      'description': description,
      'backgroundColor': _getColorValue(backgroundColor),
      'textColor': _getColorValue(textColor),
    };
  }

  factory NoteModel.fromFirestore(String id, Map<String, dynamic> data) {
    return NoteModel(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'],
      description: data['description'],
      backgroundColor: Color(data['backgroundColor'] ?? 0xFFFFFFFF),
      textColor: Color(data['textColor'] ?? 0xFF000000),
    );
  }
}

// Funzione helper per ottenere il valore ARGB
int _getColorValue(Color color) {
  // Convertiamo i componenti di colore in interi (0-255)
  int alpha = (color.a * 255).toInt();
  int red = (color.r * 255).toInt();
  int green = (color.g * 255).toInt();
  int blue = (color.b * 255).toInt();

  // Combiniamo i componenti ARGB in un intero
  return (alpha << 24) | (red << 16) | (green << 8) | blue;
}
